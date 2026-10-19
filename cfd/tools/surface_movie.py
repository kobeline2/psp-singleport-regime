#!/usr/bin/env python3
"""surface_movie.py -- 自由表面の流速から動画と判定指標を作る (WS で動く. MATLAB 不要).

指標の定義と格子は MATLAB 側の判定 (cfd/campaign.md §2 の表を作った手順) と同一.
B03 / P02 / P09 / 実験 R0006・R0008 で §2 の数値を再現することを確認済み.

使い方:
  python3 surface_movie.py <入力> [--label 名前] [--out-dir 出力先]

  <入力> は次のどれでもよい:
    - OpenFOAM のケースディレクトリ (postProcessing/surfSample を含む)
    - surfSample ディレクトリそのもの
    - 実験の pivlab_single.mat (--frame-metrics に frame_metrics.csv を渡す)

  よく使うオプション:
    --window T0 T1   判定に使う時間窓 [s]. 省略時は深水帯 (Q=0.5 L/s で 485-950 s,
                     流量 Q なら 485-950 を 0.5/Q 倍した時刻) を自動で選ぶ
    --flow-rate Q    流量 [m3/s]. 省略時は 0.orig/U の flowRate, それも無ければ水量の増加率
    --tmin/--tmax    動画にする時間範囲 (省略時は全時刻)
    --no-movie       判定指標と平均場の図だけ作る (速い)

出力 (--out-dir, 省略時はカレントの <label>_surface/):
  <label>_surface.mp4     渦度 (色) + 流速 (矢印) の動画. 下段に偏り指数の時系列
  <label>_meanfield.png   判定窓の平均場 (渦度と符号) と判定指標
  <label>_metrics.txt     判定指標 1 行 (campaign.md §2 と同じ列)

読み方の注意 (campaign.md §3 の要約):
  - 偏り指数 B = (上半分のエネルギー - 下半分) / (合計). +: ジェットが上壁 (y>1) 寄り.
    実験はロックすると +0.249 / -0.244 で, 465 s 間ほとんど動かない (±0.007).
  - CFD は瞬間的には ±0.27 まで振れる. 動画で一瞬偏って見えても成功ではない.
    見るべきは「偏りが保持されるか」= 下段の移動平均が ±0.25 付近に張り付くか.
"""

import argparse
import glob
import os
import re
import sys
import warnings

import numpy as np
from scipy.interpolate import LinearNDInterpolator
from scipy.ndimage import gaussian_filter, label

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib import animation  # noqa: E402

# --- 解析領域と格子: MATLAB の import_cfd_surface + 判定と同一 ---------------------------
OMEGA_X = (0.045, 2.909)        # 実験 PIV の解析領域 Ω [m]
OMEGA_Y = (0.041, 1.929)
GRID_DX = 0.0315                # 実験 PIV のベクトル間隔に合わせた格子 [m]
SURFACE_Z_TOL = 0.015           # 気泡の等値面を除く: 中央値 ±15 mm の点だけ使う
Y_SPLIT = 1.0                   # CFD メッシュの対称面 (ポート中心). 偏り指数の上下分割
SMOOTH_SIGMA = 1.5              # 渦度前の平滑化 (MATLAB imgaussfilt(.,1.5) と同じ 7x7 窓)

# --- 幾何 (CFD メッシュ = 呼び値 3.0 x 2.0 m. 水位の換算にのみ使う) ---------------------
PORT_A = 0.055                  # ポート高 [m]
PORT_B = 0.11                   # ポート幅 [m]
AREA_BELOW_PORT = 6.066         # 水槽 6.0 + 導水路 0.066 [m2] (h < a: 導水路も自由表面)
AREA_ABOVE_PORT = 6.0           # h > a: 導水路は満管なので水槽だけ
BASIN_LX, BASIN_LY = 3.0, 2.0

# --- 深水帯の判定窓: Q = 0.5 L/s, 初期水位 20 mm で t = 485-950 s (h = 0.060-0.098 m) ----
REF_Q = 0.5e-3
REF_WINDOW = (485.0, 950.0)

# --- 実験の参照値 (cfd/campaign.md §2) ------------------------------------------------
LAB_REF = "lab R0006 / R0008:  dominant sign 66.0 / 66.3 %,  bias +0.249 / -0.244,  lock 15.2 / 12.5"


# ======================================================================================
# 入力の読み込み
# ======================================================================================

def matlab_colon(start, step, stop):
    """MATLAB の start:step:stop と同じ点列 (stop を超えない)."""
    n = int(np.floor((stop - start) / step + 1e-9)) + 1
    return start + step * np.arange(n)


def analysis_grid():
    xg = matlab_colon(OMEGA_X[0] + GRID_DX / 2, GRID_DX, OMEGA_X[1])
    yg = matlab_colon(OMEGA_Y[0] + GRID_DX / 2, GRID_DX, OMEGA_Y[1])
    return np.meshgrid(xg, yg)          # 形状 (ny, nx). MATLAB の meshgrid と同じ向き


def find_sample_dir(path):
    """surfSample ディレクトリを探す (ケース直下, postProcessing 下, それ自身)."""
    for cand in (os.path.join(path, "postProcessing", "surfSample"),
                 os.path.join(path, "surfSample"),
                 path):
        if os.path.isdir(cand) and list_sample_times(cand):
            return cand
    sys.exit(f"surfSample の時刻ディレクトリが見つからない: {path}\n"
             f"  先に postProcess -func surfSample -parallel を実行したか確認すること")


def list_sample_times(sample_dir):
    times = []
    for name in os.listdir(sample_dir):
        try:
            t = float(name)
        except ValueError:
            continue
        if glob.glob(os.path.join(sample_dir, name, "U_*.raw")):
            times.append((t, name))
    return sorted(times)


def read_surface_frame(frame_dir, X, Y):
    """1 時刻分の等値面を読み, 解析格子に線形補間した (u, v) を返す. 範囲外は NaN."""
    files = glob.glob(os.path.join(frame_dir, "U_*.raw"))
    raw = np.loadtxt(files[0], comments="#", ndmin=2)        # 列: x y z Ux Uy Uz
    if raw.shape[0] >= 10:
        z_med = np.median(raw[:, 2])
        raw = raw[np.abs(raw[:, 2] - z_med) <= SURFACE_Z_TOL]
    if raw.shape[0] < 10:
        return np.full(X.shape, np.nan), np.full(X.shape, np.nan)
    # 同一点の重複は平均する (MATLAB scatteredInterpolant と同じ扱い)
    xy, inverse = np.unique(np.round(raw[:, :2], 9), axis=0, return_inverse=True)
    inverse = inverse.ravel()
    count = np.bincount(inverse)
    uv = np.column_stack([np.bincount(inverse, raw[:, 3]) / count,
                          np.bincount(inverse, raw[:, 4]) / count])
    field = LinearNDInterpolator(xy, uv)(X, Y)               # 凸包の外は NaN
    return field[..., 0], field[..., 1]


def read_water_volume(path):
    """waterVolume の時系列 (t, V). 再起動で分かれたファイルも連結する."""
    pattern_dirs = [os.path.join(path, "postProcessing", "waterVolume"),
                    os.path.join(path, "waterVolume"),
                    os.path.join(os.path.dirname(os.path.abspath(path)), "waterVolume")]
    files = []
    for d in pattern_dirs:
        files += glob.glob(os.path.join(d, "*", "volFieldValue*.dat"))
    parts = []
    for f in files:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")          # 落ちたランの見出しだけのファイルは空で返る
            arr = np.loadtxt(f, comments="#", ndmin=2)
        if arr.ndim == 2 and arr.shape[0] > 0 and arr.shape[1] >= 2:
            parts.append(arr[:, :2])
    if not parts:
        return None
    rows = np.vstack(parts)
    rows = rows[np.argsort(rows[:, 0])]
    _, keep = np.unique(rows[:, 0], return_index=True)
    return rows[keep]


def water_level(volume):
    """水量 [m3] -> 水位 [m]. ポート高 a を境に平面積が変わる (導水路が満管になる)."""
    v_port = AREA_BELOW_PORT * PORT_A
    return np.where(volume <= v_port, volume / AREA_BELOW_PORT,
                    PORT_A + (volume - v_port) / AREA_ABOVE_PORT)


def read_nominal_flow_rate(case_dir):
    for sub in ("0.orig", "0"):
        f = os.path.join(case_dir, sub, "U")
        if os.path.isfile(f):
            m = re.search(r"^\s*flowRate\s+([0-9.eE+-]+)\s*;", open(f).read(), re.M)
            if m:
                return float(m.group(1))
    return None


def cfd_context(path):
    """表面データの場所と, 流量・水量 (軽い情報) だけを先に読む."""
    sample_dir = find_sample_dir(path)
    if os.path.basename(os.path.dirname(sample_dir)) == "postProcessing":
        case_dir = os.path.dirname(os.path.dirname(sample_dir))
    else:
        case_dir = path
    return dict(sample_dir=sample_dir, volume=read_water_volume(case_dir),
                q_nominal=read_nominal_flow_rate(case_dir))


def load_cfd_frames(ctx, tmin, tmax):
    sample_dir = ctx["sample_dir"]
    times = [(t, n) for t, n in list_sample_times(sample_dir) if tmin <= t <= tmax]
    X, Y = analysis_grid()
    U = np.full(X.shape + (len(times),), np.nan)
    V = np.full_like(U, np.nan)
    for k, (t, name) in enumerate(times):
        U[..., k], V[..., k] = read_surface_frame(os.path.join(sample_dir, name), X, Y)
        if (k + 1) % 25 == 0 or k + 1 == len(times):
            print(f"  読み込み {k + 1}/{len(times)}  (t = {t:g} s)", flush=True)
    t = np.array([tt for tt, _ in times])
    return dict(X=X, Y=Y, U=U, V=V, t=t, volume=ctx["volume"],
                q_nominal=ctx["q_nominal"], source="cfd")


def load_piv(mat_path, frame_metrics_csv, frame_step):
    """実験の pivlab_single.mat (v7.3) から深水帯 (B3/B4) のフレームを読む."""
    import csv
    import h5py
    with open(frame_metrics_csv, newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.DictReader(fh))
    band = np.array([r["band_id"] for r in rows])
    depth = np.array([float(r["depth_m"]) if r.get("depth_m") not in (None, "", "NaN")
                      else np.nan for r in rows])
    with h5py.File(mat_path, "r") as h:
        n_frames = h["piv/u"].shape[0]
        sel = np.flatnonzero((band == "B3") | (band == "B4"))
        sel = sel[sel < n_frames]
        # MATLAB の [ny, nx, nt] は h5py では [nt, nx, ny] に見えるので転置して戻す
        X = np.array(h["piv/x"]).T
        Y = np.array(h["piv/y"]).T
        U = np.transpose(np.array(h["piv/u"][sel]), (2, 1, 0))
        V = np.transpose(np.array(h["piv/v"][sel]), (2, 1, 0))
    dt_pair = 0.1001
    return dict(X=X, Y=Y, U=U, V=V, t=sel * dt_pair, depth=depth[sel], frame_step=frame_step,
                volume=None, q_nominal=None, source="piv")


# ======================================================================================
# 指標 (MATLAB の判定スクリプトと同じ式)
# ======================================================================================

def smooth(F):
    # imgaussfilt(F, 1.5) と同じ: 7x7 窓 (truncate 2.0), 端は複製, NaN は窓内に伝播する
    return gaussian_filter(F, sigma=SMOOTH_SIGMA, mode="nearest", truncate=2.0)


def vorticity(u, v, dx):
    us, vs = smooth(u), smooth(v)
    return np.gradient(vs, dx, axis=1) - np.gradient(us, dx, axis=0)


def bias_index(u, v, Y):
    s = u ** 2 + v ** 2
    finite = np.isfinite(s)
    upper, lower = s[(Y >= Y_SPLIT) & finite], s[(Y < Y_SPLIT) & finite]
    if upper.size == 0 or lower.size == 0 or upper.mean() + lower.mean() <= 0:
        return np.nan                      # 静水 (t = 0) や表面が取れないフレーム
    return (upper.mean() - lower.mean()) / (upper.mean() + lower.mean())


def window_metrics(X, Y, U, V, t, window):
    dx = abs(X[0, 1] - X[0, 0])
    sel = (t >= window[0]) & (t <= window[1])
    u3, v3, tw = U[..., sel], V[..., sel], t[sel]
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", category=RuntimeWarning)
        um, vm = np.nanmean(u3, axis=2), np.nanmean(v3, axis=2)
    w = vorticity(um, vm, dx)
    wv = w[np.isfinite(w)]
    pos = 100.0 * np.mean(wv > 0)
    largest = 0
    for sign in (1, -1):
        labels, n = label((np.sign(w) == sign) & np.isfinite(w), structure=np.ones((3, 3)))
        if n:
            largest = max(largest, np.bincount(labels.ravel())[1:].max())
    s = um ** 2 + vm ** 2
    e_frames, circ = [], []
    for k in range(u3.shape[2]):
        q = u3[..., k] ** 2 + v3[..., k] ** 2
        e_frames.append(q[np.isfinite(q)].mean())
        wk = vorticity(u3[..., k], v3[..., k], dx)
        circ.append(wk[np.isfinite(wk)].mean())
    e_inst = float(np.mean(e_frames))
    e_mean = float(s[np.isfinite(s)].mean())
    circ = np.array(circ)
    # 偏りの持続性: 窓を時間で 3 等分した部分窓ごとの偏り (campaign.md §3.2)
    edges = window[0] + (window[1] - window[0]) * np.array([0, 1 / 3, 2 / 3, 1])
    sub = []
    for a, b in zip(edges[:-1], edges[1:]):
        m = (tw >= a) & (tw < b)
        if m.sum():
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", category=RuntimeWarning)
                sub.append(bias_index(np.nanmean(u3[..., m], 2), np.nanmean(v3[..., m], 2), Y))
    return dict(
        n_frames=int(sel.sum()), um=um, vm=vm, w=w,
        e_inst=e_inst, e_mean=e_mean, fluct_pct=100 * (e_inst - e_mean) / e_inst,
        bias=bias_index(um, vm, Y), dominant_pct=max(pos, 100 - pos),
        largest_pct=100.0 * largest / wv.size,
        lock=abs(circ.mean()) / circ.std(ddof=1) if circ.size > 1 else np.nan,
        sub_bias=sub)


# ======================================================================================
# 図と動画
# ======================================================================================

def draw_basin(ax, source):
    ax.add_patch(plt.Rectangle((0, 0), BASIN_LX, BASIN_LY, fill=False, lw=1.2, color="0.25"))
    ax.plot([0, 0], [1.0 - PORT_B / 2, 1.0 + PORT_B / 2], color="#d98e04", lw=5,
            solid_capstyle="butt")
    ax.axhline(Y_SPLIT, color="0.5", lw=0.6, ls=":")
    ax.set_xlim(-0.05, BASIN_LX + 0.05)
    ax.set_ylim(-0.05, BASIN_LY + 0.05)
    ax.set_aspect("equal")
    ax.set_xlabel("x [m]")
    ax.set_ylabel("y [m]")


def plot_vorticity(ax, X, Y, u, v, w, source, vlim=0.15, step=3):
    mesh = ax.pcolormesh(X, Y, w, cmap="RdBu_r", vmin=-vlim, vmax=vlim, shading="nearest")
    us, vs = smooth(u), smooth(v)
    q = ax.quiver(X[::step, ::step], Y[::step, ::step], us[::step, ::step], vs[::step, ::step],
                  angles="xy", scale_units="xy", scale=0.4, width=0.0022, color="k")
    ax.quiverkey(q, 0.90, -0.13, 0.05, "5 cm/s", labelpos="E", fontproperties={"size": 8})
    draw_basin(ax, source)
    return mesh


def write_meanfield_png(path, label_, data, m, window):
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(13, 4.6), constrained_layout=True)
    mesh = plot_vorticity(a1, data["X"], data["Y"], m["um"], m["vm"], m["w"], data["source"])
    fig.colorbar(mesh, ax=a1, shrink=0.85, label="mean vorticity [1/s]  (+ = counter-clockwise)")
    a1.set_title(f"{label_}  mean field, t = {window[0]:.0f}-{window[1]:.0f} s ({m['n_frames']} frames)")
    sign = np.sign(m["w"])
    a2.pcolormesh(data["X"], data["Y"], sign, cmap="RdBu_r", vmin=-1.5, vmax=1.5, shading="nearest")
    draw_basin(a2, data["source"])
    sub = " / ".join(f"{b:+.3f}" for b in m["sub_bias"])
    a2.set_title(f"sign of mean vorticity: dominant {m['dominant_pct']:.1f} %, "
                 f"largest patch {m['largest_pct']:.1f} %")
    fig.text(0.01, -0.06,
             f"E_inst {m['e_inst']:.6f}   mean-flow E {m['e_mean']:.6f}   fluctuation {m['fluct_pct']:.1f} %"
             f"   bias {m['bias']:+.3f}   (sub-windows {sub})   lock {m['lock']:.2f}\n{LAB_REF}",
             fontsize=9, family="monospace", va="top")
    fig.savefig(path, dpi=110, bbox_inches="tight")
    plt.close(fig)


def write_movie(path, label_, data, window, fps, every, level, smooth_s, tmin=-np.inf, tmax=np.inf):
    X, Y, U, V, t = data["X"], data["Y"], data["U"], data["V"], data["t"]
    dx = abs(X[0, 1] - X[0, 0])
    frames = np.flatnonzero((t >= tmin) & (t <= tmax))[::every]   # 動画に描く時刻
    bias_t = np.array([bias_index(U[..., k], V[..., k], Y) for k in range(len(t))])
    dt = np.median(np.diff(t)) if len(t) > 1 else 1.0
    n_avg = max(1, int(round(smooth_s / dt)))
    # 移動平均. 端や NaN (静水フレーム) では実在するサンプルだけで割る (端が 0 に垂れないように)
    valid = np.isfinite(bias_t)
    kernel = np.ones(n_avg)
    summed = np.convolve(np.where(valid, bias_t, 0.0), kernel, mode="same")
    counts = np.convolve(valid.astype(float), kernel, mode="same")
    with np.errstate(invalid="ignore", divide="ignore"):
        bias_avg = np.where(counts > 0, summed / counts, np.nan)

    fig = plt.figure(figsize=(10, 8.6))
    gs = fig.add_gridspec(2, 1, height_ratios=[4.2, 1.3], hspace=0.28)
    ax, axb = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])

    axb.axhspan(-0.3, -0.2, color="#d98e04", alpha=0.12)
    axb.axhspan(0.2, 0.3, color="#d98e04", alpha=0.12)
    axb.axhline(0, color="0.5", lw=0.6)
    if window is not None:
        axb.axvspan(window[0], window[1], color="0.85", zorder=0)
        axb.text(window[0], 0.36, " analysis window (deep band)", fontsize=7, color="0.35")
    axb.plot(t, bias_t, color="0.6", lw=0.7, label="instantaneous")
    axb.plot(t, bias_avg, color="#1f4e79", lw=1.8, label=f"{smooth_s:g}-s running mean")
    axb.text(t[0], 0.25, " lab locked (+0.25)", fontsize=7, color="#a86d00", va="center")
    axb.text(t[0], -0.25, " lab locked (-0.25)", fontsize=7, color="#a86d00", va="center")
    cursor = axb.axvline(t[0], color="#c0392b", lw=1.2)
    axb.set_xlim(t[0], t[-1])
    axb.set_ylim(-0.4, 0.4)
    axb.set_xlabel("t [s]" if data["source"] == "cfd" else "t from run start [s]")
    axb.set_ylabel("bias B")
    axb.legend(loc="lower right", fontsize=7, ncol=2, frameon=False)

    writer_cls = animation.FFMpegWriter if animation.FFMpegWriter.isAvailable() else None
    if writer_cls is None:
        path = os.path.splitext(path)[0] + ".gif"
        writer = animation.PillowWriter(fps=fps)
        print("  ffmpeg が無いので GIF で書き出す (大きく遅い). ffmpeg を入れると mp4 になる")
    else:
        writer = writer_cls(fps=fps, bitrate=2400)

    with writer.saving(fig, path, dpi=100):
        cbar = None
        for i, k in enumerate(frames):
            ax.clear()
            w = vorticity(U[..., k], V[..., k], dx)
            mesh = plot_vorticity(ax, X, Y, U[..., k], V[..., k], w, data["source"])
            if cbar is None:
                cbar = fig.colorbar(mesh, ax=ax, shrink=0.8,
                                    label="vorticity [1/s]  (+ = counter-clockwise)")
            h_txt = f"   h = {1000 * level[k]:.1f} mm" if level is not None and np.isfinite(level[k]) else ""
            ax.set_title(f"{label_}    t = {t[k]:7.1f} s{h_txt}    B = {bias_t[k]:+.2f}")
            cursor.set_xdata([t[k], t[k]])
            writer.grab_frame()
            if (i + 1) % 25 == 0 or i + 1 == len(frames):
                print(f"  描画 {i + 1}/{len(frames)}", flush=True)
    plt.close(fig)
    return path


# ======================================================================================

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("--label", default=None)
    ap.add_argument("--out-dir", default=None)
    ap.add_argument("--window", nargs=2, type=float, default=None, metavar=("T0", "T1"))
    ap.add_argument("--flow-rate", type=float, default=None, help="流量 [m3/s]")
    ap.add_argument("--tmin", type=float, default=-np.inf)
    ap.add_argument("--tmax", type=float, default=np.inf)
    ap.add_argument("--fps", type=int, default=10)
    ap.add_argument("--every", type=int, default=None, help="何フレームおきに描くか")
    ap.add_argument("--smooth-s", type=float, default=60.0, help="偏りの移動平均の幅 [s]")
    ap.add_argument("--no-movie", action="store_true")
    ap.add_argument("--frame-metrics", default=None, help="実験入力のときの frame_metrics.csv")
    args = ap.parse_args()

    label_ = args.label or os.path.basename(os.path.normpath(args.input)).replace(".mat", "")
    out_dir = args.out_dir or os.path.join(os.getcwd(), f"{label_}_surface")
    os.makedirs(out_dir, exist_ok=True)

    print(f"[{label_}] 読み込み: {args.input}")
    if args.input.endswith(".mat"):
        if not args.frame_metrics:
            sys.exit("実験入力には --frame-metrics <frame_metrics.csv> が必要")
        data = load_piv(args.input, args.frame_metrics, frame_step=args.every or 25)
        window = (data["t"][0], data["t"][-1])
        level = data["depth"]
        every = args.every or 25
        print(f"  実験: 深水帯 (B3/B4) {data['U'].shape[2]} フレーム")
    else:
        ctx = cfd_context(args.input)
        vol = ctx["volume"]
        q_est = np.polyfit(vol[:, 0], vol[:, 1], 1)[0] if vol is not None and len(vol) > 10 else None
        q = args.flow_rate or ctx["q_nominal"] or q_est or REF_Q
        if not (args.flow_rate or ctx["q_nominal"]):
            print(f"  注意: 流量を 0.orig/U から読めない. {'水量の増加率から推定' if q_est else '既定値'}"
                  f" {q:g} m3/s を使う (判定窓がずれるなら --flow-rate か --window を指定)")
        if ctx["q_nominal"] and vol is not None:
            mass = 100 * (vol[-1, 1] - vol[0, 1]) / (ctx["q_nominal"] * (vol[-1, 0] - vol[0, 0]))
            print(f"  質量保存: {mass:.2f} %  (流入 Q = {ctx['q_nominal']:g} m3/s, 水量 {vol[0, 0]:.0f}-{vol[-1, 0]:.0f} s)")
        window = tuple(args.window) if args.window else tuple(np.array(REF_WINDOW) * REF_Q / q)
        if not (args.window or args.flow_rate or ctx["q_nominal"]):
            # 流量が推定値のときは推定誤差 (~0.1 %) で窓の端がサンプルを跨がないよう,
            # 最寄りのサンプル時刻に寄せる (0.orig/U が読める WS 上では起きない)
            ts = np.array([t for t, _ in list_sample_times(ctx["sample_dir"])])
            window = tuple(ts[np.argmin(np.abs(ts - w))] for w in window)
        print(f"  流量 {q:g} m3/s -> 判定窓 t = {window[0]:.1f}-{window[1]:.1f} s")
        if args.no_movie:
            t_lo, t_hi = window                      # 指標だけなら判定窓の時刻だけ読めば足りる
        else:                                        # 動画の範囲と判定窓の両方を含めて読む
            t_lo = min(args.tmin, window[0])
            t_hi = max(args.tmax, window[1])
        data = load_cfd_frames(ctx, t_lo, t_hi)
        level = water_level(np.interp(data["t"], vol[:, 0], vol[:, 1])) if vol is not None else None
        every = args.every or 1

    m = window_metrics(data["X"], data["Y"], data["U"], data["V"], data["t"], window)
    if m["n_frames"] < 3:
        sys.exit(f"判定窓に {m['n_frames']} フレームしかない. --window か計算の終了時刻を確認すること")
    sub = " / ".join(f"{b:+.3f}" for b in m["sub_bias"])
    row = (f"{label_}\twindow {window[0]:.1f}-{window[1]:.1f} s ({m['n_frames']} frames)\t"
           f"E_inst {m['e_inst']:.6f}\tmean-flow {m['e_mean']:.6f}\tfluct {m['fluct_pct']:.1f} %\t"
           f"bias {m['bias']:+.3f} (sub {sub})\tdominant {m['dominant_pct']:.1f} %\t"
           f"largest {m['largest_pct']:.1f} %\tlock {m['lock']:.2f}")
    with open(os.path.join(out_dir, f"{label_}_metrics.txt"), "w") as fh:
        fh.write(row + "\n" + LAB_REF + "\n")
    print("  " + row.replace("\t", "\n  "))
    write_meanfield_png(os.path.join(out_dir, f"{label_}_meanfield.png"), label_, data, m, window)

    if not args.no_movie:
        print("  動画を書き出し中")
        movie = write_movie(os.path.join(out_dir, f"{label_}_surface.mp4"), label_, data,
                            window, args.fps, every, level, args.smooth_s, args.tmin, args.tmax)
        print(f"  -> {movie}")
    print(f"  出力: {out_dir}")


if __name__ == "__main__":
    main()

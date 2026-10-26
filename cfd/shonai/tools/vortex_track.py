"""vortex_track.py -- 平均場 (既定 50 s 平均) の主渦 (反時計回り, w > 0) の位置・大きさ・強さの時系列.

usage: python3 vortex_track.py <ケース> [<ケース> ...] [--tmin T] [--block 50] [--out-dir DIR]
  surface_movie.py の読み込みと渦度 (vorticity) をそのまま使う. 計算はしない (表面データを読むだけ).
  核 (core) = 盆地内側 (x > 0.8 m, 壁から 0.2 m 以上) で, 平滑した渦度が最大値の 50 % を超える連結領域. 重心・面積・ピーク渦度・壁までの最短距離を出す.
"""
import argparse, os, sys
import numpy as np
from scipy.ndimage import label, gaussian_filter
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import surface_movie as sm
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def track(path, tmin, block):
    ctx = sm.cfd_context(path)
    data = sm.load_cfd_frames(ctx, tmin, np.inf)
    X, Y, U, V, t = data["X"], data["Y"], data["U"], data["V"], data["t"]
    dx = abs(X[0, 1] - X[0, 0])
    rows, means = [], []
    for t0 in np.arange(t[0], t[-1] - block + 1e-6, block):
        sel = (t >= t0) & (t < t0 + block)
        um, vm = np.nanmean(U[..., sel], 2), np.nanmean(V[..., sel], 2)
        w = sm.vorticity(um, vm, dx)
        # 核の探索: 導水路・ポート付近 (x < 0.8 m) と壁際 0.2 m は薄い強い渦度層があるので除く. 大きな渦だけ追う
        inside = (X > 0.8) & (X < sm.OMEGA_X[1] - 0.2) & (Y > sm.OMEGA_Y[0] + 0.2) & (Y < sm.OMEGA_Y[1] - 0.2)
        ws = gaussian_filter(np.nan_to_num(w), 0.1 / dx) * inside   # 約 0.1 m の幅でさらに平滑
        k = np.unravel_index(np.argmax(ws), ws.shape)
        lab, _ = label(ws > 0.5 * ws[k], structure=np.ones((3, 3)))
        core = lab == lab[k]
        cx, cy = X[core].mean(), Y[core].mean()
        xs, ys = X[core], Y[core]
        wall = min(xs.min() - sm.OMEGA_X[0], sm.OMEGA_X[1] - xs.max(),
                   ys.min() - sm.OMEGA_Y[0], sm.OMEGA_Y[1] - ys.max())
        rows.append((t0 + block / 2, cx, cy, core.sum() * dx * dx, ws[k], wall))
        means.append((t0, um, vm, w, core))
    return np.array(rows), means, X, Y


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cases", nargs="+")
    ap.add_argument("--tmin", type=float, default=300)
    ap.add_argument("--block", type=float, default=50)
    ap.add_argument("--out-dir", default=os.path.expanduser("~/surface_movies/vortex_track"))
    a = ap.parse_args()
    os.makedirs(a.out_dir, exist_ok=True)
    fig, ax = plt.subplots(4, 1, figsize=(8, 9), sharex=True)
    for path in a.cases:
        name = os.path.basename(path.rstrip("/"))
        tmin = a.tmin if "P02" in name else max(a.tmin, 600)
        r, means, X, Y = track(path, tmin, a.block)
        np.savetxt(os.path.join(a.out_dir, name + "_track.csv"), r, delimiter=",", fmt="%.4f",
                   header="t_mid_s,core_x_m,core_y_m,core_area_m2,peak_vorticity_1_s,core_to_wall_m")
        for i, (col, lab) in enumerate([(1, "core x [m]"), (2, "core y [m]"), (3, "core area [m2]"), (4, "peak vorticity [1/s]")]):
            ax[i].plot(r[:, 0], r[:, col], "o-", ms=3, label=name); ax[i].set_ylabel(lab)
        print(name); print("  t_mid   x      y     area   peak   wall")
        for row in r: print("  %5.0f %6.2f %6.2f %6.3f %6.3f %6.3f" % tuple(row))
        n = len(means); cols = min(n, 5); rws = (n + cols - 1) // cols
        f2, a2 = plt.subplots(rws, cols, figsize=(3.2 * cols, 2.2 * rws), squeeze=False)
        for ax2 in a2.ravel(): ax2.axis("off")
        for ax2, (t0, um, vm, w, core) in zip(a2.ravel(), means):
            ax2.pcolormesh(X, Y, w, cmap="RdBu_r", vmin=-0.15, vmax=0.15, shading="auto")
            ax2.contour(X, Y, core.astype(float), [0.5], colors="k", linewidths=1)
            ax2.set_aspect("equal"); ax2.set_title("%s %g-%g s" % (name, t0, t0 + a.block), fontsize=7); ax2.axis("on")
            ax2.set_xticks([]); ax2.set_yticks([])
        f2.tight_layout(); f2.savefig(os.path.join(a.out_dir, name + "_blocks.png"), dpi=90)
    ax[0].legend(); ax[3].set_xlabel("t [s]")
    for x in ax: x.axvline(600, color="gray", ls=":")
    fig.tight_layout(); fig.savefig(os.path.join(a.out_dir, "track.png"), dpi=100)
    print("出力:", a.out_dir)


if __name__ == "__main__":
    main()

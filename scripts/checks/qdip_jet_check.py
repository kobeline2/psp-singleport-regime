#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
qdip_jet_check.py -- Is the inflow discharge dip at h ~ 44-50 mm real?

The water-level discharge Q_level = A_plan * |dh/dt| falls to ~0.35 x nominal
at h ~ 44-50 mm in every inflow run. This tool tests that dip against an
indicator that does not go through the water level: the surface speed of the
port jet measured by PIV at x = 0.19-0.52 m (the "jet proxy"). If the dip were
a real drop in port discharge, the proxy would follow it (log-log slope
beta ~ 0.8-1.1). If the proxy ignores it (beta ~ 0), the port discharge did
not drop and the dip lives in the water-level -> volume step instead.

Verification tool only; it is not part of the s10-s40 MATLAB pipeline.
Procedure, pass/fail criteria and the LT results: doc/qdip_jet_check.md

Reads the machine-local data under <data-root> (default <repo>/local):
  raw/<raw_subdir>/<waterlevel_file>          logger CSV (UTF-16, 1 mm steps)
  derived/metrics/<run_id>/frame_metrics.csv  frame time + depth (from s31)
  work/<run_id>/pivlab_single.mat             canonical PIV (MAT v7.3)
  work/C0001/pivlab_single.mat                optional CFD reference, Q = 0.50 L/s
  work/D02/surfSample/<t>/U_freeSurface.raw   optional CFD reference, Q = 0.75 L/s
Writes CSV and PNG files to <data-root>/derived/qc/qdip_jet_check/.

Usage (from the repository root):
  python3 scripts/checks/qdip_jet_check.py                    # all inflow runs found
  python3 scripts/checks/qdip_jet_check.py --runs R0009,R0010
  python3 scripts/checks/qdip_jet_check.py --mode outflow     # low power, see doc

Requires Python 3.8+, numpy, h5py, matplotlib.
"""
import argparse
import csv
import glob
import os

import h5py
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

PLAN_AREA_M2 = 5.7918      # measured inner plan area (config/constants.m)
PORT_HEIGHT_M = 0.055      # a
GRID_DY_M = 0.0315         # PIV vector spacing (16 px x 1.9667 mm)

BLOCK_S = 5.0              # block-average length for the PIV fields
XWIN_MAIN = (0.19, 0.52)   # x-range of the main jet proxy [m]
XWINS = {"W1": (0.07, 0.25), "W2": XWIN_MAIN, "W3": (0.50, 0.80), "W4": (0.80, 1.25)}
X_BOX = (0.05, 1.30)       # region read from the PIV files [m]
Y_BOX = (0.38, 1.66)       # contains the jet axis (port centre y ~ 0.98 m)

# Depth windows [mm]. "dip" is where Q_level bottoms out in every inflow run.
WINDOWS = {"ref": (32, 38), "pre": (38, 42), "dip": (44, 50), "post": (56, 62),
           "B3": (62, 75), "B4": (75, 95)}
REGRESSION_H_MM = (35, 62) # h-range of the beta regression (Q_level swings ~3x)
BOOT_BLOCK_S = 60.0        # moving-block bootstrap block length

# Pass/fail thresholds (see doc/qdip_jet_check.md).
BETA_SUPPORT_HI95 = 0.5    # upper 95% bound below this -> dip not followed
BETA_CONTRADICT = 0.6      # beta at or above this -> dip followed (real)
MIN_QLEVEL_RANGE = 2.0     # Q_level must swing at least this much in the window
MIN_N_DIP = 0.6            # proxy sensitivity to Q required in the dip window


# ---------------------------------------------------------------------------
# Water level
# ---------------------------------------------------------------------------
def read_logger(path):
    """Logger CSV -> (t_s, h_mm). UTF-16, tab-separated, mm:ss.s wraps hourly."""
    raw = open(path, "rb").read().decode("utf-16")
    raw = raw.replace("\r\n", "\n").replace("\r", "\n")
    t_s, h_mm = [], []
    prev, offset = None, 0.0
    for line in raw.split("\n")[1:]:
        cells = line.split("\t")
        if len(cells) < 4 or not cells[3].strip():
            continue
        try:
            mm, ss = cells[2].split(":")
            sec = int(mm) * 60 + float(ss)
            depth = float(cells[3])
        except ValueError:
            continue
        if prev is not None and sec + offset < prev - 1000:
            offset += 3600.0   # the minutes field wrapped past the hour
        prev = sec + offset
        t_s.append(sec + offset)
        h_mm.append(depth)
    t_s = np.asarray(t_s)
    return t_s - t_s[0], np.asarray(h_mm)


def level_discharge_profile(t_s, h_mm, window_levels=5):
    """Q_level(h) from the dwell time at each 1 mm logger level.

    A raw finite difference of a 1 mm-quantized signal is mostly zeros, so the
    time spent at each integer level is used instead: dh/dt = 1 mm / dwell.
    Q over a window of 5 levels = A * 5 mm / (total dwell). Waves make the
    reading flicker between neighbours, but the window sum is robust to that.
    """
    dt = np.diff(t_s)
    dt = np.append(dt, np.median(dt))         # time each sample is held
    levels = np.arange(31, 100)               # interior levels only
    dwell = np.array([dt[h_mm == L].sum() for L in levels])
    centers_m, q_m3s = [], []
    for i in range(len(levels) - window_levels + 1):
        total = dwell[i:i + window_levels].sum()
        if total <= 0:
            continue
        centers_m.append(levels[i:i + window_levels].mean() / 1000.0)
        q_m3s.append(PLAN_AREA_M2 * window_levels * 1e-3 / total)
    return np.asarray(centers_m), np.asarray(q_m3s)


# ---------------------------------------------------------------------------
# PIV / CFD surface fields
# ---------------------------------------------------------------------------
def coord_slice(values, lo, hi):
    idx = np.where((values >= lo) & (values <= hi))[0]
    return slice(int(idx[0]), int(idx[-1]) + 1)


def safe_argmax(a, axis=-1):
    """argmax that treats NaN as -inf (np.nanargmax raises on all-NaN slices)."""
    return np.argmax(np.where(np.isfinite(a), a, -np.inf), axis=axis)


def box_filter3(field):
    """3x3 box filter over the last two axes (CFD only: mimics the 63 mm PIV window)."""
    pad = np.pad(field, [(0, 0)] * (field.ndim - 2) + [(1, 1), (1, 1)], mode="edge")
    out = np.zeros_like(field)
    nx, ny = field.shape[-2], field.shape[-1]
    for di in (0, 1, 2):
        for dj in (0, 1, 2):
            out += pad[..., di:di + nx, dj:dj + ny]
    return out / 9.0


def load_canonical_blocks(mat_path, smooth=False, chunk_blocks=40):
    """Block-averaged surface fields from a canonical pivlab_single.mat.

    h5py sees the MATLAB arrays transposed: u is (frame, x, y) and the static
    grids are (x, y). Returns block-mean u, v, the speed of the block-mean
    vector, the block mean of the per-frame max speed over y, and the valid
    (typevector == 1) fraction.
    """
    piv = h5py.File(mat_path, "r")["piv"]
    x = piv["x"][()][:, 0]
    y = piv["y"][()][0, :]
    xs, ys = coord_slice(x, *X_BOX), coord_slice(y, *Y_BOX)
    fps = float(np.squeeze(piv["meta/effective_sequence_fps_hz"][()]))
    n_frames = piv["u"].shape[0]
    blk = max(1, int(round(BLOCK_S * fps)))
    n_blocks = n_frames // blk
    bu, bv, fmax, valid = [], [], [], []
    for b0 in range(0, n_blocks, chunk_blocks):
        b1 = min(n_blocks, b0 + chunk_blocks)
        f0, f1 = b0 * blk, b1 * blk
        u = piv["u"][f0:f1, xs, ys]
        v = piv["v"][f0:f1, xs, ys]
        tv = piv["typevector"][f0:f1, xs, ys]
        if smooth:
            u, v = box_filter3(u), box_filter3(v)
        shape = (b1 - b0, blk) + u.shape[1:]
        bu.append(np.nanmean(u.reshape(shape), axis=1))
        bv.append(np.nanmean(v.reshape(shape), axis=1))
        frame_max_y = np.nanmax(np.hypot(u, v), axis=2)              # (frames, x)
        fmax.append(np.nanmean(frame_max_y.reshape((b1 - b0, blk, -1)), axis=1))
        valid.append(np.mean((tv == 1).reshape((b1 - b0, -1)), axis=1))
    bu, bv = np.concatenate(bu), np.concatenate(bv)
    return dict(x=x[xs], y=y[ys], fps=fps, n_frames=n_frames, blk=blk,
                u=bu, v=bv, speed=np.hypot(bu, bv),
                frame_max=np.concatenate(fmax), valid=np.concatenate(valid),
                center_frame=np.arange(n_blocks) * blk + blk // 2)


def load_surfsample_blocks(sample_dir, grid_dx=0.02):
    """OpenFOAM free-surface samples (one directory per time) binned to a grid.

    Each sample is instantaneous and the samples are ~5 s apart, so one sample
    is one block. Depth is the median surface z in the basin interior.
    """
    dirs = [d for d in glob.glob(os.path.join(sample_dir, "*")) if os.path.isdir(d)]
    dirs = sorted(dirs, key=lambda d: float(os.path.basename(d)))
    gx = np.arange(X_BOX[0], X_BOX[1], grid_dx) + grid_dx / 2
    gy = np.arange(Y_BOX[0], Y_BOX[1], grid_dx) + grid_dx / 2
    times, depths, us, vs = [], [], [], []
    for d in dirs:
        files = glob.glob(os.path.join(d, "U_*.raw"))
        if not files:
            continue
        data = np.loadtxt(files[0], comments="#")
        if data.size == 0:
            continue
        px, py, pz, pu, pv = data[:, 0], data[:, 1], data[:, 2], data[:, 3], data[:, 4]
        interior = (px > 1.0) & (px < 2.5) & (py > 0.3) & (py < 1.7)
        ix = np.floor((px - X_BOX[0]) / grid_dx).astype(int)
        iy = np.floor((py - Y_BOX[0]) / grid_dx).astype(int)
        ok = (ix >= 0) & (ix < len(gx)) & (iy >= 0) & (iy < len(gy))
        acc_u = np.zeros((len(gx), len(gy))); acc_v = np.zeros_like(acc_u); cnt = np.zeros_like(acc_u)
        np.add.at(acc_u, (ix[ok], iy[ok]), pu[ok])
        np.add.at(acc_v, (ix[ok], iy[ok]), pv[ok])
        np.add.at(cnt, (ix[ok], iy[ok]), 1)
        with np.errstate(invalid="ignore", divide="ignore"):
            us.append(np.where(cnt > 0, acc_u / cnt, np.nan))
            vs.append(np.where(cnt > 0, acc_v / cnt, np.nan))
        times.append(float(os.path.basename(d)))
        depths.append(float(np.median(pz[interior])))
    u = box_filter3(np.asarray(us)); v = box_filter3(np.asarray(vs))
    return dict(x=gx, y=gy, u=u, v=v, speed=np.hypot(u, v),
                t=np.asarray(times), h=np.asarray(depths))


def jet_proxy(blocks, xwin=XWIN_MAIN, stat="core"):
    """Jet proxy per block.

    core      : max over y of the block-mean speed, averaged over the x-window
                (the main statistic).
    frame_max : block mean of the per-frame max speed over y (no meander
                smearing, slightly noise-biased upward).
    jetflux   : streamwise surface flux over +-3 cells around the jet axis,
                sum(u) dy -- catches "same speed but narrower jet".
    """
    sel = (blocks["x"] >= xwin[0]) & (blocks["x"] <= xwin[1])
    if stat == "core":
        return np.nanmax(blocks["speed"][:, sel, :], axis=2).mean(axis=1)
    if stat == "frame_max":
        return blocks["frame_max"][:, sel].mean(axis=1)
    if stat == "jetflux":
        u = blocks["u"][:, sel, :]
        out = np.zeros(u.shape[:2])
        for b in range(u.shape[0]):
            for i in range(u.shape[1]):
                j = int(safe_argmax(u[b, i]))
                out[b, i] = np.nansum(u[b, i, max(0, j - 3):j + 4]) * GRID_DY_M
        return out.mean(axis=1)
    raise ValueError(stat)


# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------
def window_mean(h_m, values, window):
    lo, hi = window
    m = (h_m * 1000 >= lo) & (h_m * 1000 <= hi)
    return float(np.nanmean(values[m])) if m.any() else np.nan


def ols_slope(x, y):
    xc = x - x.mean()
    return float(np.sum(xc * (y - y.mean())) / np.sum(xc * xc))


def slope_with_bootstrap(x, y, block_len, n_boot, rng):
    """OLS slope and a moving-block bootstrap 95% interval (blocks keep autocorrelation)."""
    beta = ols_slope(x, y)
    n = len(x)
    if n < 2 * block_len:
        return beta, np.nan, np.nan
    n_pick = int(np.ceil(n / block_len))
    boots = np.empty(n_boot)
    for k in range(n_boot):
        starts = rng.integers(0, n - block_len + 1, size=n_pick)
        idx = np.concatenate([np.arange(s, s + block_len) for s in starts])[:n]
        boots[k] = ols_slope(x[idx], y[idx])
    lo, hi = np.percentile(boots, [2.5, 97.5])
    return beta, float(lo), float(hi)


def verdict(qrange, beta_hi_list, beta_list):
    if not np.isfinite(qrange) or qrange < MIN_QLEVEL_RANGE:
        return "low-power"
    if all(np.isfinite(b) and b < BETA_SUPPORT_HI95 for b in beta_hi_list):
        return "dip-not-followed"
    if all(b >= BETA_CONTRADICT for b in beta_list):
        return "dip-followed"
    return "inconclusive"


# ---------------------------------------------------------------------------
# Per-run analysis
# ---------------------------------------------------------------------------
def analyze_run(run, data_root, n_boot, rng):
    rid = run["run_id"]
    mat = os.path.join(data_root, "work", rid, "pivlab_single.mat")
    fmc = os.path.join(data_root, "derived", "metrics", rid, "frame_metrics.csv")
    lgr = os.path.join(data_root, "raw", run["raw_subdir"], run["waterlevel_file"])
    missing = [p for p in (mat, fmc, lgr) if not os.path.isfile(p)]
    if missing:
        return None, "missing " + ", ".join(os.path.relpath(p, data_root) for p in missing)

    t_log, h_log = read_logger(lgr)
    hq, q = level_discharge_profile(t_log, h_log)
    with open(fmc) as f:
        rows = list(csv.DictReader(f))
    frame_t = np.array([float(r["time_s"]) for r in rows])
    frame_h = np.array([float(r["depth_m"]) for r in rows])

    blocks = load_canonical_blocks(mat)
    fi = np.minimum(blocks["center_frame"], len(frame_h) - 1)
    t_b, h_b = frame_t[fi], frame_h[fi]
    q_b = np.interp(h_b, hq, q)

    res = dict(run=run, t=t_b, h=h_b, q=q_b, hq=hq, qprof=q,
               valid=blocks["valid"],
               dur_piv_s=blocks["n_frames"] / blocks["fps"],
               dur_logger_s=float(t_log[-1]),
               n_frames=blocks["n_frames"], n_frame_metrics=len(frame_h))
    res["proxy"] = {(s, w): jet_proxy(blocks, xw, s)
                    for s in ("core", "frame_max", "jetflux") for w, xw in XWINS.items()}
    # Jet axis (W2): y of the block-mean speed maximum, averaged over x columns.
    sel = (blocks["x"] >= XWIN_MAIN[0]) & (blocks["x"] <= XWIN_MAIN[1])
    res["jet_axis_y"] = blocks["y"][safe_argmax(blocks["speed"][:, sel, :], axis=2)].mean(axis=1)

    # Main test: within-run log-log slope over the regression h-range.
    m = (h_b * 1000 >= REGRESSION_H_MM[0]) & (h_b * 1000 <= REGRESSION_H_MM[1])
    res["n_reg_blocks"] = int(m.sum())
    res["qlevel_range"] = float(q_b[m].max() / q_b[m].min()) if m.sum() > 2 else np.nan
    block_len = int(round(BOOT_BLOCK_S / BLOCK_S))
    for s in ("core", "frame_max"):
        p = res["proxy"][(s, "W2")]
        ok = m & np.isfinite(p) & (p > 0)
        res[f"beta_{s}"] = slope_with_bootstrap(np.log(q_b[ok]), np.log(p[ok]), block_len, n_boot, rng)
    res["verdict"] = verdict(res["qlevel_range"],
                             [res["beta_core"][2], res["beta_frame_max"][2]],
                             [res["beta_core"][0], res["beta_frame_max"][0]])
    return res, ""


def cfd_reference(data_root):
    """Same proxy on CFD runs with a constant discharge (optional)."""
    out = {}
    c_mat = os.path.join(data_root, "work", "C0001", "pivlab_single.mat")
    c_fm = os.path.join(data_root, "derived", "metrics", "C0001", "frame_metrics.csv")
    if os.path.isfile(c_mat) and os.path.isfile(c_fm):
        blocks = load_canonical_blocks(c_mat, smooth=True)
        with open(c_fm) as f:
            rows = list(csv.DictReader(f))
        h = np.array([float(r["depth_m"]) for r in rows])
        fi = np.minimum(blocks["center_frame"], len(h) - 1)
        out["C0001"] = dict(q_lps=0.50, h=h[fi], proxy=jet_proxy(blocks))
    d_dir = os.path.join(data_root, "work", "D02", "surfSample")
    if os.path.isdir(d_dir):
        blocks = load_surfsample_blocks(d_dir)
        out["D02"] = dict(q_lps=0.75, h=blocks["h"], proxy=jet_proxy(blocks))
    return out


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def write_csv(path, header, rows):
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)


def ratio(a, b):
    return a / b if (np.isfinite(a) and np.isfinite(b) and b != 0) else np.nan


def calibration_rows(results):
    """Sensitivity n = ln(P_A/P_B) / ln(Q_A/Q_B) between flow levels, per depth window."""
    by_level = {}
    for r in results:
        by_level.setdefault(r["run"]["flow_level"], []).append(r)
    pairs = [(a, b) for a, b in (("medium", "low"), ("high", "medium"), ("high", "low"))
             if a in by_level and b in by_level]
    rows = []
    for a, b in pairs:
        for wname, win in WINDOWS.items():
            pa = np.nanmean([window_mean(r["h"], r["proxy"][("core", "W2")], win) for r in by_level[a]])
            pb = np.nanmean([window_mean(r["h"], r["proxy"][("core", "W2")], win) for r in by_level[b]])
            qa = np.nanmean([window_mean(r["h"], r["q"], win) for r in by_level[a]])
            qb = np.nanmean([window_mean(r["h"], r["q"], win) for r in by_level[b]])
            pr, qr = ratio(pa, pb), ratio(qa, qb)
            n = np.log(pr) / np.log(qr) if (np.isfinite(pr) and np.isfinite(qr) and qr > 0 and qr != 1) else np.nan
            rows.append([f"{a}/{b}", wname, len(by_level[a]), len(by_level[b]), pr, qr, n])
    return rows


def plot_summary(results, cfd, calib, path):
    colors = {"low": "#4C9BE8", "medium": "#E8873A", "high": "#C23B3B"}
    a = PORT_HEIGHT_M
    fig, ax = plt.subplots(1, 3, figsize=(16, 4.8))
    edges = np.arange(0.030, 0.1001, 0.003)
    centers = (edges[1:] + edges[:-1]) / 2
    qnorm = []
    for r in results:
        p = r["proxy"][("core", "W2")]
        pref = window_mean(r["h"], p, WINDOWS["ref"])
        binned = [np.nanmean(p[(r["h"] >= lo) & (r["h"] < hi)]) / pref
                  if np.any((r["h"] >= lo) & (r["h"] < hi)) else np.nan
                  for lo, hi in zip(edges[:-1], edges[1:])]
        ax[0].plot(centers / a, binned, color=colors.get(r["run"]["flow_level"], "k"), lw=1, alpha=.8)
        qnorm.append(np.interp(centers, r["hq"], r["qprof"]) / window_mean(r["h"], r["q"], WINDOWS["ref"]))
    ax[0].plot(centers / a, np.nanmean(qnorm, axis=0), color="red", lw=2.5, label="water-level Q (mean)")
    for name, ls in (("C0001", "--"), ("D02", ":")):
        if name in cfd:
            c = cfd[name]
            pref = window_mean(c["h"], c["proxy"], WINDOWS["ref"])
            e2 = np.arange(0.030, 0.1001, 0.006)
            cb = [np.nanmean(c["proxy"][(c["h"] >= lo) & (c["h"] < hi)]) / pref
                  if np.any((c["h"] >= lo) & (c["h"] < hi)) else np.nan for lo, hi in zip(e2[:-1], e2[1:])]
            ax[0].plot((e2[1:] + e2[:-1]) / 2 / a, cb, "k", ls=ls, lw=1.8, label=f"CFD {name} (Q const {c['q_lps']} L/s)")
    for lvl, c in colors.items():
        ax[0].plot([], [], color=c, label=f"PIV jet proxy, {lvl}")
    ax[0].axvspan(WINDOWS["dip"][0] / 1000 / a, WINDOWS["dip"][1] / 1000 / a, color="red", alpha=.1)
    ax[0].axvline(1, color="k", lw=.6)
    ax[0].set(xlabel="h/a", ylabel="normalized to h = 32-38 mm", ylim=(0, 1.8),
              title="(a) jet proxy vs water-level Q")
    ax[0].legend(fontsize=7, loc="upper right"); ax[0].grid(alpha=.3)

    lo_mm, hi_mm = REGRESSION_H_MM
    xx = np.linspace(-0.8, 0.6, 10)
    allx, ally = [], []
    for r in results:
        p = r["proxy"][("core", "W2")]
        m = (r["h"] * 1000 >= lo_mm) & (r["h"] * 1000 <= hi_mm) & np.isfinite(p) & (p > 0)
        lx, ly = np.log(r["q"][m]), np.log(p[m])
        lx, ly = lx - lx.mean(), ly - ly.mean()
        allx.append(lx); ally.append(ly)
        ax[1].plot(lx, ly, ".", ms=3, alpha=.5, color=colors.get(r["run"]["flow_level"], "k"))
    if allx:
        pooled = ols_slope(np.concatenate(allx), np.concatenate(ally))
        ax[1].plot(xx, pooled * xx, "k", lw=2, label=f"observed pooled slope {pooled:+.2f}")
    ax[1].fill_between(xx, 0.8 * xx, 1.1 * xx, color="red", alpha=.15, label="expected if the dip were real (0.8-1.1)")
    ax[1].set(xlabel="log Q_level (run-demeaned)", ylabel="log jet proxy (run-demeaned)",
              title=f"(b) within run, h = {lo_mm}-{hi_mm} mm")
    ax[1].legend(fontsize=7, loc="lower right"); ax[1].grid(alpha=.3)

    markers = {"medium/low": "o", "high/medium": "s", "high/low": "^"}
    for pair, wname, _, _, pr, qr, _ in calib:
        if np.isfinite(pr) and np.isfinite(qr):
            ax[2].plot(qr, pr, markers.get(pair, "o"), color="red" if wname == "dip" else "k")
            ax[2].annotate(wname, (qr, pr), textcoords="offset points", xytext=(4, 3), fontsize=6)
    for pair in sorted({row[0] for row in calib}):
        ax[2].plot([], [], markers.get(pair, "o"), color="k", ls="none", label=pair)
    g = np.linspace(1, 3.5, 10)
    ax[2].plot(g, g, "k--", lw=.8, label="proportional (n = 1)")
    ax[2].plot(g, np.ones_like(g), color="0.6", lw=.8, label="no response (n = 0)")
    ax[2].set(xlabel="Q ratio between levels (water level, same h window)",
              ylabel="jet proxy ratio", title="(c) proxy responds to Q (across levels)")
    ax[2].legend(fontsize=7); ax[2].grid(alpha=.3)
    plt.tight_layout(); plt.savefig(path, dpi=120); plt.close(fig)


def plot_timeseries(results, path):
    a = PORT_HEIGHT_M
    ncol = 4
    nrow = int(np.ceil(len(results) / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(4.2 * ncol, 3.4 * nrow), squeeze=False)
    for ax, r in zip(axes.flat, results):
        p = r["proxy"][("core", "W2")]
        ref = (r["h"] * 1000 >= WINDOWS["ref"][0]) & (r["h"] * 1000 <= WINDOWS["ref"][1])
        geo = 1.0 / np.minimum(r["h"], a)     # port-exit velocity factor Q/(b min(h,a))
        if_real = r["q"] * geo
        if_const = geo
        s = np.nanmean(p[ref])
        ax.plot(r["t"], p, "k", lw=.9, label="PIV jet proxy")
        ax.plot(r["t"], if_real / np.nanmean(if_real[ref]) * s, color="red", lw=1.1, label="if Q = water-level Q")
        ax.plot(r["t"], if_const / np.nanmean(if_const[ref]) * s, color="tab:blue", ls="--", lw=1.1, label="if Q = const")
        dip = (r["h"] * 1000 >= WINDOWS["dip"][0]) & (r["h"] * 1000 <= WINDOWS["dip"][1])
        if dip.any():
            ax.axvspan(r["t"][dip].min(), r["t"][dip].max(), color="red", alpha=.1)
        ax.set_ylim(0, None)
        ax.set_title(f"{r['run']['run_id']} {r['run']['mode']} {r['run']['flow_level']}  beta={r['beta_core'][0]:+.2f}", fontsize=9)
        ax.set_xlabel("t [s]")
        ax2 = ax.twinx()
        ax2.plot(r["t"], r["h"] * 1000, color="tab:green", lw=.7, alpha=.7)
        ax2.set_ylim(20, 105)
    for ax in list(axes.flat)[len(results):]:
        ax.axis("off")
    axes.flat[0].legend(fontsize=7, loc="upper right")
    plt.tight_layout(); plt.savefig(path, dpi=110); plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--data-root", default=os.path.join(REPO, "local"))
    ap.add_argument("--runs", default="", help="comma-separated run IDs (default: every run of --mode)")
    ap.add_argument("--mode", default="inflow", choices=["inflow", "outflow", "all"])
    ap.add_argument("--out", default="", help="output folder (default <data-root>/derived/qc/qdip_jet_check)")
    ap.add_argument("--no-cfd", action="store_true", help="skip the CFD constant-Q reference")
    ap.add_argument("--n-boot", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    out_dir = args.out or os.path.join(args.data_root, "derived", "qc", "qdip_jet_check")
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(REPO, "metadata", "runs.csv")) as f:
        runs = [r for r in csv.DictReader(f) if r["run_id"].startswith("R")]
    if args.runs:
        wanted = [s.strip() for s in args.runs.split(",") if s.strip()]
        runs = [r for r in runs if r["run_id"] in wanted]
    elif args.mode != "all":
        runs = [r for r in runs if r["mode"] == args.mode]

    rng = np.random.default_rng(args.seed)
    results = []
    for run in runs:
        res, why = analyze_run(run, args.data_root, args.n_boot, rng)
        if res is None:
            print(f"{run['run_id']}: skipped ({why})")
            continue
        results.append(res)
        b, bf = res["beta_core"], res["beta_frame_max"]
        print(f"{run['run_id']} {run['mode']:7s} {run['flow_level']:6s} "
              f"beta_core={b[0]:+.2f} [{b[1]:+.2f},{b[2]:+.2f}]  "
              f"beta_frame_max={bf[0]:+.2f} [{bf[1]:+.2f},{bf[2]:+.2f}]  "
              f"Q_level range x{res['qlevel_range']:.1f}  -> {res['verdict']}", flush=True)
    if not results:
        print("No run could be analyzed.")
        return

    # Per-run summary
    rows = []
    for r in results:
        run, p = r["run"], r["proxy"][("core", "W2")]
        wq = {k: window_mean(r["h"], r["q"], w) for k, w in WINDOWS.items()}
        wp = {k: window_mean(r["h"], p, w) for k, w in WINDOWS.items()}
        wv = {k: window_mean(r["h"], r["valid"], w) for k, w in WINDOWS.items()}
        wy = {k: window_mean(r["h"], r["jet_axis_y"], w) for k, w in WINDOWS.items()}
        rows.append([run["run_id"], run["mode"], run["flow_level"], r["n_frames"], r["n_frame_metrics"],
                     round(r["dur_piv_s"], 1), round(r["dur_logger_s"], 1),
                     round(r["dur_piv_s"] - r["dur_logger_s"], 1),
                     r["n_reg_blocks"], r["qlevel_range"],
                     ratio(wq["pre"], wq["ref"]), ratio(wq["dip"], wq["ref"]), ratio(wq["dip"], wq["pre"]), ratio(wq["post"], wq["ref"]),
                     ratio(wp["pre"], wp["ref"]), ratio(wp["dip"], wp["ref"]), ratio(wp["dip"], wp["pre"]), ratio(wp["post"], wp["ref"]),
                     *r["beta_core"], *r["beta_frame_max"],
                     wv["ref"], wv["dip"], wy["ref"], wy["dip"], r["verdict"]])
    write_csv(os.path.join(out_dir, "run_summary.csv"),
              ["run_id", "mode", "flow_level", "n_frames", "n_frame_metrics",
               "dur_piv_s", "dur_logger_s", "dur_diff_s", "n_reg_blocks", "qlevel_range",
               "Q_pre_ref", "Q_dip_ref", "Q_dip_pre", "Q_post_ref",
               "P_pre_ref", "P_dip_ref", "P_dip_pre", "P_post_ref",
               "beta_core", "beta_core_lo95", "beta_core_hi95",
               "beta_frame_max", "beta_frame_max_lo95", "beta_frame_max_hi95",
               "valid_ref", "valid_dip", "jet_axis_y_ref", "jet_axis_y_dip", "verdict"], rows)

    # Window ratios for every statistic x x-window (the "no V-shape anywhere" check)
    rows = []
    for r in results:
        for (s, w), p in r["proxy"].items():
            wp = {k: window_mean(r["h"], p, win) for k, win in WINDOWS.items()}
            rows.append([r["run"]["run_id"], s, w, *XWINS[w],
                         ratio(wp["dip"], wp["ref"]), ratio(wp["dip"], wp["pre"]), ratio(wp["post"], wp["ref"])])
    write_csv(os.path.join(out_dir, "window_ratios.csv"),
              ["run_id", "stat", "xwin", "x_lo_m", "x_hi_m", "dip_ref", "dip_pre", "post_ref"], rows)

    calib = calibration_rows(results)
    write_csv(os.path.join(out_dir, "calibration.csv"),
              ["pair", "window", "n_runs_a", "n_runs_b", "proxy_ratio", "Q_ratio", "n_sensitivity"], calib)
    print("\nSensitivity n between flow levels (core, W2):")
    for pair, wname, na, nb, pr, qr, n in calib:
        flag = "  <- must be >= %.1f" % MIN_N_DIP if wname == "dip" else ""
        print(f"  {pair:12s} {wname:5s} (runs {na}/{nb}) proxy x{pr:.2f}  Q x{qr:.2f}  n={n:+.2f}{flag}")

    cfd = {} if args.no_cfd else cfd_reference(args.data_root)
    if cfd:
        rows = []
        print("\nCFD constant-Q reference (core, W2; ratios to the ref window):")
        for name, c in cfd.items():
            w = {k: window_mean(c["h"], c["proxy"], win) for k, win in WINDOWS.items()}
            rr = [ratio(w[k], w["ref"]) for k in ("pre", "dip", "post", "B3", "B4")]
            rows.append([name, c["q_lps"], *rr, ratio(w["dip"], w["pre"])])
            print(f"  {name} Q={c['q_lps']} L/s: pre {rr[0]:.2f} dip {rr[1]:.2f} post {rr[2]:.2f} "
                  f"B3 {rr[3]:.2f} B4 {rr[4]:.2f}  dip/pre {ratio(w['dip'], w['pre']):.2f}")
        write_csv(os.path.join(out_dir, "cfd_reference.csv"),
                  ["case", "Q_Lps", "pre_ref", "dip_ref", "post_ref", "B3_ref", "B4_ref", "dip_pre"], rows)

    plot_summary(results, cfd, calib, os.path.join(out_dir, "summary.png"))
    plot_timeseries(results, os.path.join(out_dir, "timeseries.png"))
    counts = {}
    for r in results:
        counts[r["verdict"]] = counts.get(r["verdict"], 0) + 1
    print(f"\nVerdicts: {counts}")
    print(f"Outputs written to {out_dir}")


if __name__ == "__main__":
    main()

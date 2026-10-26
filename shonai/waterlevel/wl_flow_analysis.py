#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
wl_flow_analysis.py -- upper/lower basin water levels and discharge, inflow and outflow.

Question: is the dip of the discharge computed from the UPPER water level (doc/qdip_jet_check.md)
a real drop of the pumped discharge? The lower basin gives a second, independent level record.

Discharge conventions follow the repo (psp-singleport-regime):
  * Q_level(h)  dwell time at each 1 mm logger level, 5-level window,
                Q = A_plan * 5 mm / total dwell                (scripts/checks/qdip_jet_check.py)
  * Q_transit   dV_band / T_band per depth band B1-B4, dV_band = (A + 0.6 b) * (part below a) + A * (part above a)
                                                               (doc/metrics_primer.md, s33)
  * Q(t)        A * |dh/dt|; here a block-mean difference over 60 s (the logger samples at 0.1-0.3 s, so
                np.gradient of a moving mean would only see the window edges).
Time alignment: t = 0 is the first sample of the upper record (30 -> 100 mm); the lower record is cut to it.

The lower-basin plan area is NOT known (drawing: ~1.89 m^2 before the pumps; steady-slope ratio: ~1.63 m^2),
so every lower-basin discharge is provisional and the figures show the range --lower-area-range.
The lower logger saturates at its 4-20 mA full scale (~111 mm in run 1, ~78 mm in run 2, because the
logger scaling differs between runs); readings near and below that level are not used.

Usage (repo root; the raw logger files stay outside the repo):
  python3 shonai/waterlevel/wl_flow_analysis.py --label run1 \
      --upper-inflow U_in.csv --upper-outflow U_out.csv --lower-inflow L_in.CSV --lower-outflow L_out.CSV \
      --lower-valid-mm 125
Outputs go to <repo>/local/derived/qc/waterlevel_two_basin/<label>/ (gitignored) unless --out is given.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from load_wl import clock, load_run, read_lower_scaling   # noqa: E402

from matplotlib import font_manager   # noqa: E402
_installed = {f.name for f in font_manager.fontManager.ttflist}
plt.rcParams["font.family"] = [f for f in ("IPAGothic", "Hiragino Sans", "Yu Gothic", "Meiryo") if f in _installed] + ["DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

C_UP = "#CC4729"      # upper basin: red-orange of the deck palette (slides/gen_assets.py)
C_LOW = "#3378B8"     # lower basin: "medium" blue of the deck palette

A_UP = 5.7918         # measured inner plan area of the upper basin [m^2] (config/constants.m)
PORT_H_MM = 55.0      # port height a
CHANNEL_FOOT_M2 = 0.6 * 0.11    # supply-channel footprint assumed by the repo (0.6 m x b)
BANDS = [("B1", 30, 50), ("B2", 50, 60), ("B3", 60, 75), ("B4", 75, 100)]   # metadata/depth_bands.csv
SMOOTH_S = 60.0       # smoothing window of Q(t) [s]
LOWER_VALID_MM = 0.0  # set from --lower-valid-mm in main()


# ---------------------------------------------------------------------------
# signal helpers
# ---------------------------------------------------------------------------
def movmean(t, h, w):
    """Centered moving mean over a time window w [s] on a possibly non-uniform grid."""
    cs = np.concatenate([[0], np.cumsum(h)])
    lo = np.searchsorted(t, t - w / 2, "left")
    hi = np.searchsorted(t, t + w / 2, "right")
    return (cs[hi] - cs[lo]) / (hi - lo)


def q_smooth(t, h_mm, area_m2, w):
    """A*|dh/dt| [L/s] as the difference of two w/2-second block means (w/2 apart), centred on t.
    h in mm, so 1 mm over 1 m^2 = 1 L."""
    half = w / 2.0
    m = movmean(t, h_mm, half)
    ahead = np.interp(t + half / 2, t, m)
    behind = np.interp(t - half / 2, t, m)
    ahead[t + half / 2 > t[-1]] = np.nan
    behind[t - half / 2 < t[0]] = np.nan
    return area_m2 * np.abs(ahead - behind) / half


def q_dwell(t, h_mm, win=5):
    """Q(h) from the dwell time at each 1 mm level (upper logger only), as in qdip_jet_check.py."""
    dt = np.append(np.diff(t), np.median(np.diff(t)))
    levels = np.arange(31, 100)
    dwell = np.array([dt[h_mm == lv].sum() for lv in levels])
    centers, q = [], []
    for i in range(len(levels) - win + 1):
        tot = dwell[i:i + win].sum()
        if tot > 0:
            centers.append(levels[i:i + win].mean())
            q.append(A_UP * win * 1e-3 / tot * 1000.0)
    return np.array(centers), np.array(q)


def moving_span(tl, hl, trim_s=30.0):
    """(t_start, t_end) of the period in which the lower level moves at its steady rate and the reading is
    valid (excludes the start-up ramp, the stop and the saturated part), trimmed by trim_s at both ends."""
    hs = movmean(tl, hl, 20.0)
    slope = np.abs(np.gradient(hs, tl))
    valid = hs > LOWER_VALID_MM
    steady = np.median(slope[valid])
    idx = np.where((slope > 0.6 * steady) & valid)[0]
    gaps = np.where(np.diff(tl[idx]) > 20.0)[0]          # longest contiguous run, gaps <= 20 s allowed
    starts, ends = np.r_[0, gaps + 1], np.r_[gaps, len(idx) - 1]
    k = np.argmax(tl[idx][ends] - tl[idx][starts])
    return tl[idx][starts[k]] + trim_s, tl[idx][ends[k]] - trim_s


def crossing_time(tu, hs, level, mode):
    """First time the (smoothed) upper level reaches `level` (rising for inflow, falling for outflow)."""
    i = np.argmax(hs >= level) if mode == "inflow" else np.argmax(hs <= level)
    return tu[i]


# ---------------------------------------------------------------------------
# tables
# ---------------------------------------------------------------------------
def window_table(d, a_low, out_csv, step_mm=6, first_mm=32, last_mm=86):
    """Q from linear fits of the level over the time the upper basin spends in each depth window.
    The lower-basin Q is also taken with the window shifted by -60 s and +60 s (line storage / lag)."""
    def fit_q(t, h, area, t1, t2):
        lo, hi = min(t1, t2), max(t1, t2)
        m = (t >= lo) & (t <= hi)
        return area * abs(np.polyfit(t[m] - lo, h[m], 1)[0]) if m.sum() > 10 else float("nan")

    rows = []
    for mode in ("inflow", "outflow"):
        tu, hu = d[("upper", mode)]
        tl, hl = d[("lower", mode)]
        ts, te = moving_span(tl, hl, trim_s=5.0)
        hs = movmean(tu, hu, 3.0)
        levels = list(range(first_mm, last_mm + 1, step_mm))
        tt = [crossing_time(tu, hs, lv, mode) for lv in levels]
        for a, b, la, lb in zip(tt[:-1], tt[1:], levels[:-1], levels[1:]):
            row = [mode, f"{la}-{lb}", abs(b - a), fit_q(tu, hu, A_UP, a, b)]
            for lag in (0, -60, 60):
                t1, t2 = a + lag, b + lag
                inside = ts <= min(t1, t2) and max(t1, t2) <= te
                row.append(fit_q(tl, hl, a_low, t1, t2) if inside else float("nan"))
            rows.append(row)
    with open(out_csv, "w", encoding="utf-8") as f:
        f.write("mode,upper_window_mm,T_s,Q_upper_Lps,Q_lower_lag0_Lps,Q_lower_lagm60_Lps,Q_lower_lagp60_Lps\n")
        for r in rows:
            f.write("%s,%s,%.1f,%.3f,%.3f,%.3f,%.3f\n" % tuple(r))
    return rows


def band_table(d, a_low, out_csv):
    """Transit-time discharge per depth band B1-B4: upper level (repo method) and lower level (provisional)."""
    rows = []
    for mode in ("inflow", "outflow"):
        tu, hu = d[("upper", mode)]
        tl, hl = d[("lower", mode)]
        hs = movmean(tu, hu, 3.0)
        hls = movmean(tl, hl, 5.0)
        ts, te = moving_span(tl, hl, trim_s=0.0)
        for name, lo, hi in BANDS:
            inside = np.where((hs >= lo) & (hs < hi))[0]
            if inside.size == 0:
                continue
            t_in, t_out = tu[inside[0]], tu[inside[-1]]
            below = max(0.0, min(hi, PORT_H_MM) - lo) * 1e-3          # m of the band below a
            above = (hi - lo) * 1e-3 - below
            dv_l = ((A_UP + CHANNEL_FOOT_M2) * below + A_UP * above) * 1000.0
            q_up = dv_l / (t_out - t_in)
            ok = ts <= t_in and t_out <= te
            q_low = a_low * abs(np.interp(t_in, tl, hls) - np.interp(t_out, tl, hls)) / (t_out - t_in) if ok else float("nan")
            rows.append((mode, name, t_out - t_in, dv_l, q_up, q_low))
    with open(out_csv, "w", encoding="utf-8") as f:
        f.write("mode,band,T_band_s,dV_band_L,Q_transit_upper_Lps,Q_lower_equiv_Lps_provisional\n")
        for r in rows:
            f.write("%s,%s,%.1f,%.2f,%.3f,%.3f\n" % r)
    return rows


def dwell_table(d, out_csv):
    with open(out_csv, "w", encoding="utf-8") as f:
        f.write("mode,h_center_mm,Q_level_upper_Lps\n")
        for mode in ("inflow", "outflow"):
            tu, hu = d[("upper", mode)]
            for c, q in zip(*q_dwell(tu, hu)):
                f.write("%s,%.0f,%.3f\n" % (mode, c, q))


# ---------------------------------------------------------------------------
# figures
# ---------------------------------------------------------------------------
def plot_aligned(d, out, title_prefix=""):
    """Upper level (30 <-> 100 mm record) and the lower level on the same clock (t = 0: start of the upper record).
    Vertical lines: times at which the upper level passes 50, 55 (port height) and 60 mm.
    Grey: part of the lower record where the logger is saturated / not moving (reading not valid)."""
    fig, ax = plt.subplots(2, 2, figsize=(14, 7.5), sharex="col")
    for c, mode in enumerate(("inflow", "outflow")):
        tu, hu = d[("upper", mode)]
        tl, hl = d[("lower", mode)]
        t0, t1 = tu[0], tu[-1]
        m = (tl >= t0) & (tl <= t1)
        ts, te = moving_span(tl, hl, trim_s=0.0)
        hs = movmean(tu, hu, 3.0)
        ax[0, c].plot(tu - t0, hu, color=C_UP, lw=1.1)
        ax[0, c].set(title=f"{title_prefix}{mode}  (t=0: 上池の記録開始 {clock(t0)})", ylabel="上池 水位 [mm]")
        ax[1, c].plot(tl[m] - t0, hl[m], color=C_LOW, lw=0.4, alpha=0.30)
        ax[1, c].plot(tl[m] - t0, movmean(tl, hl, 5.0)[m], color=C_LOW, lw=1.2)
        ax[1, c].set(xlabel="時刻 [s]  (上池の記録開始から)", ylabel="下池 水位 [mm]")
        for lo, hi in ((t0, ts), (te, t1)):
            lo_, hi_ = max(lo, t0), min(hi, t1)
            if hi_ - lo_ > 5:
                ax[1, c].axvspan(lo_ - t0, hi_ - t0, color="0.88")
                ax[1, c].text((lo_ + hi_) / 2 - t0, np.nanmin(hl[m]) + 8, "水位計 飽和/静止",
                              ha="center", fontsize=8, color="dimgray")
        for lvl, ls_, lab in ((50, "--", "50 mm"), (55, "-", "ポート高 55 mm"), (60, "--", "60 mm")):
            tx = crossing_time(tu, hs, lvl, mode) - t0
            for r in (0, 1):
                ax[r, c].axvline(tx, ls=ls_, lw=0.8, color="gray")
            ax[0, c].text(tx, ax[0, c].get_ylim()[1], f" {lab}", va="top", fontsize=8, color="gray")
        for r in (0, 1):
            ax[r, c].grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(out, dpi=140)
    plt.close(fig)


def plot_discharge_aligned(d, a_range, out, nominal, title_prefix=""):
    """Q(t) from the upper level (red) and from the lower level (blue band for the area range a_range)."""
    fig, ax = plt.subplots(2, 1, figsize=(11, 8))
    for r, mode in enumerate(("inflow", "outflow")):
        tu, hu = d[("upper", mode)]
        tl, hl = d[("lower", mode)]
        t0, t1 = tu[0], tu[-1]
        hs = movmean(tu, hu, 3.0)
        qu = q_smooth(tu, hu, A_UP, SMOOTH_S)
        qu[(tu - t0 < SMOOTH_S / 2) | (t1 - tu < SMOOTH_S / 2)] = np.nan
        ts, te = moving_span(tl, hl, trim_s=SMOOTH_S / 2)
        sel = (tl >= max(ts, t0)) & (tl <= min(te, t1))
        q_lo = q_smooth(tl, hl, a_range[0], SMOOTH_S)
        q_hi = q_smooth(tl, hl, a_range[1], SMOOTH_S)
        ax[r].plot(tu - t0, qu, color=C_UP, lw=1.3, label=f"上池の水位から A_plan×|dh/dt| ({SMOOTH_S:.0f} s平滑, A={A_UP} m²)")
        ax[r].fill_between(tl[sel] - t0, q_lo[sel], q_hi[sel], color=C_LOW, alpha=0.25,
                           label=f"下池の水位から A_low×|dh/dt| (A_low={a_range[0]:.2f}〜{a_range[1]:.2f} m²)")
        ax[r].plot(tl[sel] - t0, q_hi[sel], color=C_LOW, lw=0.9)
        ax[r].axhline(nominal, ls="--", lw=0.8, color="gray")
        ax[r].text(t1 - t0, nominal, f" 設定 {nominal:g}", va="bottom", ha="right", fontsize=8, color="gray")
        for lvl, ls_, lab in ((50, "--", "上池 50 mm"), (55, "-", "ポート高 55 mm"), (60, "--", "60 mm")):
            tx = crossing_time(tu, hs, lvl, mode) - t0
            ax[r].axvline(tx, ls=ls_, lw=0.8, color="gray")
            ax[r].text(tx, 1.17, lab, rotation=90, va="top", ha="right", fontsize=8, color="gray")
        ax[r].set(title=f"{title_prefix}{mode}: 流量 Q(t)  (t=0: 上池の記録開始 {clock(t0)})",
                  xlabel="時刻 [s]  (上池の記録開始から)", ylabel="Q [L/s]", ylim=(0, 1.2), xlim=(0, t1 - t0))
        ax[r].grid(alpha=0.3)
        ax[r].legend(fontsize=8, loc="lower center")
    fig.tight_layout()
    fig.savefig(out, dpi=140)
    plt.close(fig)


def plot_lower_linearity(d, a_low, out):
    """Does the lower level change at a constant rate? Linear fit, residual and 60 s local rate."""
    fig, ax = plt.subplots(2, 3, figsize=(16, 7.5))
    stats = []
    for r, mode in enumerate(("inflow", "outflow")):
        tl, hl = d[("lower", mode)]
        ts, te = moving_span(tl, hl)
        core = (tl >= ts) & (tl <= te)
        tc, hc = tl[core], hl[core]
        p = np.polyfit(tc - tc[0], hc, 1)
        fit = np.polyval(p, tc - tc[0])
        res = hc - fit
        r2 = 1 - np.sum(res ** 2) / np.sum((hc - hc.mean()) ** 2)
        bt, bq = [], []
        for e in np.arange(tc[0], tc[-1] - 60, 60.0):
            m = (tc >= e) & (tc < e + 60)
            bt.append(e + 30 - tl[0])
            bq.append(abs(np.polyfit(tc[m] - e, hc[m], 1)[0]))
        bq = np.array(bq)
        t0 = tl[0]
        ax[r, 0].plot((tl - t0) / 60, hl, lw=0.4, color=C_LOW, alpha=0.5)
        ax[r, 0].plot((tc - t0) / 60, fit, color="k", lw=1.2, label=f"直線近似 傾き {p[0]:+.3f} mm/s,  R²={r2:.4f}")
        ax[r, 0].set(title=f"{mode}: 下池の水位と直線近似(定速で動いた区間)", xlabel="時刻 [min]", ylabel="下池 水位 [mm]")
        ax[r, 0].legend(fontsize=9)
        ax[r, 1].plot((tc - t0) / 60, res, lw=0.5, color=C_UP)
        ax[r, 1].plot((tc - t0) / 60, movmean(tc, res, 20.0), lw=1.5, color=C_LOW, label="20 s 移動平均")
        ax[r, 1].axhline(0, color="gray", lw=0.6)
        ax[r, 1].set(title=f"{mode}: 直線からのずれ (標準偏差 {res.std():.2f} mm)", xlabel="時刻 [min]", ylabel="残差 [mm]")
        ax[r, 1].legend(fontsize=9)
        ax[r, 2].plot(np.array(bt) / 60, bq * a_low, "o-", color=C_LOW)
        ax[r, 2].axhline(abs(p[0]) * a_low, color="k", lw=0.8, ls="--", label="全体の傾きから")
        ax[r, 2].set(title=f"{mode}: 60 s ごとの流量 A_low×|dh/dt| (暫定 A_low={a_low:.2f} m²)", xlabel="時刻 [min]",
                     ylabel="Q [L/s]", ylim=(0, 1.0))
        ax[r, 2].legend(fontsize=9)
        for a in ax[r]:
            a.grid(alpha=0.3)
        stats.append((mode, p[0], r2, res.std(), bq.std() / bq.mean()))
    fig.tight_layout()
    fig.savefig(out, dpi=140)
    plt.close(fig)
    return stats


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    for name in ("upper-inflow", "upper-outflow", "lower-inflow", "lower-outflow"):
        ap.add_argument(f"--{name}", required=True, help=f"{name} logger file")
    ap.add_argument("--label", default="run", help="name of this measurement set (output sub-folder)")
    ap.add_argument("--out", default=None, help="output folder (default: <repo>/local/derived/qc/waterlevel_two_basin/<label>)")
    ap.add_argument("--lower-valid-mm", type=float, default=None,
                    help="ignore lower-logger readings below this level [mm] (default: lowest reading + 40 mm)")
    ap.add_argument("--lower-area", type=float, default=1.63, help="lower plan area for the single-valued tables [m^2]")
    ap.add_argument("--lower-area-range", type=float, nargs=2, default=(1.63, 1.89), metavar=("A_MIN", "A_MAX"),
                    help="lower plan area range drawn in the discharge figure [m^2]")
    ap.add_argument("--nominal-lps", type=float, default=0.75, help="set discharge [L/s] drawn as a dashed line")
    args = ap.parse_args()

    global LOWER_VALID_MM
    d = load_run(args.upper_inflow, args.upper_outflow, args.lower_inflow, args.lower_outflow)
    floor = min(np.min(movmean(*d[("lower", m)], 5.0)) for m in ("inflow", "outflow"))
    LOWER_VALID_MM = args.lower_valid_mm if args.lower_valid_mm is not None else floor + 40.0
    out = args.out or os.path.join(REPO, "local", "derived", "qc", "waterlevel_two_basin", args.label)
    os.makedirs(out, exist_ok=True)
    print(f"lowest lower reading {floor:.1f} mm -> readings below {LOWER_VALID_MM:.0f} mm are not used")
    for mode in ("inflow", "outflow"):
        tu, hu = d[("upper", mode)]
        tl, hl = d[("lower", mode)]
        print(f"{mode}: upper {clock(tu[0])} - {clock(tu[-1])} ({hu[0]:.0f} -> {hu[-1]:.0f} mm), "
              f"lower {clock(tl[0])} - {clock(tl[-1])} ({hl[0]:.0f} -> {hl[-1]:.0f} mm)")
    for mode in ("inflow", "outflow"):
        sc = read_lower_scaling({"inflow": args.lower_inflow, "outflow": args.lower_outflow}[mode])
        print(f"  lower logger scaling ({mode}): 計測値 {sc[0]}, {sc[1]} -> 表示値 {sc[2]}, {sc[3]}")

    plot_aligned(d, os.path.join(out, "levels_aligned.png"), title_prefix=f"{args.label} ")
    plot_discharge_aligned(d, tuple(args.lower_area_range), os.path.join(out, "discharge_aligned.png"),
                           args.nominal_lps, title_prefix=f"{args.label} ")
    for st in plot_lower_linearity(d, args.lower_area, os.path.join(out, "lower_level_linearity.png")):
        print("lower level (%s): slope %+.4f mm/s  R2=%.4f  resid std %.2f mm  60 s-rate CV %.1f%%"
              % (st[0], st[1], st[2], st[3], 100 * st[4]))
    for r in window_table(d, args.lower_area, os.path.join(out, "window_Q.csv")):
        print("%-8s %-6s T=%5.1fs  Q_up=%.3f  Q_low(0/-60/+60)=%.3f/%.3f/%.3f" % tuple(r))
    for r in band_table(d, args.lower_area, os.path.join(out, "band_transit_Q.csv")):
        print("%-8s %s  T=%6.1f s  dV=%6.1f L  Q_up=%.3f  Q_low(prov.)=%.3f L/s" % r)
    dwell_table(d, os.path.join(out, "dwell_Q_upper.csv"))
    print("wrote", out)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_assets.py -- matplotlib figures + TeX equation images for the paper-1
progress deck (build_deck.py). Reads the machine-local derived metrics
(local/derived/metrics/), so run it on a machine that has them; the outputs
are committed in assets/ so the deck itself rebuilds anywhere.
"""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib as mpl

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MET  = os.path.join(REPO, "local", "derived", "metrics")
OUT  = os.path.join(HERE, "assets")
os.makedirs(OUT, exist_ok=True)

mpl.rcParams.update({
    "font.size": 17, "axes.titlesize": 19, "axes.labelsize": 18,
    "xtick.labelsize": 15, "ytick.labelsize": 15, "legend.fontsize": 15,
    "axes.spines.top": False, "axes.spines.right": False,
    "mathtext.fontset": "cm", "axes.unicode_minus": False,
    "figure.facecolor": "white", "savefig.facecolor": "white",
})

INK    = "#1A1A1A"
KUBLUE = "#00205B"
POS    = "#CC4729"   # I_circ > 0, counterclockwise branch (matches paper figure)
NEG    = "#1A59A6"   # I_circ < 0, clockwise branch
LEVELC = {"low": "#8CBFEA", "medium": "#3378B8", "high": "#0D295C"}
LEVELM = {"low": "o", "medium": "s", "high": "^"}
A_M    = 0.055

bm = pd.read_csv(os.path.join(MET, "band_metrics.csv"))
bm = bm[bm.run_id.str.startswith("R")]
bs = pd.read_csv(os.path.join(MET, "branch_stats.csv"))
bs = bs[(bs["mode"] == "inflow") & bs.run_id.str.startswith("R")].reset_index(drop=True)

runs = pd.read_csv(os.path.join(REPO, "metadata", "runs.csv"))
level_of = dict(zip(runs.run_id, runs.flow_level))
date_of  = dict(zip(runs.run_id, runs.date.astype(str)))

def save(fig, name):
    p = os.path.join(OUT, name)
    fig.savefig(p, dpi=200, bbox_inches="tight", pad_inches=0.12)
    plt.close(fig)
    print("wrote", p)

# ---------------------------------------------------------------- A1 traces
# I_circ against h/a for the four medium repetitions: locked traces, one flipped.
fig, ax = plt.subplots(figsize=(11.2, 5.0))
ax.axhline(0, color="0.35", lw=1.2)
ax.axvspan(1.09, 1.82, color="0.92", zorder=0)
ax.text(1.45, 0.0125, "deep bands $B_3$+$B_4$\n(branch statistics window)",
        ha="center", va="top", fontsize=14, color="0.35")
for rid in ["R0005", "R0006", "R0007", "R0008"]:
    fm = pd.read_csv(os.path.join(MET, rid, "frame_metrics.csv"),
                     usecols=["I_circ", "h_over_a"])
    sm = fm.I_circ.rolling(151, center=True, min_periods=50).mean()
    hh = fm.h_over_a.rolling(151, center=True, min_periods=50).mean()
    sgn = bs.loc[bs.run_id == rid, "branch_sign"].iloc[0]
    c = POS if sgn > 0 else NEG
    ax.plot(hh, fm.I_circ, color=c, lw=0.5, alpha=0.16)
    ax.plot(hh, sm, color=c, lw=2.6,
            label=f"{rid}" + ("  (flipped)" if rid == "R0008" else ""))
ax.set_xlim(0.55, 1.82); ax.set_ylim(-0.014, 0.014)
ax.set_xlabel("relative submergence  $h/a$")
ax.set_ylabel("$I_{\\mathrm{circ}}(t)$  (signed)")
ax.legend(loc="lower left", ncol=2, framealpha=0.95)
save(fig, "icirc_traces_medium.png")

# ------------------------------------------------------------- A2 sign matrix
days = sorted(set(date_of[r] for r in bs.run_id))
levels = ["low", "medium", "high"]
fig, ax = plt.subplots(figsize=(8.6, 5.2))
for _, r in bs.iterrows():
    ix = levels.index(level_of[r.run_id]); iy = days.index(date_of[r.run_id])
    c = POS if r.branch_sign > 0 else NEG
    ax.scatter(ix, iy, s=3600, marker="o", c=c, zorder=3)
    ax.text(ix, iy, f"{r.R_lock:.1f}", color="w", ha="center", va="center",
            fontsize=15, fontweight="bold", zorder=4)
ax.set_xticks(range(3), ["low\n0.25 L/s", "medium\n0.50 L/s", "high\n0.75 L/s"])
ax.set_yticks(range(len(days)), [f"day {i+1}\n{d[4:6]}/{d[6:]}" for i, d in enumerate(days)])
ax.set_xlim(-0.55, 2.55); ax.set_ylim(len(days) - 0.45, -0.55)
ax.set_frame_on(False); ax.tick_params(length=0)
h1 = ax.scatter([], [], s=160, marker="o", c=POS, label="counterclockwise ($I_{\\mathrm{circ}}>0$)")
h2 = ax.scatter([], [], s=160, marker="o", c=NEG, label="clockwise ($I_{\\mathrm{circ}}<0$)")
ax.legend(handles=[h1, h2], loc="upper center", bbox_to_anchor=(0.5, -0.08),
          ncol=2, frameon=False, fontsize=14)
ax.set_title("branch sign per run   (number = lock strength $R_{\\mathrm{lock}}$)",
             color=KUBLUE, pad=14)
save(fig, "sign_matrix.png")

# ------------------------------------------------------------ A3 lock vs Q
fig, ax = plt.subplots(figsize=(8.8, 5.4))
for _, r in bs.iterrows():
    lv = level_of[r.run_id]
    c = POS if r.branch_sign > 0 else NEG
    ax.scatter(r.Q_transit_Lps, r.R_lock, s=170, marker=LEVELM[lv], c=c, zorder=3)
med = bs.assign(level=[level_of[r] for r in bs.run_id]).groupby("level")
for lv in levels:
    g = med.get_group(lv)
    ax.scatter(g.Q_transit_Lps.median(), g.R_lock.median(), s=650, marker=LEVELM[lv],
               facecolor="none", edgecolor=INK, lw=2.0, zorder=4)
for rid, dx, dy in [("R0002", 0.025, -0.25), ("R0007", 0.025, -0.25), ("R0008", -0.115, 0.45)]:
    r = bs[bs.run_id == rid].iloc[0]
    ax.annotate(rid, (r.Q_transit_Lps, r.R_lock), xytext=(r.Q_transit_Lps + dx, r.R_lock + dy),
                fontsize=14, color="0.25")
ax.scatter([], [], s=300, marker="s", facecolor="none", edgecolor=INK, lw=2.0,
           label="level median")
ax.legend(loc="lower right", frameon=False, fontsize=14)
ax.set_xlabel("measured discharge $Q$ over $B_3$+$B_4$  [L/s]")
ax.set_ylabel("lock strength  $R_{\\mathrm{lock}}$")
ax.set_xlim(0.22, 0.92); ax.set_ylim(0, 14.5)
ax.text(0.29, 13.6, "level medians: 3.6 $\\to$ 8.7 $\\to$ 11.8", fontsize=15, color=KUBLUE)
ax.grid(alpha=0.25)
save(fig, "lock_vs_q.png")

# ------------------------------------------------------- A4 metrics vs h/a
inf = bm[bm["mode"] == "inflow"]
panels = [("E_mean", "$E$  [m$^2$/s$^2$]", "log"),
          ("phi_lv_mean", "$\\phi_{\\mathrm{lv}}$  (fraction below $0.2\\,U_p$)", "linear"),
          ("I_unst", "$I_{\\mathrm{unst}}$  (std/mean of $E$ in band)", "linear")]
fig, axes = plt.subplots(1, 3, figsize=(15.6, 4.6))
for ax, (col, lab, sc) in zip(axes, panels):
    for lv in levels:
        g = inf[inf.flow_level == lv].groupby("band_id")
        ha = g.h_over_a_mid.mean(); mu = g[col].mean(); sd = g[col].std()
        ax.errorbar(ha, mu, sd, marker=LEVELM[lv], ms=7, lw=1.8, capsize=3,
                    color=LEVELC[lv], label=lv)
    ax.axvline(1.0, ls=":", color="0.45")
    ax.set_yscale(sc); ax.set_xlabel("$h/a$"); ax.set_title(lab, fontsize=17)
    ax.grid(alpha=0.25)
axes[0].legend()
fig.tight_layout()
save(fig, "inflow_metrics_ha.png")

# --------------------------------------------------- A4b I_unst standalone
fig, ax = plt.subplots(figsize=(7.8, 4.6))
for lv in levels:
    g = inf[inf.flow_level == lv].groupby("band_id")
    ax.errorbar(g.h_over_a_mid.mean(), g.I_unst.mean(), g.I_unst.std(),
                marker=LEVELM[lv], ms=8, lw=2.0, capsize=3, color=LEVELC[lv], label=lv)
ax.axvline(1.0, ls=":", color="0.45")
ax.annotate("factor ~10 drop,\nsame position at\nall three levels",
            xy=(1.0, 0.20), xytext=(1.24, 0.16), fontsize=15, color="0.25",
            arrowprops=dict(arrowstyle="->", color="0.45"))
ax.set_xlabel("$h/a$"); ax.set_ylabel("$I_{\\mathrm{unst}}$  (std/mean of $E$ in band)")
ax.legend()
ax.grid(alpha=0.25)
save(fig, "iunst_ha.png")

# ------------------------------------------------------------ A5 q(h) profile
# The logged q_actual column is quantized (1-mm logger / 20-s window -> discrete
# levels 0.289/0.579/0.868 L/s), so any per-frame view is a comb. Instead use
# the transit-time method at 2-mm granularity: Q_i = A(h) dh / dt_i, where dt_i
# is the time the run took to sweep each 2-mm depth slab.
A_EXP = 2.952 * 1.962
A_CH  = 0.6 * 0.11          # guide-channel plan footprint below its roof (h < a)
fig, ax = plt.subplots(figsize=(11.2, 5.0))
for rid in bs.run_id:
    fm = pd.read_csv(os.path.join(MET, rid, "frame_metrics.csv"),
                     usecols=["time_s", "depth_m"]).dropna().sort_values("time_s")
    h_mm = fm.depth_m.to_numpy() * 1000
    t = fm.time_s.to_numpy()
    edges = np.arange(32, 99, 4.0)
    tc = np.interp(edges, h_mm, t)          # first-crossing times (h monotone up)
    hmid = 0.5 * (edges[:-1] + edges[1:])
    area = np.where(hmid < 55.0, A_EXP + A_CH, A_EXP)
    q = area * 0.004 / np.diff(tc) * 1000   # L/s per 4-mm slab
    ok = np.diff(tc) > 1.0                   # slab actually swept
    lv = level_of[rid]
    ax.plot(hmid[ok], q[ok], color=LEVELC[lv], lw=1.7, alpha=0.9)
for lv, qn in [("low", 0.25), ("medium", 0.50), ("high", 0.75)]:
    ax.axhline(qn, color=LEVELC[lv], ls=(0, (1, 3)), lw=1.2)
    ax.text(33.5, qn + 0.015, f"nominal {lv}", color=LEVELC[lv], fontsize=13)
ax.axvline(55, ls=":", color="0.35")
ax.text(95.5, 0.06, "$h = a$: port submerges AND supply channel\npressurizes -- same instant, by apparatus design",
        fontsize=13.5, color="0.25", va="bottom", ha="right")
ax.set_xlim(33, 97); ax.set_ylim(0, 1.05)
ax.set_xlabel("water depth  $h$  [mm]")
ax.set_ylabel("effective discharge  [L/s]")
ax.set_title("inflow, 12 runs: the delivered discharge varies within a run  (transit-time, 4-mm slabs)",
             color=KUBLUE, fontsize=17)
save(fig, "qh_profile.png")
# ------------------------------------------------------------ A6 E mode bars
fig, ax = plt.subplots(figsize=(7.6, 4.8))
x = np.arange(3); w = 0.36
Ein  = [bm[(bm["mode"] == "inflow") & (bm.flow_level == l)].E_mean.mean() for l in levels]
Eout = [bm[(bm["mode"] == "outflow") & (bm.flow_level == l)].E_mean.mean() for l in levels]
ax.bar(x - w/2, Ein,  w, color=KUBLUE, label="inflow")
ax.bar(x + w/2, Eout, w, color="#9FB4D6", label="outflow")
for xi, (ei, eo) in zip(x, zip(Ein, Eout)):
    ax.text(xi + w/2, eo * 1.4, f"1/{ei/eo:,.0f}", ha="center", fontsize=14, color="0.25")
ax.set_yscale("log"); ax.set_ylim(1e-7, 5e-3)
ax.set_xticks(x, levels)
ax.set_ylabel("$E$  (band mean)  [m$^2$/s$^2$]")
ax.legend()
ax.grid(alpha=0.25, axis="y")
save(fig, "E_mode_bars.png")

# ------------------------------------------------------------ equations
def eq(tex, fname, fs=40, color=INK):
    f = plt.figure(figsize=(0.1, 0.1))
    f.text(0, 0, tex, fontsize=fs, color=color)
    f.savefig(os.path.join(OUT, fname), dpi=400, transparent=True,
              bbox_inches="tight", pad_inches=0.06)
    plt.close(f)
    print("eq", fname)

eq(r"$E(t)=\left\langle |\mathbf{u}|^{2}\right\rangle _{\Omega}\qquad"
   r"\phi_{\mathrm{lv}}(t)=\frac{\mathrm{Area}(|\mathbf{u}|<0.2\,U_p)}{\mathrm{Area}(\Omega)}\qquad"
   r"I_{\mathrm{asym}}(t)=\frac{|E_L-E_R|}{E_L+E_R}$", "eq_basic.png", 30)
eq(r"$I_{\mathrm{circ}}(t)=\frac{a}{U_p}\left\langle \omega\right\rangle_{\Omega}"
   r"\qquad I_{\mathrm{rot}}(t)=\frac{a}{U_p}\left\langle |\omega|\right\rangle_{\Omega}"
   r"\qquad \omega=\partial_x v-\partial_y u$", "eq_circ.png", 32)
eq(r"$R_{\mathrm{lock}}=\frac{\left|\,\mathrm{mean}\,I_{\mathrm{circ}}\,\right|}"
   r"{\mathrm{std}\,I_{\mathrm{circ}}}\;\;\mathrm{over}\;B_3{+}B_4$", "eq_rlock.png", 34, KUBLUE)
eq(r"$I_{\mathrm{unst}}(B_k)=\frac{\mathrm{std}\{E\,|\,h\in B_k\}}{\mathrm{mean}\{E\,|\,h\in B_k\}}$",
   "eq_iunst.png", 32)
print("done")

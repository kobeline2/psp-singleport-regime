#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_deck.py -- informal progress deck for the paper-1 (experiment) results,
built on the Kyoto-University-style template (deck.py in the Dropbox folder).

Audience: collaborators who know the rig and the campaign, but have not yet
seen the metrics, the branch-selection result, or the discussion. English.
Photo slots the presenter should fill are figure_box placeholders.

Build:  python3 build_deck.py           -> paper1_progress.pptx (this folder)
Assets: python3 gen_assets.py           (needs local/derived/metrics on disk)
"""
import os, sys

TEMPLATE = "/Users/takahiro/Library/CloudStorage/Dropbox/agent/PPTテンプレート"
sys.path.insert(0, TEMPLATE)
from deck import *   # noqa: F401,F403
from deck import EMW, CW, ML  # explicit for layout math

HERE = os.path.dirname(os.path.abspath(__file__))
def AP(n): return os.path.join(HERE, "assets", n)

prs = new_presentation()
PG = 0
def pg():
    global PG; PG += 1; return PG

# ============================================================ 1 cover
pg()
cover(prs, "Surface-flow regimes in a shallow\nsingle-port reservoir model",
      subtitle="Experiment results and discussion -- a preview of Paper 1",
      tag="Pumped-storage upper reservoir project | informal progress share",
      name="Takahiro Koshiba", date="August 2026")

# ============================================================ 2 one slide
s = content(prs, "Today in one slide", page=pg(),
            message="Three findings from the 24-run campaign; the middle one is new and is the headline.")
b = [
    ("Inflow", ["Jet deflects to one wall and drives a basin-scale circulation, at every depth.",
                "Depth modulates intensity, not the pattern."]),
    ("NEW  Flow rate picks the direction", ["Low: counterclockwise, 4/4 runs.",
                "High: clockwise, 4/4. Medium: bistable, 3/1.",
                "The sign splits within every day."]),
    ("Outflow", ["A symmetric converging sink, ~1000x weaker at the surface; no rotation.",
                 "Weak mean, largest relative fluctuation."]),
]
for i, (h, body) in enumerate(b):
    block(s, ML + i * 4.13, 2.15, 3.95, 3.3, h, body, hsize=19, bsize=16)
takeaway(s, "One rig, one port: the flow rate decides which way the basin turns.")
notes(s, "30-second version of the talk. Everything else is evidence for these three boxes.")

# ============================================================ 3 chapter 1
chapter(prs, "1", "Setup recap and the measurement",
        subtitle="What you have seen before, now with the numbers pinned down",
        bridge="(skip fast -- the new material starts in Section 2)")

# ============================================================ 4 facility
s = content(prs, "Facility and campaign", page=pg(),
            message="Same rig as before: shallow rectangular basin, one reversible port on the short wall.")
figure_box(s, ML, 2.05, 5.6, 3.9, "PHOTO PLACEHOLDER\nbasin overview + port close-up")
block(s, 6.5, 2.05, 6.2, 1.85, "Geometry (measured)",
      ["Basin 2.952 x 1.962 m, depth range 0.03-0.10 m",
       "Port 0.11 m wide x 0.055 m high, at mid short wall",
       "Port bottom flush with the floor;  a = 0.055 m"], hsize=18, bsize=15)
block(s, 6.5, 4.05, 6.2, 1.9, "Campaign (24 runs, all from still water)",
      ["2 modes (inflow / outflow) x 3 flow levels x 4 reps",
       "Nominal 0.25 / 0.50 / 0.75 L/s (valve-set)",
       "Inflow reps blocked by day: each of 4 days ran",
       "low + medium + high  ->  day vs flow separable"], hsize=18, bsize=15)
notes(s, "Block design matters later: it is what lets us attribute the sign to flow rate.")

# ============================================================ 5 depth axis
s = content(prs, "Depth is swept within each run", page=pg(),
            message="Depth is an axis every run traverses; we analyze in four depth bands.")
rows = [
    ("B1  30-50 mm",  "h/a = 0.55-0.91   shallow, port partly open to the surface"),
    ("B2  50-60 mm",  "h/a = 0.91-1.09   transition around full submergence"),
    ("B3  60-75 mm",  "h/a = 1.09-1.36   moderately submerged"),
    ("B4  75-100 mm", "h/a = 1.36-1.82   clearly submerged, quasi-steady"),
]
glossary(s, ML, 2.1, CW, rows, term_w=3.3, headers=("Band", "Range and meaning"), row_h=0.62)
bullets(s, ML, 5.05, CW, 1.0, [
    "Inflow fills 30 -> 100 mm, outflow drains 100 -> 30 mm; every PIV frame gets a depth tag from the level logger.",
    "The controlling ratio is h/a (depth over port height). B3+B4 is the quasi-steady window used for statistics."],
    size=16, gap=8)
takeaway(s, "Everything that follows is plotted against h/a; the port ceiling h/a = 1 is the landmark.")

# ============================================================ 6 discharge honesty
s = content(prs, "The delivered discharge varies within a run", page=pg(),
            message="The valve fixes the label, not the discharge -- so we quote measured, band-wise Q.")
place_fit(s, AP("qh_profile.png"), ML, 1.95, 12.09, 4.1)
bullets(s, ML, 6.05, CW, 0.8, [
    "Dip to roughly 25-30% of nominal just below h = a, then recovery; high runs overshoot nominal at depth.",
    "Note for later: at h = a the port submerges AND the supply channel pressurizes -- same instant, by design."],
    size=15, gap=6)
notes(s, "This is why all quantitative claims use the transit-time discharge over stated bands, "
         "not the nominal value. The h=a coincidence returns on the unsteadiness slide.")

# ============================================================ 7 pipeline
s = content(prs, "From movies to numbers: three layers", page=pg(),
            message="One fixed pipeline; settings identical for all 24 runs except the pair interval.")
block(s, ML, 2.2, 3.6, 1.75, "1  Surface velocity field",
      ["u(x, y, t) from surface PIV", "92 x 61 vectors, 31.5 mm grid"], hsize=17, bsize=15)
arrow(s, 4.32, 3.08, 4.68, 3.08)
block(s, 4.72, 2.2, 3.6, 1.75, "2  Frame scalars",
      ["E, phi_lv, I_asym,", "I_circ, I_rot  per frame"], hsize=17, bsize=15)
arrow(s, 8.42, 3.08, 8.78, 3.08)
block(s, 8.82, 2.2, 3.28, 1.75, "3  Band statistics",
      ["mean, std, SNR, I_unst", "per run x band"], hsize=17, bsize=15)
code_block(s, ML, 4.25, 12.09, 2.15,
           "camera 29.97 Hz, rectified to 1501 x 1001 px (1.97 mm/px, full basin)\n"
           "PIV     multi-pass 128 > 64 > 32 px, 50% overlap, 6-sigma + median filters\n"
           "dt      inflow 0.200 / 0.100 / 0.067 s (displacement matched across levels)\n"
           "        outflow 0.334 s everywhere  <- too short, revisited on the outflow slides",
           title="Settings actually used (identical for all 24 runs except dt)", size=14)
notes(s, "Tool-agnostic after import: PIVLab output is normalized to a canonical struct, "
         "so the metric layer never sees the tool.")

# ============================================================ 8 metrics
s = content(prs, "Five primary metrics", page=pg(),
            message="Chosen once during the pilot, then frozen; all are area means over the full vector grid.")
rows = [
    ("E",       "how much the surface moves -- mean of |u|^2  [m2/s2]"),
    ("phi_lv",  "how much of it is dead -- area fraction below 0.2 Up"),
    ("I_asym",  "left-right imbalance of energy (unsigned magnitude)"),
    ("I_circ",  "net rotation, SIGNED -- which way the basin turns"),
    ("I_rot",   "rotation activity, unsigned -- how much turning exists"),
    ("I_unst",  "band-wise variability -- std/mean of E while in a band"),
]
glossary(s, ML, 2.0, CW, rows, term_w=2.2, headers=("Metric", "What it measures"), row_h=0.56)
eq_center(s, AP("eq_basic.png"), 5.85, 9.6)
notes(s, "Up = Q/(a b) is the port mean velocity; it makes thresholds and vorticity flow-rate-free.")

# ============================================================ 9 icirc vs irot
s = content(prs, "Two ways to be zero: I_circ vs I_rot", page=pg(),
            message="The signed and unsigned rotation metrics answer different questions -- we need both.")
eq_center(s, AP("eq_circ.png"), 1.95, 10.6)
block(s, ML, 3.15, 5.9, 1.95, "I_circ ~ 0, I_rot large",
      ["Strong counter-rotating cells that cancel", "in the signed mean.  This is inflow."], hsize=18, bsize=16)
block(s, 6.8, 3.15, 5.9, 1.95, "I_circ ~ 0, I_rot small",
      ["No rotation to begin with.", "This is outflow."], hsize=18, bsize=16)
block(s, ML, 5.25, 12.09, 0.85, None,
      ["Rule we enforce: the SIGN of I_circ is a per-run outcome. Never average signed I_circ across repetitions --"
       " opposite-branch runs cancel to zero and erase the result."], bsize=15, fill=PALE)
takeaway(s, "Read the pair (I_circ, I_rot); the signed one carries the branch information.")

# ============================================================ 10 noise floor
s = content(prs, "Noise-floor discipline", page=pg(),
            message="Every scalar is reported against the measured noise floor of the PIV.")
block(s, ML, 2.1, 5.9, 2.1, "Measured floor",
      ["E_noise ~ 2e-7 m2/s2", "= 0.06 px displacement per image pair",
       "Band is 'resolved' only if SNR = E/E_noise >= 3"], hsize=18, bsize=15)
block(s, 6.8, 2.1, 5.9, 2.1, "Where the data stand",
      ["Inflow: SNR > 400 in every band  -- fully resolved",
       "Outflow high: resolved at B1 (SNR ~ 37) and B4 (~6)",
       "Outflow low/medium: below or near floor everywhere"], hsize=18, bsize=15)
bullets(s, ML, 4.5, CW, 1.4, [
    "Time-mean vector fields survive below the floor (random error averages down by 1/sqrt(N) over ~1000 frames per band).",
    "So for weak outflow: trust the mean maps, treat the scalars as qualitative."], size=16, gap=8)
takeaway(s, "One honest rule, applied everywhere -- it will matter for outflow.")

# ============================================================ 11 chapter 2
chapter(prs, "2", "Inflow: one regime, modulated by depth",
        subtitle="Deflected jet + basin-scale circulation, at every depth band")

# ============================================================ 12 inflow fields
s = content(prs, "The same structure at every depth", page=pg(),
            message="Band-mean surface velocity, one representative low-flow run; port at the left wall center.")
place_fit(s, AP("R0001_band_mean_field.png"), ML, 2.0, 12.09, 2.15)
bullets(s, ML, 4.45, CW, 1.5, [
    "The jet does not go straight: it attaches to one side wall, accelerates along it, and drives one basin-scale circulation.",
    "The opposite side holds a broad, slow recirculation.",
    "Topology is identical in B1-B4 -- submergence changes the intensity, not the pattern."], size=16, gap=8)
takeaway(s, "One regime across the whole depth range: deflected jet + asymmetric circulation.")

# ============================================================ 13 metrics vs h/a
s = content(prs, "Depth modulates intensity, not topology", page=pg(),
            message="Band statistics over the 12 inflow runs (mean +/- sd over the 4 repetitions).")
place_fit(s, AP("inflow_metrics_ha.png"), ML, 2.0, 12.09, 3.65)
bullets(s, ML, 5.85, CW, 1.0, [
    "E drops 2.6-4.4x from B1 to B4: the jet's momentum reaches the surface less and less.",
    "The dead-water fraction phi_lv grows to ~half of the basin; I_asym stays flat at ~0.26 throughout."],
    size=15, gap=6)

# ============================================================ 14 h/a switch
s = content(prs, "h/a ~ 1 is an unsteadiness switch", page=pg(),
            message="The clearest depth transition is not in the pattern but in the fluctuation level.")
place_fit(s, AP("iunst_ha.png"), ML, 2.0, 6.1, 3.9)
block(s, 7.0, 2.0, 5.7, 1.95, "What switches",
      ["h < a: exposed jet wanders -- I_unst 0.35-0.40",
       "h > a: submerged jet, calm surface -- 0.03-0.05",
       "Same switch position at all three flow levels"], hsize=17, bsize=15)
block(s, 7.0, 4.15, 5.7, 1.9, "One honest caveat",
      ["At h = a the port submerges and the supply",
       "channel pressurizes at the same instant (channel",
       "roof = a by design). This rig cannot separate the",
       "two mechanisms -- stated as such in the paper."], hsize=17, bsize=14)
takeaway(s, "Keep water above the port ceiling and the inflow surface is steady; near it, it is not.")

# ============================================================ 15 chapter 3
chapter(prs, "3", "The headline: flow rate selects the branch",
        subtitle="Which way the basin turns is not noise -- it is set by the discharge",
        bridge="(this is the part that was not in any earlier report)")

# ============================================================ 16 mirror pair
s = content(prs, "Same condition, opposite branch", page=pg(),
            message="Two medium repetitions, identical settings, four days apart -- mirror-image circulations.")
place_fit(s, AP("R0006_band_mean_field.png"), ML, 1.95, 12.09, 1.95)
place_fit(s, AP("R0008_band_mean_field.png"), ML, 4.05, 12.09, 1.95)
textbox(s, 12.05, 2.0, 0.6, 1.7, [{"t": "CW", "s": 16, "b": True, "c": KUBLUE}])
textbox(s, 11.95, 4.1, 0.75, 1.7, [{"t": "CCW", "s": 16, "b": True, "c": KUBLUE}])
takeaway(s, "Two mirror states, both realized: a symmetry-breaking pair, not scatter.")
notes(s, "Top: R0006 (clockwise). Bottom: R0008 (counterclockwise). 'CW/CCW' refer to the plotted frame.")

# ============================================================ 17 traces
s = content(prs, "Locked traces -- one of them flipped", page=pg(),
            message="Signed I_circ through the fill, all four medium repetitions (thin: raw; bold: smoothed).")
place_fit(s, AP("icirc_traces_medium.png"), ML, 1.95, 12.09, 4.05)
bullets(s, ML, 6.1, CW, 0.75, [
    "Each run settles onto one sign as the jet submerges and never leaves it: in 10 of 12 inflow runs the deep-band sign persistence is 1.000.",
    ], size=15, gap=6)

# ============================================================ 18 sign matrix
s = content(prs, "The sign, day by day", page=pg(),
            message="Every experiment day ran low, medium and high -- and the sign splits inside each day.")
place_fit(s, AP("sign_matrix.png"), ML, 1.95, 6.4, 4.15)
bullets(s, 7.5, 2.3, 5.2, 3.6, [
    "low: counterclockwise in 4 of 4 runs",
    "high: clockwise in 4 of 4 runs",
    "medium: 3 CW / 1 CCW -- the fence-sitter",
    {"t": "same day, same rig, same water -- only the valve differs between columns", "sub": True},
    "so the selector is the flow rate, not the day, not the setup",
    ], size=17, gap=12)
takeaway(s, "Deterministic at low and high; the preferred direction REVERSES between them.")

# ============================================================ 19 medium fence
s = content(prs, "Medium sits on the fence -- genuine bistability", page=pg(),
            message="The flipped run is not a discharge outlier: both branches occur at the same Q.")
block(s, ML, 2.15, 5.9, 2.3, "The flipped run, R0008",
      ["Deep-band discharge (transit-time):",
       "R0008 = 0.492 L/s vs R0007 = 0.485 L/s -> 1.4%",
       "(B4 alone: 0.2%). Within the medium spread",
       "0.485-0.519 L/s across the four repetitions."], hsize=18, bsize=15)
block(s, 6.8, 2.15, 5.9, 2.3, "The weak run, R0007",
      ["Same sign as the majority but barely locked:",
       "R_lock = 1.9 (vs 7.5-10.3 for the others),",
       "sign persistence 0.970 -- occasional excursions",
       "toward zero. The fence is real on both sides."], hsize=18, bsize=15)
bullets(s, ML, 4.85, CW, 1.1, [
    "Same condition, two outcomes: that is a bistable transition band, not measurement scatter.",
    "Low (all CCW) and high (all CW) sit safely on either side of it."], size=16, gap=8)
takeaway(s, "Medium is where the two branches compete -- exactly where a transition band should sit.")

# ============================================================ 20 lock strength
s = content(prs, "How firmly the branch is held grows with discharge", page=pg(),
            message="Lock strength: mean net circulation over its own fluctuation, per run (deep bands).")
place_fit(s, AP("lock_vs_q.png"), ML, 1.95, 7.3, 4.5)
place_fit(s, AP("eq_rlock.png"), 8.3, 2.2, 4.2, 1.1)
block(s, 8.0, 3.6, 4.7, 2.5, "Reading",
      ["Level medians 3.6 -> 8.7 -> 11.8:",
       "monotonic in discharge.",
       "The two weak points are the fence",
       "(R0007) and one marginal low run",
       "(R0002, persistence 0.83)."], hsize=17, bsize=15)
takeaway(s, "Flow rate controls both WHICH branch is taken and HOW FIRMLY it is held.")

# ============================================================ 21 interpretation
s = content(prs, "Reading it as symmetry breaking", page=pg(),
            message="A deliberately careful reading: the data constrain the story, not close it.")
block(s, ML, 2.05, 12.09, 1.2, "Mirror pair = broken symmetry",
      ["The geometry is left-right symmetric, so the two circulations are twin solutions; shallow-basin work "
       "treats wall attachment as a symmetry-breaking bifurcation (Dewals 2008; Mullin 2003)."], hsize=17, bsize=14)
block(s, ML, 3.4, 12.09, 1.35, "A fixed imperfection cannot explain a REVERSING preference",
      ["One geometric defect would always pick the same side. Ours reverses between low and high -- so at least two",
       "competing biases with different flow-rate dependence must be present (e.g. supply-line bias vs jet-momentum bias).",
       "Identifying them needs deliberate asymmetry experiments -- future work, stated as such."], hsize=17, bsize=14)
block(s, ML, 4.9, 12.09, 1.2, "Firmer lock at higher flow fits stability theory",
      ["More flow means bottom friction matters relatively less (higher effective Re, cf. Chen & Jirka 1997):",
       "the system sits farther above the symmetry-breaking threshold, so the chosen branch is held harder."], hsize=17, bsize=14)
source(s, "Dewals et al. 2008; Chen & Jirka 1997; Mullin et al. 2003")
notes(s, "Keep this slide modest: selection mechanism is NOT identified; only its flow-rate dependence is established.")

# ============================================================ 22 chapter 4
chapter(prs, "4", "Outflow: the other half of the cycle",
        subtitle="Weak, symmetric, restless -- and partly below the current noise floor")

# ============================================================ 23 outflow fields
s = content(prs, "A converging sink, three orders weaker", page=pg(),
            message="Band-mean fields, high-flow outflow run; note the color scales vs the inflow slides.")
place_fit(s, AP("R0021_band_mean_field.png"), ML, 2.0, 12.09, 2.15)
bullets(s, ML, 4.4, CW, 1.5, [
    "All vectors point at the port: a near-symmetric converging sink. No deflection, no attached wall jet, no rotation.",
    "I_rot = 0.002-0.007, about 1/20 of inflow; I_asym ~ 0.08 vs 0.26 -- and E is ~1/1000 of inflow at equal discharge.",
    "So the branch-selection question simply does not arise here: there is nothing rotating to choose a side."],
    size=16, gap=8)
takeaway(s, "Same port, opposite role: injection makes a jet; withdrawal makes a sink.")

# ============================================================ 24 surface immunity
s = content(prs, "The surface barely feels the withdrawal", page=pg(),
            message="This is geometry, not an instrument limit: the free surface is ~1000 port areas wide.")
place_fit(s, AP("E_mode_bars.png"), ML, 2.0, 5.6, 4.0)
block(s, 6.5, 2.0, 6.2, 1.9, "Saturated dead water",
      ["phi_lv = 1.000 in every outflow band:",
       "the whole surface is below 0.2 Up.",
       "Band-mean speeds: 0.35-2.2% of Up."], hsize=18, bsize=15)
block(s, 6.5, 4.1, 6.2, 1.9, "Continuity does the arithmetic",
      ["A_plan / (a b) ~ 1e3, so a sink of Up at the",
       "port dilutes to ~1e-3 Up at the surface --",
       "matching what we measure."], hsize=18, bsize=15)
takeaway(s, "In a shallow basin, outflow is geometrically guaranteed to leave the surface almost still.")

# ============================================================ 25 outflow unsteadiness
s = content(prs, "Weak but restless -- and partly below our floor", page=pg(),
            message="Where we can resolve it, outflow fluctuates twice as hard (relatively) as inflow ever does.")
place_fit(s, AP("R0013_band_mean_field.png"), ML, 2.0, 12.09, 1.95)
bullets(s, ML, 4.25, CW, 1.75, [
    "Low-flow outflow (above): B2-B4 show no coherent mean structure -- these bands sit at the noise floor.",
    "The one well-resolved band (high flow, B1): I_unst = 0.76, twice the inflow maximum -- weak mean, large relative fluctuation (consistent with Zhu et al. 2023 near intakes).",
    "Root cause of the floor problem is our dt = 0.33 s: particle displacements 0.05-0.16 px. Fix already planned: re-export the SAME videos at dt ~ 2-7 s and re-run PIV -- no new experiments needed.",
    ], size=15, gap=8)
takeaway(s, "Outflow unsteadiness is real but under-resolved -- the re-analysis will recover it before submission.")

# ============================================================ 26 history
s = content(prs, "History matters (to be tested properly)", page=pg(),
            message="The old continuous-operation observation and this batch disagree -- informatively.")
figure_box(s, ML, 2.05, 5.6, 3.9, "PLACEHOLDER (optional)\ncontinuous-run sketch or photo")
block(s, 6.5, 2.05, 6.2, 1.85, "What we saw before",
      ["In inflow -> outflow continuous operation, the",
       "outflow surface kept a basin-wide circulation."], hsize=18, bsize=15)
block(s, 6.5, 4.1, 6.2, 1.85, "What the still-start batch says",
      ["From rest, outflow is a rotation-free sink -- so the",
       "old circulation was inherited from the preceding",
       "inflow (cf. Muller 2012: cells persist ~0.2-0.8 t_P).",
       "Still-start = the clean baseline; history runs are next."], hsize=18, bsize=14)
takeaway(s, "In alternating operation the outflow surface is set by the previous inflow -- a paper-2-era experiment.")

# ============================================================ 27 summary
summary(prs, "What Paper 1 will claim", [
    "Inflow and outflow through one reversible port are decisively asymmetric: deflected jet + circulation vs a ~1000x weaker symmetric sink.",
    "h/a ~ 1 is a transition of unsteadiness and surface reach, not of topology (with the stated apparatus caveat at h = a).",
    "Flow rate selects the circulation branch -- deterministically at low and high (opposite signs!), bistably at medium -- and firms the lock as Q grows.",
    "Method lesson: signed + unsigned rotation metrics together, per-run branch statistics, and an explicit noise floor.",
], page=pg())

# ============================================================ 28 roadmap
s = content(prs, "Where this sits in the three-paper plan", page=pg(),
            message="Paper 1 is written to stand on the experiment alone.")
block(s, ML, 2.1, 3.95, 2.9, "Paper 1 -- this talk",
      ["Experiment only, no CFD", "inside. Target: submit after",
       "the outflow re-analysis and", "final figure pass."], hsize=17, bsize=15)
block(s, 4.7, 2.1, 3.95, 2.9, "Paper 2 -- 3D CFD",
      ["OpenFOAM VOF campaign", "running in parallel;",
       "quantifies what 3D CFD can", "and cannot reproduce of", "these regimes."], hsize=17, bsize=15)
block(s, 8.77, 2.1, 3.95, 2.9, "Paper 3 -- 2D x 3D",
      ["Joint comparison with your", "HEC-RAS 2D results --",
       "model hierarchy on one", "bifurcation axis. Builds on", "papers 1 + 2."], hsize=17, bsize=15)
bullets(s, ML, 5.3, CW, 1.0, [
    "Open items before submitting Paper 1: outflow re-PIV (longer dt), tracer specs for Methods, two intro references.",
    "Nothing in today's results depends on the CFD -- by design."], size=15, gap=6)
takeaway(s, "Comments most welcome on the branch-selection story -- it is the paper's centerpiece.")

# ============================================================ 29 closing (custom, English)
s = slide(prs, KUBLUE)
textbox(s, 0.9, 2.6, 11.5, 0.7, [{"t": "Discussion", "s": 40, "b": True, "c": WHITE}])
rect(s, 0.95, 3.55, 2.4, 0.06, fill=ICE)
textbox(s, 0.9, 3.85, 11.5, 1.2, [
    {"t": "Especially: does the reversing branch preference survive your scrutiny?", "s": 22, "c": ICE},
    {"t": "Data, scripts and the manuscript draft live in the shared repository.", "s": 18, "c": ICE, "space_before": 10},
])
furniture(s, page=pg(), on_dark=True)

save(prs, os.path.join(HERE, "paper1_progress.pptx"))

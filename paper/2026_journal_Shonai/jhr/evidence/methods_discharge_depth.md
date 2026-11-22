# Evidence sheet -- Methods 2.3 "Discharge and water depth"

Prepared 2026-11-22 for the JHR manuscript (paper 1). Evidence only; no manuscript text.

- Paths are relative to the repository root. `local/` is the gitignored, machine-local data root
  (this Mac); files under it are not in Git and may differ on the lab workstation (WS).
- Line numbers refer to the working tree on 2026-11-22. `doc/settled_and_retracted.md` and
  `cfd/campaign.md` had uncommitted edits at that time, so their line numbers can shift.
- `cfd/campaign.md` is cited only for experimental facts recorded there (gauge, procedure, user
  confirmations). No CFD result is carried into this sheet.
- "old manuscript" = `paper/2026_journal_Shonai/sections/*.tex` (frozen source material, may be stale).
- Status vocabulary: **settled** (recorded as settled in the authoritative file), **user-confirmed**
  (decided or confirmed by the user), **computed** (output of a repo script, or arithmetic done in
  this task on an existing CSV -- the row says which), **unverified** (recorded but not checked,
  non-authoritative, or contradicted elsewhere), **GAP** (not recorded; leave a `\PH{...}`).
- Rows marked "arithmetic in this task" were obtained with one-off python on the CSV named in the
  row. They are cross-checks of recorded numbers, not new results, and are not reproducible from a
  repo tool. Quote the recorded value, not the cross-check.

**Read this first.** All band-wise numbers that exist as files today (`frame_metrics.csv`,
`band_metrics.csv`, `branch_stats.csv`) are on the **gauge** depth axis. The time-proportional axis,
which the user made primary on 2026-11-22, is not implemented in `s31`. Band values are therefore
not final on the primary axis (section 7).

## 1. Verdict and the quoted discharge

| fact | value | source (file:line) | status (settled / user-confirmed / computed / unverified / GAP) |
|---|---|---|---|
| Verdict | Discharge is nearly constant ("ほぼ一定") within each run; there is no ramp during a run | `doc/settled_and_retracted.md:16`; `doc/qdip_jet_check.md:3`, `:10-13` | settled (2026-10-26) |
| What the depth dependence of the level-derived discharge is | An artefact of the upper-basin water-level gauge reading, not a change of the real discharge | `doc/qdip_jet_check.md:12-13`; `doc/settled_and_retracted.md:41` | settled (but see section 9, conflict C11) |
| Number of grounds | Three, described as mutually independent: (1) PIV jet surface speed, (2) lower-reservoir level, (3) behaviour of the gauge reading | `doc/qdip_jet_check.md:13-26`; `doc/settled_and_retracted.md:41` | settled |
| Supplementary observation | Discharge ratios between flow levels are preserved at every depth: high/low 2.8-3.4, medium/low 1.8-2.3 (each band and the dip interval, inflow and outflow) | `doc/qdip_jet_check.md:28` | settled |
| Quoted discharge | Run average over the whole record, Q = A x abs(dh) / T | `src/metrics/compute_branch_statistics.m:37-38`, `:40-45`, `:101-105`; `doc/qdip_jet_check.md:50-51` | settled |
| A (plan area) | 5.7918 m^2 = 2.952 m x 1.962 m (measured inner dimensions). The nominal 3.0 x 2.0 m (6.0 m^2) overstates the area by 3.6% and must not be used | `config/constants.m:16-24`; `doc/settled_and_retracted.md:25`; `doc/piv_conditions.md:78-81` | settled |
| dh in the implementation | Difference between the depth of the last and the first frame of the record (`depth_m` in `frame_metrics`), i.e. gauge readings at the two ends | `src/metrics/compute_branch_statistics.m:102-105` | computed (repo code) |
| End readings of the record | First / last `depth_m` = 30.0 / 100.0 mm in all 12 inflow runs and 100.0 / 30.0 mm in all 12 outflow runs, so abs(dh) = 70 mm in every run | `local/derived/metrics/R00xx/frame_metrics.csv` (columns `time_s`, `depth_m`), arithmetic in this task; agrees with `metadata/runs.csv:3-26` (`start_depth_m`, `end_depth_m`) and `doc/qdip_jet_check.md:60` | computed |
| T in the implementation | Span of the PIV frame times, max(time_s) - min(time_s) (not the logger duration) | `src/metrics/compute_branch_statistics.m:102-105` | computed (repo code) |
| PIV record vs logger record length | Within 0.3 s for four of the five runs checked; R0006: PIV 1002.0 s vs logger 1008.2 s (6.2 s; 0.6% on the normalized-time mapping) | `doc/qdip_jet_check.md:178-179`; `local/derived/qc/qdip_jet_check/run_summary.csv` (`dur_diff_s`) | computed (repo script) |
| Run average relative to nominal | inflow 0.75-0.89, outflow 0.78-1.00 | `doc/qdip_jet_check.md:50-51`; inflow also `doc/settled_and_retracted.md:16` | settled as a relative figure; the absolute value is unverified (section 6) |
| Inflow run averages by level | low 0.219 / medium 0.392 / high 0.623 L/s | `doc/settled_and_retracted.md:16`; `doc/metrics_primer.md:26-29` | settled; absolute value unverified |
| What those three figures are | Medians of the four runs per level (means would be 0.217 / 0.390 / 0.619) | `local/derived/metrics/branch_stats.csv` (`Q_run_mean_Lps`), arithmetic in this task | computed |
| Inflow per-run run averages [L/s] | R0001 0.218, R0002 0.223, R0003 0.220, R0004 0.207 (low); R0005 0.403, R0006 0.405, R0007 0.373, R0008 0.381 (medium); R0009 0.634, R0010 0.632, R0011 0.615, R0012 0.597 (high) | `local/derived/metrics/branch_stats.csv` (`Q_run_mean_Lps`, file dated 2026-10-26) | computed (repo code `compute_branch_statistics`) |
| Inflow ratio to nominal per level | low 0.83-0.89, medium 0.75-0.81, high 0.80-0.84 (overall 0.745-0.891) | same file, arithmetic in this task | computed |
| Medium-level spread | 0.373-0.405 L/s; R0007 0.373 vs R0008 0.381 (2.2% apart) | `paper/README.md:116-118` | settled |
| Outflow per-run run averages | Not in `branch_stats.csv` (it holds the 12 inflow runs only). Cross-check from `frame_metrics.csv`: low 0.195-0.249, medium 0.434-0.450, high 0.681-0.701 L/s; ratio to nominal 0.78-1.00, which reproduces the recorded range | `local/derived/metrics/R0013..R0024/frame_metrics.csv`, arithmetic in this task (Q = 5.7918 x 0.070 / T) | computed (cross-check only; no authoritative per-run table exists for outflow) |
| Nominal levels | low / medium / high = 0.25 / 0.50 / 0.75 L/s, listed with 2.5 / 5.0 / 7.5 mm/min | `metadata/flow_levels.csv:2-4` | settled (labels) |
| Meaning of "nominal" | A target value for the port, not a measurement | `doc/metrics_primer.md:27`; `cfd/campaign.md:310` | settled |
| How the nominal discharge was obtained (added by audit) | Derived from the plan area of the basin and the nominal rate of water-level change. Numerically 2.5 / 5.0 / 7.5 mm/min x 6.0 m^2 = 0.25 / 0.50 / 0.75 L/s, so the nominal plan area was used (C13) | `metadata/README.md:75`; `metadata/flow_levels.csv:2-4`, arithmetic | settled (documentation); which area: computed |
| How the discharge was set | By the pump frequency (Hz). The old manuscript's "valve opening" is wrong | `doc/settled_and_retracted.md:30`; `cfd/campaign.md:407-408`; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:163-165`; old: `paper/2026_journal_Shonai/sections/methods.tex:9` | user-confirmed (2026-11-15) |
| Feed-channel plan area below h = a | Ignored in the run average; "worth about 1%". The 1% rests on an assumed footprint 0.6 x b = +0.066 m^2 (+1.1%), which is not a measured dimension of the rig | `src/metrics/compute_branch_statistics.m:44-45`; `doc/piv_conditions.md:132`; `doc/metrics_primer.md:173` | unverified (assumption) |
| Direct flow measurement | None is mentioned in any source read; discharge is inferred from level change and time only | (absence) `doc/qdip_jet_check.md`, `doc/settled_and_retracted.md`, `metadata/README.md` | GAP |

## 2. Ground 1 -- PIV jet-speed test

### 2a. Definitions

| fact | value | source (file:line) | status |
|---|---|---|---|
| Purpose | A measure of port discharge that does not pass through the water level | `doc/qdip_jet_check.md:130`; `scripts/checks/qdip_jet_check.py:6-12` | settled |
| Rationale | For h < a the port-exit mean velocity is U = Q / (b h). h changes by less than 20% across the dip, so Q falling to 1/3 would make U fall to about 1/3. The jet reaches x = 0.5 m in 10-17 s; the dip lasts 140-490 s | `doc/qdip_jet_check.md:132-134` | settled |
| Level-derived discharge Q_level | A x abs(dh/dt) by a dwell-time method: time spent at each integer 1 mm logger level (levels 31-99 mm); over a sliding window of 5 levels, Q = A x 5 mm / (total dwell) | `scripts/checks/qdip_jet_check.py:96-115`; `doc/qdip_jet_check.md:117-118` | computed (repo script) |
| Logger resolution | 1 mm steps | `doc/qdip_jet_check.md:117`; `scripts/checks/qdip_jet_check.py:18`; `src/metrics/compute_actual_discharge.m:8-11` | settled |
| Jet proxy (main statistic, "core") | x = 0.19-0.52 m. PIV fields are averaged over 5 s blocks; the speed of the block-mean vector is taken; at each x column the maximum over y is taken; the maxima are averaged over the x columns | `scripts/checks/qdip_jet_check.py:49-50`, `:142-177`, `:217-229`; `doc/qdip_jet_check.md:135-136` | computed (repo script) |
| y range searched | y = 0.38-1.66 m (contains the jet axis; port centre y about 0.98 m). x range read 0.05-1.30 m | `scripts/checks/qdip_jet_check.py:52-53` | computed (repo script) |
| Block length | 5 s (= round(5 x frame rate) frames) | `scripts/checks/qdip_jet_check.py:49`, `:156-157` | computed (repo script) |
| Why x starts at 0.19 m | Right at the port (x < 0.15 m) the PIV does not capture the jet (surface speed about 0.01 m/s) | `doc/qdip_jet_check.md:135` | settled |
| Auxiliary statistics | `frame_max` (block mean of the per-frame maximum over y) and `jetflux` (streamwise surface flux, sum of u dy over +-3 cells about the jet axis; detects "same speed but narrower jet") | `scripts/checks/qdip_jet_check.py:222-239`; `doc/qdip_jet_check.md:137` | computed (repo script) |
| Other x windows | W1 0.07-0.25, W2 0.19-0.52 (main), W3 0.50-0.80, W4 0.80-1.25 m | `scripts/checks/qdip_jet_check.py:51` | computed (repo script) |
| Depth of each block | `depth_m` of the block's centre frame in `frame_metrics.csv`, i.e. the s31 mapping (gauge depth, normalized time) | `scripts/checks/qdip_jet_check.py:297-304`; `doc/qdip_jet_check.md:139` | computed (repo script) |
| Q_level of each block | Q_level(h) profile interpolated at the block depth | `scripts/checks/qdip_jet_check.py:305` | computed (repo script) |
| Depth windows [mm] | ref 32-38, pre 38-42, dip 44-50, post 56-62, "B3" 62-75, "B4" 75-95 | `scripts/checks/qdip_jet_check.py:55-57`; `doc/qdip_jet_check.md:138` | computed (repo script) |
| Caution on names | The windows called "B3" (62-75 mm) and "B4" (75-95 mm) in this test are not the depth bands B3 (60-75 mm) and B4 (75-100 mm) | `scripts/checks/qdip_jet_check.py:56-57` vs `metadata/depth_bands.csv:4-5` | computed |
| Main test | Per run, ordinary least-squares slope beta of log(proxy) on log(Q_level) over the blocks with h = 35-62 mm | `scripts/checks/qdip_jet_check.py:58`, `:252-254`, `:318-326`; `doc/qdip_jet_check.md:140` | computed (repo script) |
| 95% interval | Moving-block bootstrap, block 60 s (12 blocks of 5 s), 2000 resamples, 2.5 / 97.5 percentiles, seed 0 | `scripts/checks/qdip_jet_check.py:59`, `:257-270`, `:322`, `:489-490`; `doc/qdip_jet_check.md:141` | computed (repo script) |
| Expected beta | About n (the sensitivity below) if the dip were real, about 0 if it is apparent | `doc/qdip_jet_check.md:141-142` | settled |
| Sensitivity n | n = ln(proxy ratio) / ln(Q ratio) between flow levels in the same depth window; the Q ratio is the ratio of level-derived Q in that window | `scripts/checks/qdip_jet_check.py:366-383`, `:446`; `doc/qdip_jet_check.md:143-144` | computed (repo script) |
| Per-run verdict rule | `dip-not-followed`: upper 95% bounds of beta (core and frame_max) both below 0.5; `dip-followed`: both beta at or above 0.6; `low-power`: Q_level swings by less than a factor 2 in the window | `scripts/checks/qdip_jet_check.py:61-65`, `:273-280`; `doc/qdip_jet_check.md:190-195` | computed (repo script) |

### 2b. Runs

| fact | value | source (file:line) | status |
|---|---|---|---|
| Runs tested | 5 of the 12 inflow runs: R0001 (low), R0005, R0006, R0007, R0008 (medium) | `doc/qdip_jet_check.md:148-158`, `:241`; `local/derived/qc/qdip_jet_check/run_summary.csv` | settled |
| Why only those | They are the only runs whose canonical PIV fields (`pivlab_single.mat`) are on the laptop where the check was run (2026-10-15). R0002-R0004 (low) and R0009-R0012 (high) are on the lab workstation and have not been transferred | `doc/qdip_jet_check.md:148`, `:241`; `paper/README.md:134`, `:169`; `doc/settled_and_retracted.md:32`; `local/work/*/pivlab_single.mat` (present for R0001, R0005-R0008 only) | settled |
| Check on the other 7 runs | Not done. Deprioritised after the lower-reservoir result; the workstation lacks h5py | `doc/qdip_jet_check.md:112-113`, `:254-256` | GAP |
| Consequence | No high-level run was tested; the low level is represented by one run (R0001) | `doc/qdip_jet_check.md:241-242` | settled (limitation) |
| Outflow | The same test can be run with `--mode outflow`, but outflow PIV is near the noise floor and its dip is shallow, so the power is low (reference only). No outflow result is recorded | `doc/qdip_jet_check.md:228-229`; `scripts/checks/qdip_jet_check.py:28` | GAP |

### 2c. Numbers

| fact | value | source (file:line) | status |
|---|---|---|---|
| beta, summary | -0.05 to -0.17 over the five runs (range spans both statistics); all five negative; upper 95% bound at most +0.03 | `doc/qdip_jet_check.md:15-16`, `:160` | settled |
| beta (core) [95% interval] | R0001 -0.08 [-0.17, -0.01]; R0005 -0.11 [-0.15, -0.03]; R0006 -0.07 [-0.24, -0.01]; R0007 -0.13 [-0.27, +0.01]; R0008 -0.17 [-0.27, -0.06] | `doc/qdip_jet_check.md:152-158`; `local/derived/qc/qdip_jet_check/run_summary.csv` (`beta_core*`) | computed (repo script) |
| beta (frame_max) [95% interval] | R0001 -0.05 [-0.17, +0.03]; R0005 -0.10 [-0.20, -0.03]; R0006 -0.06 [-0.27, +0.03]; R0007 -0.10 [-0.14, -0.01]; R0008 -0.13 [-0.18, -0.06] | same (`beta_frame_max*`) | computed (repo script) |
| beta if the dip were real | +0.8 to +1.1 | `doc/qdip_jet_check.md:16`, `:160`; `scripts/checks/qdip_jet_check.py:10-11` | settled |
| Swing of Q_level inside the regression range (h = 35-62 mm) | x3.6 (R0001), x3.3 (R0005), x3.8 (R0006), x3.0 (R0007), x2.6 (R0008) | `doc/qdip_jet_check.md:152-158`; `run_summary.csv` (`qlevel_range`) | computed (repo script) |
| Blocks in the regression | 206 (R0001), 110-117 (medium runs) | `local/derived/qc/qdip_jet_check/run_summary.csv` (`n_reg_blocks`) | computed (repo script) |
| Sensitivity n, medium/low | ref 0.82, pre 1.03, dip 0.84, post 0.99, "B3" 0.98, "B4" 1.11 | `doc/qdip_jet_check.md:162`; `local/derived/qc/qdip_jet_check/calibration.csv` | computed (repo script) |
| Reading of n | The proxy responds to discharge almost proportionally, also inside the dip window | `doc/qdip_jet_check.md:163` | settled |
| Weakness of n | Based on 4 medium runs vs 1 low run (R0001); no high run, so high/medium and high/low are not available | `doc/qdip_jet_check.md:163`, `:242`; `calibration.csv` (`n_runs_a` = 4, `n_runs_b` = 1) | settled (limitation) |
| No V shape, Q_level | dip/ref of Q_level = 0.30-0.52 (CSV values 0.31-0.53 on rounding) | `doc/qdip_jet_check.md:168`; `run_summary.csv` (`Q_dip_ref`) | computed (repo script) |
| No V shape, proxy (x = 0.19-0.52 m) | dip/ref: core 0.92-1.24, frame_max 0.90-1.14, jetflux 0.91-1.85. The flux including jet width does not fall either | `doc/qdip_jet_check.md:168-170`; `local/derived/qc/qdip_jet_check/window_ratios.csv` | computed (repo script) |
| Other x windows | W1 (0.07-0.25 m) scatters widely (core 0.58-1.54). W3, W4 (0.50-1.25 m) decrease monotonically with depth (dip/ref 0.52-0.96, post/ref 0.38-0.82) and do not recover | `doc/qdip_jet_check.md:170-172` | computed (repo script) |
| PIV filter | PIVLab has no upper/lower velocity limit filter here (6-sigma standard-deviation filter, local median 3, correlation 0.5 only); the R0005 speed distribution near the jet is smooth up to 0.126 m/s | `doc/qdip_jet_check.md:174-175` | settled |
| Valid-vector fraction (typevector = 1) | ref 0.92-0.94, dip 0.97-0.98 | `doc/qdip_jet_check.md:176`; `run_summary.csv` (`valid_ref`, `valid_dip`) | computed (repo script) |
| Jet axis | y = 0.73-1.31 m (ref), 0.93-1.07 m (dip); inside the range read | `doc/qdip_jet_check.md:177` | computed (repo script) |
| Overall confirmation criteria | (1) every run `dip-not-followed`; (2) n in the dip window at least 0.6 for each level pair; (3) PIV-logger length difference within 10 s for every run | `doc/qdip_jet_check.md:197-202` | settled |
| Criteria as met | All 5 tested runs `dip-not-followed`; n(dip) = 0.84 for the one available pair; largest length difference 6.2 s. Criterion (1) over all 12 runs is not met because 7 are untested | `doc/qdip_jet_check.md:152-162`, `:178-179`, `:241` | settled (partial coverage) |
| Limitation: surface only | The vertical profile of the jet is not seen | `doc/qdip_jet_check.md:245-246` | settled (limitation) |
| Limitation: only the dip is testable | The rise of Q_level for h > a (about 0.75 to 1.25 of nominal) cannot be judged by this test | `doc/qdip_jet_check.md:247-248` | settled (limitation) |
| CFD constant-discharge reference | Exists in the record (two CFD cases) as a further check. Not usable in paper 1 | `doc/qdip_jet_check.md:145-146`, `:164-167`; exclusion: `paper/README.md:17-18`, `:92` | do not use |

## 3. Ground 2 -- lower reservoir

| fact | value | source (file:line) | status |
|---|---|---|---|
| What is recorded | The experimenter measured the water level of the lower reservoir; it changed at a constant rate even while the upper-basin reading was fluctuating ("揺れている間も"). Date: late October 2026. Reading: the discharge seen from the supply side is constant | `doc/qdip_jet_check.md:17-18`; `cfd/campaign.md:251-252`; `doc/piv_conditions.md:155` | settled (observation as reported by the experimenter) |
| Mode (inflow / outflow) of that measurement | not recorded | `doc/qdip_jet_check.md:18-19`; `cfd/campaign.md:272-273` | GAP |
| Flow level(s) | not recorded | same | GAP |
| Instrument | not recorded | same | GAP |
| Plan area of the lower reservoir | not recorded (measuring it once is also what would close the absolute discharge, section 6) | same; `doc/settled_and_retracted.md:23`, `:55` | GAP |
| Whether the interval of upper-basin level 40-60 mm was covered | not recorded | `doc/qdip_jet_check.md:19` | GAP |
| How constant "constant" was | not recorded (no number) | `doc/qdip_jet_check.md:19` | GAP |
| Number of runs measured | not recorded | (absence) `doc/qdip_jet_check.md:17-19` | GAP |
| Standing of this blank | Already listed as a blank in the writing agreement | `paper/README.md:89`; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:69-71` | user-confirmed |
| What the observation cannot do | It is compatible with both a gauge error and real storage on the basin side, so it does not separate those two | `doc/qdip_jet_check.md:42-43` | settled (limitation) |

## 4. Ground 3 -- behaviour of the gauge reading

| fact | value | source (file:line) | status |
|---|---|---|---|
| Gauge | KEYENCE FR-S01, 60 GHz (millimetre-wave) radar level sensor. Not ultrasonic | `doc/qdip_jet_check.md:20`; `doc/settled_and_retracted.md:19`, `:44`; `cfd/campaign.md:309` (logger header and user confirmation) | settled (2026-11-14) |
| Position | By the wall facing the inlet (port); `settled_and_retracted` adds "on the centreline" | `doc/qdip_jet_check.md:20`; `doc/settled_and_retracted.md:19` | settled; coordinates are a GAP |
| Lens height | About 0.50 m above the basin floor | `doc/qdip_jet_check.md:21`; `cfd/campaign.md:309` | settled |
| Distance to the water surface | 0.40-0.47 m | `doc/qdip_jet_check.md:21` | settled |
| Specified accuracy | +-1 mm (class 0.3-1.5 m). The specification is a guarantee for the recommended mounting and static water; a rippled surface viewed close to a wall is outside it | `doc/qdip_jet_check.md:21-22`, `:25-26` | settled |
| Coincidence with the dip | In inflow, the dip coincides with the depth at which the number of changes of the gauge reading (the surface disturbance as seen by the gauge) falls from 15-50 per minute to 5-15 per minute; this holds in all 12 inflow runs | `doc/qdip_jet_check.md:22-23` | settled |
| After the dip | Q_level recovers, but the change count stays low; so the calming of the surface is not a consequence of a lower discharge | `doc/qdip_jet_check.md:24` | settled |
| Raw signal during the stall | Still changes 10-23 times per minute (waves are picked up); the signal is not stuck and shows no physically impossible jump. If the gauge is the cause it is a "distorted scale" fault, not a "frozen" one | `doc/qdip_jet_check.md:183-184` | settled (checked outside the script) |
| Depth at which the surface calms (inflow) | About 45-48 mm on either depth axis, with large scatter | `doc/qdip_jet_check.md:46` | settled |
| Reproducibility of the count analysis | `qdip_jet_check.py` does not compute the reading-change counts; the counting window and rule are not written down | (absence) `scripts/checks/qdip_jet_check.py`; `doc/qdip_jet_check.md:181-184` | GAP (method) |
| Stated cause of the misreading | "bubbles and surface agitation at h about 45-55 mm" | `doc/settled_and_retracted.md:19` | unverified as a mechanism (the authoritative file shows a coincidence, not a cause; see C11) |
| Inflow/outflow asymmetry of the artefact | Described as consistent with the sensor being on the wall that the jet strikes only during inflow | `cfd/campaign.md:307` | unverified (interpretation) |
| Logger sampling interval, gauge response/averaging setting, zero reference | not recorded in any source read | (absence) `doc/qdip_jet_check.md`, `src/io/read_waterlevel.m:16-21` | GAP |

## 5. The apparent dip and related features of the level-derived discharge

These describe the retracted quantity. They may be reported only as a description of the artefact.

| fact | value | source (file:line) | status |
|---|---|---|---|
| Inflow dip, location | h about 44-50 mm (h/a about 0.85), in all 12 inflow runs | `doc/qdip_jet_check.md:12`, `:117-119` | settled |
| Inflow dip, size | About 0.35 of nominal | `doc/qdip_jet_check.md:12`, `:119`; `scripts/checks/qdip_jet_check.py:6-7` | settled |
| Inflow dip, cross-check | 0.33-0.43 of nominal; 0.40-0.53 of the run average (dwell time over gauge levels 44-49 mm, 12 runs) | `local/derived/metrics/R0001..R0012/frame_metrics.csv`, arithmetic in this task | computed (cross-check) |
| Inflow dip relative to the run average, as noted in the old manuscript | 0.33-0.51 | old: `paper/2026_journal_Shonai/sections/methods.tex:25` (comment) | unverified |
| Dip relative to the 32-38 mm window (5 runs) | 0.30-0.52 | `doc/qdip_jet_check.md:168` | computed (repo script) |
| Dependence | Same shape for low / medium / high; appears at the same depth although the run durations differ by a factor 3 (governed by depth, not elapsed time) | `doc/qdip_jet_check.md:119-120` | settled |
| Duration of the dip | 140-490 s | `doc/qdip_jet_check.md:134` | settled |
| Why band averages hid it | B1 (30-50 mm) mixes an interval at about 1.2 of nominal with one at about 0.35 | `doc/qdip_jet_check.md:121` | settled |
| Outflow feature | A shallower, broader dip: about 0.7 (of nominal), at h/a about 0.8-1.0 | `doc/qdip_jet_check.md:120` | settled |
| Outflow feature, cross-check | 0.61-0.85 of nominal over gauge levels 44-55 mm (12 runs) | `local/derived/metrics/R0013..R0024/frame_metrics.csv`, arithmetic in this task | computed (cross-check) |
| Inflow vs outflow | Not symmetric: swing of 2.0-3.2 (inflow) vs 1.0-1.6 (outflow); the outflow dip is shallow and cannot be treated on a par | `doc/settled_and_retracted.md:47`; `cfd/campaign.md:307` | settled |
| Deep-water over-read, as recorded | Inflow, h/a 1.4-1.7 (= 77-94 mm): level-derived Q = 1.41-1.50 of the run average; outflow 1.15-1.34 | `cfd/campaign.md:260-261` (not in `doc/qdip_jet_check.md`) | unverified (non-authoritative file; see C3) |
| Deep-water over-read, old manuscript note | 1.34-1.48 of the run average in the deep bands | old: `paper/2026_journal_Shonai/sections/methods.tex:25-26` (comment) | unverified |
| Deep-water rise, authoritative file | Q_level rises from about 0.75 to about 1.25 of nominal for h > a | `doc/qdip_jet_check.md:247` | settled (description) |
| Deep-water over-read, cross-check | Inflow 1.35-1.59 of the run average (11 of 12 runs within 1.35-1.48; R0006 1.59); outflow 1.15-1.33 (dwell time over gauge levels 77-94 mm) | `local/derived/metrics/R00xx/frame_metrics.csv`, arithmetic in this task | computed (cross-check) |
| Size of the depth misreading | Up to about 10 mm near h/a about 1, which makes band-wise discharge appear to swing by a factor 2-3 | `doc/settled_and_retracted.md:17`; `src/metrics/compute_branch_statistics.m:47-51` | settled |
| "Missing volume" over 40-60 mm | Depends strongly on the baseline: inflow 14-117 L, outflow 1-33 L; inflow and outflow do not balance | `doc/qdip_jet_check.md:185-186` | settled |
| Preserved ratios between levels | high/low 2.8-3.4, medium/low 1.8-2.3 at every depth | `doc/qdip_jet_check.md:28` | settled |
| Ratios of run averages | high/low 2.84, medium/low 1.79 (from the level medians 0.623 / 0.392 / 0.219); nominal 3.0 and 2.0 | `doc/settled_and_retracted.md:16`, arithmetic in this task | computed |

## 6. Depth axis

### 6a. Decision and definition

| fact | value | source (file:line) | status |
|---|---|---|---|
| Decision | The time-proportional depth is the primary axis; the gauge depth is reported alongside as a sensitivity check | `doc/settled_and_retracted.md:20`; `paper/README.md:61-63` | user-confirmed (2026-11-22) |
| Rationale | If discharge and plan area are constant, the true level is proportional to time; having stated that discharge is steady, the consistent primary axis is the time-proportional one | `doc/qdip_jet_check.md:32`, `:101-102` | settled |
| Definition used in the impact assessment | The straight line joining the start and the end of the record (30 mm and 100 mm), on the same normalized time as s31 | `doc/qdip_jet_check.md:60`; `paper/README.md:61` | settled |
| Normalized time of a frame (s31) | u = (t - t_min) / (t_max - t_min) of the PIV frame times, clipped to [0, 1] | `src/metrics/assign_depth_bands.m:41-46` | computed (repo code) |
| Resulting formula | h(t) = h_first + (h_last - h_first) u, with (h_first, h_last) = (30, 100) mm for inflow and (100, 30) mm for outflow | reading of `doc/qdip_jet_check.md:60` with `src/metrics/assign_depth_bands.m:41-46`; end readings confirmed in section 1 | unverified as code (the calculation was done in a scratchpad and is not in the repo, `doc/qdip_jet_check.md:62`). Reproduced by audit: this formula applied to the 24 `frame_metrics.csv` files returns the recorded lock-strength medians (3.02 / 7.27 / 10.73), sign persistences (R0003 0.972, R0007 0.896, R0002 0.817) and phi_lv level means of sections 6d-6e |
| Band assignment in the assessment | Same rules as s32; with the gauge depth the calculation reproduces the current `band_metrics.csv` to a relative difference of 1e-14 or less | `doc/qdip_jet_check.md:61-62` | settled (not a repo tool) |
| Scope of the assessment | 24 runs, `frame_metrics.csv`, only the depth replaced | `doc/qdip_jet_check.md:59` | settled |
| Shared assumption | Both axes fix the same two end readings, so the unverified span of the gauge is shared by both | old: `paper/2026_journal_Shonai/sections/methods.tex:28-29` (comment); `paper/README.md:156-159` | settled (logic) |
| Effect of the feed-channel plan area on linearity | Under the assumed +1.1% plan area below h = a, the true level departs from the straight line by about 0.2 mm at most | `doc/piv_conditions.md:132`, arithmetic in this task | computed (under an unverified assumption) |

### 6b. Current gauge-axis mapping (what the files contain today)

| fact | value | source (file:line) | status |
|---|---|---|---|
| Alignment | Logger series and PIV frames are treated as co-extensive records and aligned by normalized time: logger sample i of N maps to (i - 1)/(N - 1), a frame to u above; depth is linearly interpolated | `src/metrics/assign_depth_bands.m:21-28`, `:38-48`; `src/io/read_waterlevel.m:18-21`; `scripts/s31_map_waterlevel.m:5-7`, `:69-70` | computed (repo code) |
| Bands | B1 0.030-0.050 m (h/a 0.55-0.91), B2 0.050-0.060 m (0.91-1.09), B3 0.060-0.075 m (1.09-1.36), B4 0.075-0.100 m (1.36-1.82) | `metadata/depth_bands.csv:2-5` | settled |
| Band edges | Half-open [h_min, h_max), except the deepest band, which includes its upper edge | `src/metrics/assign_depth_bands.m:51-65` | computed (repo code) |
| Frames outside all bands on the gauge axis (added by audit) | 85 frames in three inflow runs (R0005 7, R0009 23, R0011 55; all within the first 15 s) have a gauge depth between 29.0 and 30.0 mm and an empty `band_id`: the first frame reads 30.0 mm, then the 1 mm reading drops back to 29 mm. No outflow frame and no frame of the other nine inflow runs is outside the bands. With the straight line of section 6a no frame falls outside. The old manuscript's statement that every frame was assigned to a band does not hold for the current files | `local/derived/metrics/R0005,R0009,R0011/frame_metrics.csv` (`depth_m`, `band_id`), arithmetic in the audit; old: `paper/2026_journal_Shonai/sections/results.tex:21` | computed (cross-check) |
| Port height for h/a | a = 0.055 m | `config/constants.m:45`; `scripts/s31_map_waterlevel.m:67` | settled |

### 6c. Deviation of the gauge from the time-proportional line

| fact | value | source (file:line) | status |
|---|---|---|---|
| Inflow (12 runs), largest reading minus line | -9 to -11 mm, near readings of 50-59 mm | `doc/qdip_jet_check.md:35-37`; `cfd/campaign.md:266` | settled |
| Outflow (12 runs), largest reading minus line | -4 to -6 mm, near readings of 53-67 mm | `doc/qdip_jet_check.md:35-38`; `cfd/campaign.md:266` | settled |
| Share of the record time whose band changes | inflow 31-39%; outflow 10-18% | `doc/qdip_jet_check.md:35-38` | settled |
| Where gauge band B2 (50-60 mm) falls on the line | inflow 55-70 mm; outflow 51-65 mm | `doc/qdip_jet_check.md:35-38` | settled |
| Rounded statement | "up to about 10 mm near h/a about 1" | `doc/settled_and_retracted.md:17` | settled |
| Cross-check, inflow | Largest deviation -10.0 to -12.2 mm at gauge readings 50-60 mm; band changes for 31.8-37.5% of frames (32-37%; corrected by audit from "32-38%"); gauge B2 frames lie at 50-71 mm on the line | `local/derived/metrics/R0001..R0012/frame_metrics.csv`, arithmetic in this task (per-frame extreme of the 1 mm-quantized reading, no smoothing) | computed (cross-check; about 1 mm larger than recorded, see C8) |
| Cross-check, outflow | Largest deviation -4.5 to -6.5 mm at gauge readings 53-68 mm; band changes for 9-18% of frames; gauge B2 frames lie at 50-65 mm on the line | `local/derived/metrics/R0013..R0024/frame_metrics.csv`, arithmetic in this task | computed (cross-check) |
| Where the largest deviation sits on the primary axis (added by audit) | At the frame of largest negative deviation the time-proportional depth is 61-71 mm in inflow (h/a 1.12-1.30; gauge reading 50-60 mm) and 59-74 mm in outflow (gauge reading 53-68 mm). "Near h/a about 1" is therefore true of the gauge reading, not of the time-proportional depth | `local/derived/metrics/R0001..R0024/frame_metrics.csv`, arithmetic in the audit (same per-frame definition as the two rows above) | computed (cross-check) |
| Sign of the deviation (added by audit) | The reading is not below the line throughout: early in the record it is above it, by at most +2.1 to +4.9 mm in inflow (readings 34-44 mm) and +1.0 to +1.8 mm in outflow (readings 31-44 mm). The recorded figures give only the negative extreme | same files, arithmetic in the audit | computed (cross-check) |
| Where the indicators change | The location of flow changes did not decide between the axes: in outflow the depth at which the surface flow suddenly strengthens (port soffit emerging) is about 50 mm on the gauge axis and about 53 mm on the time-proportional axis (mean of the 10 runs in which it was detected; soffit at 55 mm) | `doc/qdip_jet_check.md:44-46` | settled |
| Two different depths, do not merge | The dip of the rate dh/dt is at 44-50 mm; the accumulated offset of the reading peaks later, at readings of 50-59 mm | `doc/qdip_jet_check.md:12`, `:37` | settled |

### 6d. Impact assessment (2026-10-26) -- what does not move

| fact | value | source (file:line) | status |
|---|---|---|---|
| Branch sign (frames of B3 + B4 pooled) | Unchanged in all 12 inflow runs (low 4/4 positive, high 4/4 negative, medium 3 negative / 1 positive) | `doc/qdip_jet_check.md:66` | settled |
| Lock strength, level medians | 3.6 / 8.7 / 11.8 (gauge) -> 3.0 / 7.3 / 10.7 (time-proportional); the monotonic increase is kept | `doc/qdip_jet_check.md:67` | settled (values move, ordering does not) |
| Runs with sign persistence 1.000 | 10/12 -> 9/12 (R0003 becomes 0.972; R0007 0.970 -> 0.896; R0002 0.826 -> 0.817) | `doc/qdip_jet_check.md:68` | settled |
| Inflow trends | E largest in B1 and decreasing monotonically; phi_lv increasing monotonically; I_rot largest in B1; I_asym without systematic dependence | `doc/qdip_jet_check.md:69-70` | settled |
| Outflow | phi_lv = 1, very small I_rot, and the topology are unchanged | `doc/qdip_jet_check.md:70` | settled |
| Location of the sharp fall in unsteadiness (coefficient of variation of E in 5 mm windows) | h/a about 0.98 (gauge) vs about 1.05 (time-proportional); both near h/a about 1 | `doc/qdip_jet_check.md:71-72` | settled |

### 6e. Impact assessment -- band values that move (inflow)

Audit note: every range in this table is the range of the **three flow-level means** (mean of the four
runs of each level), not the range over the 12 runs; the source table does not say so
(`doc/qdip_jet_check.md:76-84`). Recomputing from `frame_metrics.csv` reproduces the level-mean
figures on both axes (see "Audit (second reader)"). The per-run ranges are wider, for example
I_unst in B1 0.34-0.45 (gauge) and 0.24-0.36 (time-proportional), E ratio B1/B4 2.6-4.6 and 2.9-5.0,
I_rot in B1 0.092-0.128 and 0.098-0.140. Do not present the ranges below as run-to-run ranges.

| fact | value: gauge depth (current files) -> time-proportional depth | source (file:line) | status |
|---|---|---|---|
| E ratio B1/B4 | 2.6-4.4 -> 3.0-4.9 | `doc/qdip_jet_check.md:78` | settled (one-off calculation) |
| E in B2 | +23 to +45% | `doc/qdip_jet_check.md:79` | settled (one-off calculation) |
| phi_lv, B1 -> B4 | low 0.38 -> 0.58, medium 0.37 -> 0.58, high 0.22 -> 0.46 becomes 0.34 -> 0.58, 0.34 -> 0.57, 0.21 -> 0.45 | `doc/qdip_jet_check.md:80` | settled (one-off calculation) |
| I_rot in B1 | 0.095-0.123 -> 0.103-0.134 | `doc/qdip_jet_check.md:81` | settled (one-off calculation) |
| I_asym range | 0.22-0.30 -> 0.19-0.30 | `doc/qdip_jet_check.md:82` | settled (one-off calculation) |
| I_unst | B1 0.35-0.40, B2 0.08-0.13, B3/B4 0.03-0.05 -> B1 0.28-0.33, B2 0.09-0.20, B3/B4 0.05-0.10 | `doc/qdip_jet_check.md:83` | settled (one-off calculation) |
| Frames per band | B1 -25 to -27%, B2 -15 to -19%, B3 +14 to +16%, B4 +40 to +45% | `doc/qdip_jet_check.md:84` | settled (one-off calculation) |
| Largest effect | I_unst: the contrast between B1 and B3/B4 shrinks from "about one order" to "about 3-7 times" | `doc/qdip_jet_check.md:86` | settled |
| Outflow | Small changes; but high, B2: SNR 2.1 -> 3.1, crossing the SNR >= 3 criterion. Audit: 2.1 and 3.1 are the means of the four high runs; per run the SNR is 1.6-2.5 (gauge) and 2.2-4.4 (time-proportional), and only R0021 (4.4) exceeds 3 on the time-proportional axis (R0022 2.99). The `E_resolved` flag in `band_metrics.csv` is set per run | `doc/qdip_jet_check.md:87`; criterion `config/metrics_defaults.m:21-22`; per-run values: `local/derived/metrics/R0021..R0024/frame_metrics.csv` with `config/constants.m:104`, arithmetic in the audit | settled (one-off calculation); per-run values computed (cross-check) |
| Adjacent findings, independent of the axis (for the Results writer) | Three runs (R0002, R0003, R0007), not two, have a B1 sign opposite to the deep-water sign; most of I_unst is the within-band trend of E. The share is recorded as "65-75%" for inflow B1 in the authoritative file and as "5-8 割" (50-80%) in the index and the writing agreement (see C15) | `doc/qdip_jet_check.md:89-99`; `doc/settled_and_retracted.md:21`; `paper/README.md:57` | settled (the finding); the percentage is unverified (two recorded figures, C15) |

## 7. Implementation status (state plainly in any hand-off)

| fact | value | source (file:line) | status |
|---|---|---|---|
| `s31_map_waterlevel.m` | Offers no choice of depth axis. Its only settings are the run ID and the smoothing window; it always writes the gauge depth mapped by normalized time | `scripts/s31_map_waterlevel.m:22-30`, `:64-79` | computed (repo code) |
| Planned change | Add a depth option to s31, then update the band values and figures. Not done | `paper/README.md:63`, `:167-168`; `doc/settled_and_retracted.md:20`; `doc/qdip_jet_check.md:104` | settled (pending work) |
| `frame_metrics.csv` | `depth_m`, `h_over_a`, `band_id` are on the gauge axis | `scripts/s31_map_waterlevel.m:69-79` | computed (repo code) |
| `band_metrics.csv` | Still on the gauge axis (file on this machine dated 2026-07-27, the date of the last s31 -> s32 rerun) | `local/derived/metrics/band_metrics.csv` (file date); `doc/piv_conditions.md:98-102`; `doc/qdip_jet_check.md:76` ("現行") | settled |
| `branch_stats.csv` | B3 + B4 pooling uses gauge-axis bands (file dated 2026-10-26); lock strength and sign persistence in it are gauge-axis values | `src/metrics/compute_branch_statistics.m:107-111`; `local/derived/metrics/branch_stats.csv` | computed (repo code) |
| Time-proportional band values | Exist only as the ranges in `doc/qdip_jet_check.md:76-84`, from a scratchpad calculation that is not a repo tool; no per-run, per-band table on that axis exists | `doc/qdip_jet_check.md:61-62`, `:76-84` | GAP (final values) |
| Run-average discharge | Does not depend on the choice of axis (same end readings, same duration) | `src/metrics/compute_branch_statistics.m:101-105`; `doc/qdip_jet_check.md:60` | computed |
| Retracted columns still written | s31 still writes `q_actual_Lps` per frame and s32 still averages it into `band_metrics.csv` (`q_actual_Lps_mean`); `branch_stats.csv` still carries `Q_transit_Lps` as a diagnostic | `scripts/s31_map_waterlevel.m:72-79`; `scripts/s32_aggregate_band_metrics.m:25-26`; `src/metrics/compute_branch_statistics.m:47-52`, `:133` | computed (repo code) |
| Stale label in the authoritative file | `doc/qdip_jet_check.md` still heads the depth axis as "未決" (undecided); the decision of 2026-11-22 is recorded only in `doc/settled_and_retracted.md` and `paper/README.md` | `doc/qdip_jet_check.md:4`, `:30`; `doc/piv_conditions.md:156` vs `doc/settled_and_retracted.md:20` | settled (stale text, see C1) |

## 8. What remains unverified

| fact | value | source (file:line) | status |
|---|---|---|---|
| Gauge span | Whether the readings of 30 mm and 100 mm at the ends of the record are true depths has not been verified | `doc/settled_and_retracted.md:23`; `paper/README.md:156-158`; `cfd/campaign.md:270` | unverified |
| Absolute discharge | Follows from the span: the run averages and "0.75-0.89 of nominal" inherit the assumption | `paper/README.md:156-160`; `doc/settled_and_retracted.md:23` | unverified |
| Shape inside the record | Known to be wrong on the gauge axis (dip, deep-water over-read); only the span is open | old: `paper/2026_journal_Shonai/sections/methods.tex:23-29` (comment); `doc/qdip_jet_check.md:35-38` | settled |
| What would close it (1) | Measure the plan area of the lower reservoir once (ruler): with the lower-reservoir level change this gives an independent absolute discharge | `doc/settled_and_retracted.md:23`, `:55`; `paper/README.md:159-160`; `cfd/campaign.md:271` | settled (action pending, human decision) |
| What would close it (2) | One static calibration: with the port closed and still water, pour known volumes (for example 20 L at a time) and record the FR-S01 reading and a ruler reading over 30-100 mm. This also decides gauge error vs basin-side storage | `doc/qdip_jet_check.md:109`, `:250-252`; `doc/settled_and_retracted.md:55` | settled (action pending) |
| Quantization of the end readings | 1 mm steps on a 70 mm span (about 1.4% per mm) | `doc/qdip_jet_check.md:117`, arithmetic in this task | computed |
| Gauge error vs basin-side storage | Not separated by a direct test. If the water level really stalled because water went into storage on the basin side, the gauge depth would be correct and the axis would revert | `doc/qdip_jet_check.md:42-43`, `:103`, `:250-252` | unverified (see C11) |
| Outflow steadiness | Whether the outflow discharge is constant must be confirmed separately (it can vary with depth depending on how drainage is driven) | `doc/qdip_jet_check.md:110-111`; `cfd/campaign.md:274` | unverified (see C12) |
| Remaining PIV checks | 7 of 12 inflow runs untested, including every high-level run | `doc/qdip_jet_check.md:241`, `:254-256` | GAP |

## 9. Conflicts and stale passages found while compiling

| id | conflict | sources | how to handle |
|---|---|---|---|
| C1 | Depth axis is "未決" in the authoritative file but decided on 2026-11-22 elsewhere | `doc/qdip_jet_check.md:4`, `:30`; `doc/piv_conditions.md:156`; `cfd/campaign.md:48`, `:267` vs `doc/settled_and_retracted.md:20`; `paper/README.md:61-63` | Follow the decision (time-proportional primary). The older files are stale |
| C2 | Size of the inflow dip: "about 0.3" vs "about 0.35" of nominal | old `sections/methods.tex:38`, `sections/results.tex:25` vs `doc/qdip_jet_check.md:12`, `:119` | Use about 0.35 (authoritative); cross-check 0.33-0.43 |
| C3 | Deep-water over-read: 1.41-1.50 vs 1.34-1.48 of the run average; cross-check 1.35-1.59 | `cfd/campaign.md:260-261` vs old `sections/methods.tex:25-26` | Not in the authoritative file. Do not quote a range; if needed, placeholder |
| C4 | Whether the PIV follows the deep-water rise: "does not follow (beta = -0.11 to +0.05)" vs "cannot be judged" | `cfd/campaign.md:262` vs `doc/qdip_jet_check.md:247-248` | Do not claim a PIV test of the deep-water rise |
| C5 | Lower reservoir: old manuscript says the level changed at a constant rate "in the interval where the upper reading shows the dip"; the record says whether the 40-60 mm interval was covered is not recorded | old `sections/methods.tex:41` vs `doc/qdip_jet_check.md:17-19` | Use the weaker recorded wording; details are placeholders |
| C6 | Start of recording: "filming started as soon as the gauge read 20 mm" vs record starting at 30 mm | `cfd/campaign.md:408`; `doc/settled_and_retracted.md:30` vs `metadata/runs.csv:3-14` (`start_depth_m` 0.03), old `sections/methods.tex:13`, `doc/qdip_jet_check.md:60` | Already a declared blank (`paper/README.md:85-86`). The analysed record runs from a 30 mm reading to a 100 mm reading; how filming start relates to it is a placeholder |
| C7 | "Keep using the transit-time method where discharge is quoted" survives in a retracted section | `doc/piv_conditions.md:148` vs `doc/settled_and_retracted.md:42` | Retracted; ignore the stale sentence |
| C8 | Largest gauge deviation, inflow: recorded -9 to -11 mm; cross-check -10.0 to -12.2 mm | `doc/qdip_jet_check.md:37` vs arithmetic in this task | Differ by about 1 mm (probably smoothing or definition, not recorded). Say "about 10 mm" |
| C9 | Reading-change counts: "falls to 5-15 per minute" vs "10-23 per minute during the stall" | `doc/qdip_jet_check.md:23` vs `:183` | Different dates and windows, definitions not recorded. Use section 0 figures; method is a GAP |
| C10 | Old manuscript statements contradicted by settled facts: discharge set by valve opening; "actual discharge deviates from nominal with depth and submergence"; "each run started from still water" | old `sections/methods.tex:9`, `:21`, `:51` vs `doc/settled_and_retracted.md:16`, `:30`, `:48` | Do not carry over |
| C11 | Cause of the artefact: the index says the gauge misreads (and names bubbles and surface agitation); the authoritative file says gauge error and basin-side storage are not separated and would revert the axis if storage were shown | `doc/settled_and_retracted.md:17`, `:19`, `:41` vs `doc/qdip_jet_check.md:42-43`, `:103`, `:250-252`; later argument against storage in `cfd/campaign.md:260-263` | State that the port discharge did not drop; attribute the artefact to the gauge reading with the hedge the sources carry; do not state a physical mechanism as established |
| C12 | Verdict is worded for "each run", and the time-proportional axis is applied to all 24 runs, but the PIV test covers inflow only, the gauge-behaviour ground is stated for the 12 inflow runs, the mode of the lower-reservoir measurement is unrecorded, and outflow steadiness is listed as still to confirm | `doc/settled_and_retracted.md:16`, `:20` vs `doc/qdip_jet_check.md:15-23`, `:110-111`; `cfd/campaign.md:274` | Do not claim that outflow steadiness was verified; placeholder or explicit assumption |
| C13 | Nominal discharge and nominal rise rate match only with the nominal plan area: 2.5 mm/min x 6.0 m^2 = 0.250 L/s, but x 5.7918 m^2 = 0.241 L/s (likewise 0.483, 0.724) | `metadata/flow_levels.csv:2-4`; `config/constants.m:16-24`, arithmetic in this task | Corrected by audit: `metadata/README.md:75` records that the nominal discharge is derived from the plan area and the nominal rise rate, so the rise rate is the primary design value and the L/s label follows from the nominal 6.0 m^2. What the pump frequency was actually tuned to is still not recorded. Give one nominal label and do not present the pair as equivalent |
| C14 | beta range "-0.05 to -0.17" mixes the two statistics (core -0.07 to -0.17; frame_max -0.05 to -0.13) | `doc/qdip_jet_check.md:15`, `:152-158` | Say which statistic, or give the range as covering both |
| C15 (added by audit) | Share of I_unst that is within-band trend, inflow B1: "65-75%" vs "5-8 割" (50-80%). The first is not consistent with the figures beside it (0.35-0.40 -> 0.09-0.19). Audit recomputation with a linear detrend in time on the gauge-axis B1 frames gives level means 0.354 / 0.399 / 0.385 -> 0.085 / 0.130 / 0.190, i.e. 76% / 67% / 51% (low / medium / high) | `doc/qdip_jet_check.md:95` vs `doc/settled_and_retracted.md:21`, `paper/README.md:57`; `local/derived/metrics/R0001..R0012/frame_metrics.csv`, arithmetic in the audit | Outside Methods 2.3. If a figure is needed, use the wider recorded one (50-80%) or a placeholder; "65-75%" covers the low and medium levels only |
| C16 (added by audit) | Old manuscript: every frame was assigned to a depth band and none fell outside. Current files: 85 frames in R0005, R0009 and R0011 lie outside all bands on the gauge axis (section 6b) | old `sections/results.tex:21` vs `local/derived/metrics/R0005,R0009,R0011/frame_metrics.csv` | Do not carry the sentence over. On the time-proportional axis it would hold by construction |
| C17 (added by audit) | Stale notes in the metadata documentation: actual discharge "may deviate from the nominal value depending on water depth and the degree of port submergence" and should be evaluated "for each representative depth band" | `metadata/README.md:76-77`, `:94` vs `doc/settled_and_retracted.md:16-17`, `:42` | Retracted content; do not carry over. Only the statement that discharge is evaluated from the level record of each run survives, as the run average |

## What the Methods may state

Claim level only; the wording is the writer's. Every item is backed by the rows cited.

1. Discharge was set by the pump frequency at three nominal levels (0.25, 0.50, 0.75 L/s); the nominal values are targets, not measurements. (section 1)
2. Water depth in the basin was recorded by a 60 GHz radar level gauge (KEYENCE FR-S01) mounted by the wall facing the port, lens about 0.50 m above the floor, 0.40-0.47 m from the water surface, logged in 1 mm steps. (section 4)
3. The discharge of each run is quoted as the run average Q = A abs(dh) / T over the recorded interval, with A = 5.7918 m^2, abs(dh) = 70 mm (readings of 30 mm and 100 mm) and T the duration of the record. (section 1)
4. Run averages were 0.75-0.89 of nominal for inflow and 0.78-1.00 for outflow; inflow medians 0.219 / 0.392 / 0.623 L/s. These are relative to an unverified gauge span and must carry that caveat. (sections 1, 8)
5. The discharge obtained by differentiating the level record shows, in every inflow run, a dip to about 0.35 of nominal at h about 44-50 mm (h/a about 0.85), at the same depth for all three levels; outflow shows a shallower, broader feature (about 0.7, h/a about 0.8-1.0). (section 5)
6. The dip was tested against the surface speed of the port jet from PIV (x = 0.19-0.52 m, 5 s block means, maximum over y averaged over x) in five inflow runs (one low, four medium): the log-log slope of jet speed on level-derived discharge over h = 35-62 mm was -0.05 to -0.17 with upper 95% bounds at most +0.03 (moving-block bootstrap), against +0.8 to +1.1 expected if the dip were real; the same proxy scaled with discharge between flow levels with exponent 0.82-1.11 (0.84 in the dip window). (section 2)
7. The limitation of item 6 must accompany it: five of twelve inflow runs, no high-level run, sensitivity calibrated on one low run, surface only. (section 2)
8. The lower-reservoir level was reported to change at a constant rate while the upper-basin reading fluctuated. Details are placeholders. (section 3)
9. The dip coincides, in all twelve inflow runs, with the depth at which the rate of change of the gauge reading falls from 15-50 to 5-15 changes per minute, and that rate stays low after the level-derived discharge recovers. (section 4)
10. The ratios of discharge between levels are preserved at every depth (high/low 2.8-3.4, medium/low 1.8-2.3). (sections 1, 5)
11. On these grounds the discharge is treated as steady within each run, and depth-resolved discharge from the level record is not used. For outflow this is an assumption not separately verified. (sections 1, 8; C12)
12. Because steady discharge and constant plan area imply a level proportional to time, depth is assigned to each PIV frame by the straight line between the first and last readings of the record (30 mm and 100 mm) in normalized frame time; this time-proportional depth is the primary axis and the gauge depth is kept as a sensitivity check. (section 6a)
13. The gauge reading departs from that line by up to about 10 mm near h/a about 1 in inflow (-9 to -11 mm at readings of 50-59 mm) and by -4 to -6 mm in outflow (readings of 53-67 mm); 31-39% (inflow) and 10-18% (outflow) of the record changes band. Audit: "near h/a about 1" is in terms of the gauge reading; where the offset is largest the time-proportional depth is 61-71 mm (inflow), so on the primary axis the location must be given as a gauge reading or left out. (section 6c)
14. Both axes share the same end readings; the absolute level and hence the absolute discharge are not independently verified. (sections 6a, 8)
15. Depth bands: B1 0.030-0.050 m, B2 0.050-0.060 m, B3 0.060-0.075 m, B4 0.075-0.100 m (h/a 0.55-0.91, 0.91-1.09, 1.09-1.36, 1.36-1.82), lower edge inclusive. Do not add that every frame fell inside a band on the gauge axis (C16). (section 6b)
16. Sensitivity to the axis may be summarized qualitatively (branch signs unchanged in 12/12 runs; trends unchanged; band values shift), with the numbers of sections 6d-6e flagged as provisional until s31 is extended. The ranges of section 6e are ranges of the three level means, not of the 12 runs (audit note in 6e). (sections 6d, 6e, 7)

## What must not be stated

1. Any band-wise or depth-resolved discharge derived from the level record as a physical quantity: `q_actual_Lps` (s31, 20 s moving mean then A x abs(dh/dt)), `Q_transit_Lps` (band volume over band transit time), or figures such as "B1 0.29 -> B4 0.57 L/s" and "B1 0.49 -> B4 0.83 L/s". (`doc/settled_and_retracted.md:17`, `:40`; `src/metrics/compute_actual_discharge.m:7-12`, `:46-52`; `src/metrics/compute_branch_statistics.m:35-36`, `:47-52`; `doc/piv_conditions.md:133`)
2. The transit-time method as the way discharge is obtained or quoted. (`doc/settled_and_retracted.md:42`)
3. That discharge varies with depth, with submergence, or ramps during a run; that the dip is a real change of discharge; that it cannot be told apart from sensor error; that the dip is depth-controlled alike in inflow and outflow. (`doc/settled_and_retracted.md:40-41`, `:47`; `doc/piv_conditions.md:122-124`, `:140`)
4. That normalization uses a band-wise measured discharge. (`doc/settled_and_retracted.md:43`; `doc/metrics_primer.md:217`)
5. An ultrasonic level sensor. (`doc/settled_and_retracted.md:44`)
6. Discharge set by valve opening; a start from still water. (`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:163-165`; `doc/settled_and_retracted.md:30`, `:48`; `paper/README.md:87`)
7. The nominal plan area 3.0 m x 2.0 m (6.0 m^2) in any discharge or normalization. (`doc/settled_and_retracted.md:25`)
8. Any CFD figure or number, including the constant-discharge CFD reference used in the jet check. (`paper/README.md:17-18`, `:92`; `doc/qdip_jet_check.md:145-146`, `:164-167`)
9. That the jet test covered all inflow runs, any high-level run, or outflow. (`doc/qdip_jet_check.md:241-242`, `:228-229`)
10. Any detail of the lower-reservoir measurement (mode, level, instrument, plan area, interval covered, degree of constancy), or that it covered the dip interval. (`doc/qdip_jet_check.md:18-19`)
11. That the absolute discharge or the absolute level has been verified. (`doc/settled_and_retracted.md:23`)
12. A physical mechanism of the gauge misreading (bubbles, spray, wall reflection) as an established fact. (`doc/qdip_jet_check.md:22-26`, `:42-43`)
13. Band values on the time-proportional axis as final, or gauge-axis band values as if they were on the primary axis. (`paper/README.md:63`, `:167-168`; section 7)
14. A PIV-based verdict on the deep-water rise of the level-derived discharge, or a numerical range for the deep-water over-read. (C3, C4)
15. That outflow discharge was verified to be steady. (`doc/qdip_jet_check.md:110-111`)

## Gaps

Leave `\PH{...}`; do not search for or estimate these.

1. Lower-reservoir measurement: mode, flow level(s), number of runs, instrument, plan area of the lower reservoir, whether the upper-basin interval 40-60 mm was covered, and how constant the rate was. (`doc/qdip_jet_check.md:18-19`; `paper/README.md:89`)
2. Verification of the gauge span (true depth at the 30 mm and 100 mm readings) and hence the absolute discharge. (`doc/settled_and_retracted.md:23`, `:55`)
3. Steadiness of the outflow discharge, and what drives the drainage. (`doc/qdip_jet_check.md:110-111`)
4. Start of recording relative to the level: 20 mm or 30 mm; the level at which filling began; whether outflow started from still water at 100 mm. (`paper/README.md:85-87`; C6)
5. Jet check for R0002-R0004 and R0009-R0012; a sensitivity n that includes the high level. (`doc/qdip_jet_check.md:241-242`, `:254-256`)
6. Method behind the reading-change counts (counting window, rule), and the logger sampling interval. (section 4)
7. Gauge details beyond model and frequency: exact position (distance from the wall, lateral position), averaging or response setting, zero reference. (section 4)
8. Time-proportional depth in the pipeline: s31 option, per-run per-band values and figures on the primary axis. (section 7)
9. Deep-water over-read as a number (two recorded ranges disagree; neither is in the authoritative file). (C3)
10. Cause of the gauge artefact; gauge error vs basin-side storage by a direct test (static calibration). (C11)
11. Plan area of the feed channel below h = a (the 1% figure rests on an assumed footprint). (section 1)
12. What the pump frequency was tuned to: the discharge label or the rise rate. The label itself is derived from the rise rate (`metadata/README.md:75`). (C13)
13. Per-run run-average discharge for outflow as an authoritative table (only the range 0.78-1.00 of nominal is recorded). (section 1)
14. Whether any direct flow measurement existed on the supply line. (section 1)
15. Water temperature (affects only derived numbers, not this subsection). (`paper/README.md:90`)

## Audit (second reader)

Independent audit, 2026-11-22. Every cited file was opened at the cited lines; the numbers marked
"computed" were recomputed with python3 from the CSV files named in the rows. No source file was
edited and nothing was re-run that writes output (`qdip_jet_check.py` itself was not re-run; its
recorded CSV outputs were read).

### Result

All 178 table rows of sections 1-9 were compared with the lines they cite, and the 46 list items were
compared with the rows they rest on. No statement was found that its cited source does not support,
no retracted statement of `doc/settled_and_retracted.md` section 2 is carried as valid, and no CFD
number is carried (the constant-discharge CFD reference is listed only as "do not use"). One rounding error, one one-sided quotation and one "not recorded" that a cited file
does record (C13) were corrected, and five points that the sources leave implicit were added because
a manuscript sentence could go wrong on them.

### What was changed

1. Section 6c, inflow cross-check: "band changes for 32-38% of frames" -> 31.8-37.5% (32-37%).
2. Section 6e, last row, and new C15: the trend share of I_unst was carried as "65-75%" only. The
   index and the writing agreement say 50-80%, and the recomputation gives 76% / 67% / 51%. Both
   recorded figures are now shown and the percentage is marked unverified.
3. Section 6e, note under the heading, and "may state" item 16: the ranges are ranges of the three
   flow-level means, not of the 12 runs. Established by recomputation (below).
4. Section 6e, outflow row: SNR 2.1 -> 3.1 is the mean of the four high runs; per run only R0021
   exceeds 3 on the time-proportional axis.
5. Section 6c, two new rows, and "may state" item 13: where the gauge deviation is largest the
   time-proportional depth is 61-71 mm (inflow), so "near h/a about 1" holds for the gauge reading
   only; and the reading lies above the line early in the record.
6. Section 6b, new row, new C16 and "may state" item 15: 85 frames in three inflow runs are outside
   all bands on the gauge axis; the old manuscript says none are.
7. Section 6a, formula row: status extended with "reproduced by audit".
8. Section 1 (new row), C13 and gap 12: the nominal discharge is documented as derived from the
   nominal rise rate and the plan area (`metadata/README.md:75`); the sheet had this as not recorded.
9. New C17: stale notes in `metadata/README.md:76-77`, `:94` repeat retracted content.

### Recomputed and confirmed

| item | recorded in the sheet | audit recomputation | source of the recomputation |
|---|---|---|---|
| End readings, 24 runs | 30.0 / 100.0 mm (inflow), 100.0 / 30.0 mm (outflow) | same | `local/derived/metrics/R00xx/frame_metrics.csv` |
| Inflow run averages, 12 runs | 0.218 ... 0.597 L/s | identical to three decimals | `local/derived/metrics/branch_stats.csv` |
| Level medians and means | 0.219 / 0.392 / 0.623; 0.217 / 0.390 / 0.619 | 0.2188 / 0.3921 / 0.6233; 0.2168 / 0.3904 / 0.6193 | same |
| Ratio to nominal, inflow | 0.83-0.89, 0.75-0.81, 0.80-0.84 | 0.828-0.891, 0.745-0.809, 0.796-0.845 | same |
| Outflow run averages | 0.195-0.249, 0.434-0.450, 0.681-0.701 L/s; 0.78-1.00 of nominal | 0.1951-0.2492, 0.4336-0.4500, 0.6811-0.7011; 0.781-0.997 | `frame_metrics.csv`, R0013-R0024 |
| beta, intervals, Q_level swing, block counts | section 2c | identical after rounding | `local/derived/qc/qdip_jet_check/run_summary.csv` |
| Sensitivity n | 0.82 / 1.03 / 0.84 / 0.99 / 0.98 / 1.11 | 0.821 / 1.032 / 0.843 / 0.986 / 0.983 / 1.108 | `.../calibration.csv` |
| dip/ref of the proxy, W1-W4 | 0.92-1.24, 0.90-1.14, 0.91-1.85; 0.58-1.54; 0.52-0.96, 0.38-0.82 | same | `.../window_ratios.csv` |
| Valid fraction, jet axis, length difference | 0.92-0.94 / 0.97-0.98; 0.73-1.31 / 0.93-1.07; 6.2 s | 0.917-0.938 / 0.972-0.981; 0.730-1.309 / 0.933-1.067; -6.2 s | `.../run_summary.csv` |
| Inflow dip cross-check | 0.33-0.43 of nominal, 0.40-0.53 of the run average | 0.326-0.429, 0.397-0.532 | `frame_metrics.csv`, dwell time at readings 44-49 mm |
| Outflow feature cross-check | 0.61-0.85 of nominal | 0.615-0.852 | same, readings 44-55 mm |
| Deep-water cross-check | inflow 1.35-1.59 (R0006 1.59, others up to 1.48), outflow 1.15-1.33 | 1.348-1.586, 1.152-1.328 | same, readings 77-94 mm |
| Gauge deviation, inflow / outflow | -10.0 to -12.2 mm at 50-60 mm; -4.5 to -6.5 mm at 53-68 mm | -10.05 to -12.21; -4.48 to -6.47, same readings | `frame_metrics.csv` |
| Band change, outflow; B2 on the line | 9-18%; 50-71 mm, 50-65 mm | 8.9-17.6%; 49.9-70.9, 49.8-65.1 | same |
| Ratios between levels at every depth | high/low 2.8-3.4, medium/low 1.8-2.3 | 2.76-3.43, 1.75-2.30 (level means of dwell-time discharge in B1-B4 and 44-50 mm, inflow and outflow) | same |
| Feed channel, linearity, C13, quantization | about 0.2 mm; 0.241 / 0.483 / 0.724 L/s; 1.4% | 0.18 mm; 0.2413 / 0.4827 / 0.7240; 1.43% | arithmetic |
| Gauge-axis band means | reproduce `band_metrics.csv` | largest relative difference 4.4e-15 over all runs and bands | `frame_metrics.csv` vs `band_metrics.csv` |
| Impact assessment, branch statistics | signs unchanged; medians 3.6 / 8.7 / 11.8 -> 3.0 / 7.3 / 10.7; persistence 10/12 -> 9/12 | signs unchanged; 3.60 / 8.70 / 11.76 -> 3.02 / 7.27 / 10.73; 10 -> 9 with R0003 0.972, R0007 0.970 -> 0.896, R0002 0.826 -> 0.817 | `frame_metrics.csv`, formula of section 6a |
| Impact assessment, band values (level means) | section 6e | E ratio B1/B4 2.63-4.36 -> 2.95-4.90; E in B2 +23.1 to +44.6%; phi_lv 0.376 -> 0.584, 0.365 -> 0.576, 0.222 -> 0.461 becomes 0.342 -> 0.582, 0.336 -> 0.572, 0.210 -> 0.452; I_rot B1 0.095-0.123 -> 0.103-0.134; I_asym 0.219-0.296 -> 0.188-0.298; I_unst B1 0.354-0.399 -> 0.276-0.326, B2 0.077-0.134 -> 0.086-0.202, B3/B4 0.030-0.050 -> 0.045-0.100; frames B1 -24.7 to -27.2%, B2 -14.8 to -19.0%, B3 +13.5 to +16.6%, B4 +39.5 to +44.3% | same |
| B1 sign opposite to the deep-water sign | R0002, R0003, R0007; R0007 B1 I_circ +0.00027 | same three runs on both axes; +0.00027 on the gauge axis | same |
| Gauge model | KEYENCE FR-S01 | the header of the R0001 logger file names "FR-S01" | `local/raw/R0001/waterlevel.csv`, line 1 |

The recomputed frame-count changes agree with the recorded ones to within one percentage point
(B3 +13.5 to +16.6% against the recorded +14 to +16%); the recorded figures were left as they are.

### Not verified by audit

These rows match the cited source line, but the number behind them could not be recomputed. They
stay in the sheet as recorded; treat them as "unverified by audit".

1. Reading-change counts of the gauge (15-50 -> 5-15 per minute in all 12 inflow runs; 10-23 per
   minute during the stall). No script and no definition exists (already a GAP in section 4).
2. Recorded gauge deviation "-9 to -11 mm" and band-change share "31-39%" for inflow. The
   per-frame recomputation gives -10.0 to -12.2 mm and 31.8-37.5%; the definition behind the
   recorded figures (smoothing, time base) is not written down (C8). The outflow figures agree
   within rounding (-4.5 to -6.5 mm and 8.9-17.6% against the recorded -4 to -6 mm and 10-18%).
3. Location of the sharp fall in unsteadiness (h/a 0.98 vs 1.05) and the outflow depth at which the
   surface flow strengthens (50 mm vs 53 mm, 10 runs): the statistics are not defined in the source.
4. "Missing volume" 14-117 L and 1-33 L; duration of the dip 140-490 s; jet travel time 10-17 s.
5. Everything about the lower-reservoir measurement (nothing is recorded beyond the two sentences).
6. Lens height, distance to the surface and the +-1 mm specification of the gauge (taken from the
   two project documents; not compared with a manufacturer sheet or a drawing).
7. PIV filter settings and the R0005 speed distribution (the `.mat` files were not opened).
8. The absence claims (no direct flow measurement, no logger sampling interval on record). A search
   of the repository for a flow meter found none, which supports but cannot prove the first.
   Incidentally, the R0001 logger file has about 5980 rows over 1860 s, about 0.31 s per row; this is
   one file, it was not checked for the other runs, and the GAP stays.

### For the user to decide

- C11 stands as the sheet has it. The index (2026-11-14) records the gauge misreading as settled,
  while section 0 of the authoritative file (2026-10-26) still says that gauge error and
  basin-side storage are not separated and that the axis reverts if storage is shown. The one
  recorded argument against storage quotes a PIV slope for the deep water (C4) that the
  authoritative file says cannot be judged. The hedged wording is therefore the safe reading; a
  static calibration would close it.

# Evidence sheet -- Methods 2.6 "Branch identification and statistical tests"

Prepared 2026-11-22 for the JHR manuscript (paper 1). Evidence only; no manuscript text.

- Paths are relative to the repository root. `local/` is the gitignored, machine-local data root
  (this Mac); files under it are not in Git and may differ on the lab workstation (WS).
- Line numbers refer to the working tree on 2026-11-22 (HEAD b8295ed). `doc/settled_and_retracted.md`
  and `cfd/campaign.md` had uncommitted edits at that time, so their line numbers can shift. All
  other files cited were unmodified relative to HEAD.
- `cfd/campaign.md` is cited only for experimental facts recorded there. No CFD result is carried
  into this sheet.
- "old manuscript" = `paper/2026_journal_Shonai/sections/*.tex` (frozen source material, may be stale).
- Status vocabulary: **settled** (recorded as settled in the authoritative file), **user-confirmed**,
  **computed** (repo code, output of a repo script run in this task, or arithmetic done in this task
  on an existing file -- the row says which), **unverified** (recorded but not checked,
  non-authoritative, or contradicted elsewhere), **GAP** (not recorded; leave a `\PH{...}`).
- Rows marked "arithmetic in this task" were obtained with one-off python on the file named in the
  row (scratch scripts, not repo tools; their output is in Appendix B and C). They are cross-checks,
  not new results. Quote the recorded value, not the cross-check.
- Formulas are plain ASCII. `abs(x)` is written instead of vertical bars, `<w>` is the area mean
  over the analysis domain, `mean_t` / `std_t` are taken over frames.

**Read this first.**

1. **Depth axis.** Every number in this sheet that involves depth bands (branch sign, mean and s.d.
   of I_circ, R_lock, sign persistence, the energy-side index, the by-band jet offsets, frame counts)
   is computed on the **gauge** depth axis, because `band_id` in `frame_metrics.csv` is the gauge
   band. The time-proportional axis (primary since 2026-11-22) is not implemented in `s31`. On that
   axis the branch signs are unchanged in 12/12 runs, but the R_lock level medians move from
   3.6 / 8.7 / 11.8 to 3.0 / 7.3 / 10.7 (section 9). Methods 2.6 defines the quantities and need
   not quote these values.
2. **Jet offset.** Available for five runs only: R0001 (low) and R0005-R0008 (medium). No high run
   and three of the four low runs are missing (section 5d).
3. **Tests.** The three p-values come from sign patterns that are hard-coded in the check script;
   they use the signs only and therefore do not depend on the depth axis (section 6).
4. **Normalization.** I_circ in every file is normalized with the **nominal** discharge of the
   level, not with the run-average discharge (section 1). Sign, R_lock and sign persistence are
   unaffected; the tabulated mean and s.d. of I_circ are not.

## 1. Branch sign

| fact | value | source (file:line) | status |
|---|---|---|---|
| Quantity that is summarized | I_circ(t) = (a / U_p) * <omega>(t), with omega = dv/dx - du/dy (vertical vorticity of the surface field) and <.> the mean over the finite cells of the analysis domain | `src/metrics/compute_frame_metrics_circ.m:4-11`, `:91-98` | computed (repo code) |
| a | Port height, 0.055 m | `config/constants.m:45`; `scripts/s30_compute_metrics.m:56` | settled |
| U_p as implemented | U_p = Q_nominal / (a b), Q_nominal = 0.25 / 0.50 / 0.75 L/s for low / medium / high, b = 0.11 m. One constant per run. The code takes Q_nominal from the `nominal_Q_Lps` column of `metadata/runs.csv` (through `read_runs_table`), which repeats the level values of `metadata/flow_levels.csv` | `scripts/s30_compute_metrics.m:47-59`; `metadata/runs.csv:3-14` (`nominal_Q_Lps`); `metadata/flow_levels.csv:2-4`; `config/constants.m:44`; `doc/metrics_primer.md:23-25` | computed (repo code); source file corrected by audit |
| a / U_p actually applied | 1.3310 s (low), 0.6655 s (medium), 0.4437 s (high); constant within each run | `local/derived/metrics/R00xx/frame_metrics.csv` (ratio of columns `I_circ` and `omega_mean`), arithmetic in this task (Appendix B) | computed |
| Differentiation | Central differences on the PIV vector grid (one-sided at the grid edges); no smoothing before differentiation (`smooth_sigma_circ` = 0) | `src/metrics/compute_frame_metrics_circ.m:88-93`; `config/metrics_defaults.m:27-31`; `doc/metrics_primer.md:90` | computed (repo code) |
| Analysis domain | The whole PIV vector grid: 92 x 61 vectors, spacing 31.5 mm, x = 0.045-2.909 m, y = 0.041-1.929 m | `config/constants.m:106-115`; `doc/piv_conditions.md:44-48` | settled |
| Branch sign | s = sign( mean_t I_circ(t) ), mean over the pooled frames of bands B3 and B4; +1 or -1 (NaN if the mean is exactly zero) | `src/metrics/compute_branch_statistics.m:34`, `:107-116`, `:132` | computed (repo code) |
| Pooling rule | All frames whose `band_id` is B3 or B4 and whose I_circ is finite form one sample (frames are pooled; band means are not averaged). A run with fewer than two such frames is skipped | `src/metrics/compute_branch_statistics.m:107-111`; `paper/README.md:123` | computed (repo code) |
| Bands | B3: 0.060 <= h < 0.075 m (h/a 1.09-1.36); B4: 0.075 <= h <= 0.100 m (h/a 1.36-1.82). Half-open intervals, the deepest band closed at the top | `metadata/depth_bands.csv:4-5`; `src/metrics/assign_depth_bands.m:51-65` | settled |
| Depth of a frame as implemented | Gauge reading interpolated to the frame through normalized time (logger and video are treated as co-extensive records) | `src/metrics/assign_depth_bands.m:21-28`, `:38-48` | computed (repo code); gauge axis |
| Runs | The 12 inflow runs R0001-R0012: 4 days x 3 levels, one run per level per day (dates 20260416, 20260420, 20260421, 20260422) | `metadata/runs.csv:3-14`; `src/metrics/compute_branch_statistics.m:77-83`; `scripts/s40_make_paper_figures.m:152-153` | settled |
| Frames pooled per run | 3910-4777 (gauge axis) | `local/derived/metrics/branch_stats.csv:2-13` (`n_frames`) | computed (repo code) |
| Frame interval | 0.2002 s (low), 0.1001 s (medium), 0.0667 s (high): the image-pair interval was chosen so that interval x nominal discharge is the same for the three levels | `doc/piv_conditions.md:160-169`; `frame_metrics.csv` (`time_s`), arithmetic in this task | settled |
| Length of the pooled window | Gauge axis: 787-865 s (low), 446-478 s (medium), 283-303 s (high), i.e. about the last 42-45% of each record. Time-proportional axis: h = 60-100 mm is the last 40/70 = 57% of each record by construction | `frame_metrics.csv` (`time_s`, `band_id`), arithmetic in this task (Appendix B) | computed (cross-check) |
| Why the sign is kept per run | With spontaneous left-right symmetry breaking the sign is an outcome of each run (which branch it fell onto); averaging signed I_circ over replicates on opposite branches cancels to about zero | `src/metrics/compute_branch_statistics.m:4-9`; `doc/metrics_primer.md:139-147`, `:184-189`; `scripts/s40_make_paper_figures.m:11-14` | settled |
| Why the shallow bands (B1, B2) are excluded, as recorded | In the shallow bands the jet is exposed at the free surface and meanders, which weakens the lock for reasons unrelated to branch selection. B3 and B4 (h/a > 1.09) have the jet fully submerged and the flow quasi-steady | `src/metrics/compute_branch_statistics.m:11-15`; `doc/metrics_primer.md:171-173`; `paper/README.md:123-125`; old manuscript `sections/methods.tex:221`, `:234` | settled as a rule; the supporting phrase "I_unst an order of magnitude larger" is stale (section 11, C7) |
| Observation behind the exclusion | In B1, three runs have a band-mean I_circ of the opposite sign to their deep-band sign: R0002 (-0.00056) and R0003 (-0.00079), both low, and R0007 (+0.00027), medium. In B2-B4 no run differs from its deep-band sign on the gauge axis. The B1 statement is recorded as holding on both depth axes. Audit cross-check on the time-proportional axis (same recipe as section 9): B1 has the same three exceptions (R0002 -0.00060, R0003 -0.00120, R0007 +0.00064), but B2 is NOT free of exceptions there: R0002 -0.00031 (opposite to its positive branch) and R0003 -0.000001 (zero to the precision of the data); B3 and B4 have none | `doc/qdip_jet_check.md:89-93`; gauge-axis values from `local/derived/metrics/band_metrics.csv` (`I_circ_mean`), arithmetic in this task; time-proportional values from `frame_metrics.csv`, arithmetic in the audit | computed (gauge axis); time-proportional values are a cross-check, not from a repo tool (corrected by audit: "no exception in B2-B4" holds on the gauge axis only) |
| Sign convention in the code | Positive I_circ = net counterclockwise rotation in the coordinate system (piv.x to the right, piv.y increasing). The header warns that if piv.y increases downward in the image, positive is clockwise in physical y-up space | `src/metrics/compute_frame_metrics_circ.m:19-22` | computed (repo code) |
| Convention used for the paper figure | I_circ > 0 is counterclockwise in the (x to the right, y upward) analysis frame of the band-mean field figures, i.e. the jet attached to the sidewall on the y < y_port side | `scripts/s40_make_paper_figures.m:147-150`; `src/viz/plot_band_mean_fields.m:39` (figures drawn with y upward); old manuscript `sections/methods.tex:223` | computed (repo code) |
| Frame | x along the basin length measured from the port wall (the grid starts 0.045 m off the port wall), y across the basin, z upward; the port is at the centre of the short side wall; port axis y = 0.981 m = L_y / 2 (L_y = 1.962 m) | `AGENTS.md:106-109`; `config/constants.m:21-22`, `:106-109`; `src/metrics/compute_frame_metrics_basic.m:18-20`; `scripts/checks/jet_offset_by_band.py:9` | settled |
| Check against the jet offset | In the five runs with PIV fields the deep-band jet offset has the sign opposite to I_circ: positive branch R0001 and R0008, offset -0.38 to -0.43 m (toward small y); negative branch R0005 and R0006, offset +0.42 to +0.44 m; R0007 (negative, weak) +0.06 to +0.12 m | Appendix A2 (`scripts/checks/jet_offset_by_band.py`) with `branch_stats.csv:2`, `:6-9` | computed (repo script, this task) |
| Check against the energy side | The energy-side index (section 4; positive = more energy at small y) has the sign of I_circ in 12/12 runs | Appendix A1; `scripts/checks/branch_sign_tests.py:25` | computed (repo script, this task) |
| Physical meaning, as far as the sources go | Positive branch: jet deflected toward, and attached to, the sidewall at small y (y < 0.981 m); net basin circulation counterclockwise in the (x right, y up) analysis frame. Negative branch: the mirror state | rows above | computed |
| Sense as seen from above in the laboratory; which physical sidewall is y = 0 | Not recorded. `compute_frame_metrics_basic.m` calls the small-y half the "upper image half", so the y-up figure frame may be a mirror image of the camera view | `src/metrics/compute_frame_metrics_basic.m:20-21`; `src/metrics/compute_frame_metrics_circ.m:21-22` | GAP |
| Size of the net circulation | Band-mean abs(I_circ) is at most 0.013 in all inflow runs and bands (maximum 0.0131: R0010, B1). The old manuscript adds "that is, one tenth of I_rot or less in the same condition"; that part is NOT reproduced. Band-mean abs(I_circ) / I_rot, run by run and band by band, is 0.003-0.177 and exceeds 0.10 in 24 of the 48 run-band cells (17 of the 24 cells of B3 and B4; largest 0.177: R0005, B4), because I_rot falls from 0.092-0.128 in B1 to 0.053-0.069 in B4 while abs(I_circ) does not fall. Interpretation as recorded: the main circulation of the deflected jet and the recirculation on the other side largely cancel in the signed area mean | old manuscript `sections/results.tex:58`; `local/derived/metrics/band_metrics.csv` (`I_circ_mean`, `I_rot_mean`), arithmetic in this task (maximum) and in the audit (ratio) | computed (gauge axis, nominal normalization) for the 0.013 bound; the "one tenth of I_rot" wording is stale and contradicted by `band_metrics.csv` (corrected by audit) -- do not reuse it |

## 2. Lock strength R_lock

| fact | value | source (file:line) | status |
|---|---|---|---|
| Definition | R_lock = abs( mean_t I_circ(t) ) / std_t I_circ(t), over the same pooled frames as the branch sign | `src/metrics/compute_branch_statistics.m:32`, `:113-114`, `:130`; `doc/metrics_primer.md:165` | computed (repo code) |
| s.d. normalization | MATLAB `std(ic)` with the default weighting: sample standard deviation, divisor N - 1. No detrending and no temporal filtering | `src/metrics/compute_branch_statistics.m:114` | computed (repo code) |
| N - 1 versus N | Immaterial at N of about 4000-4800: e.g. R0001 4.2211 (N - 1) versus 4.2217 (N) | `frame_metrics.csv`, arithmetic in this task (Appendix B) | computed (cross-check) |
| What it is not | It is abs(mean) / s.d., not abs(mean) / (s.d. / sqrt(N)); it is a descriptive ratio (the inverse of a coefficient of variation), not a test statistic | `src/metrics/compute_branch_statistics.m:113-130` | computed (repo code) |
| Meaning as recorded | How clearly the mean net circulation stands off zero relative to its fluctuation in time; larger means the branch is held more firmly ("stability from the amplitude side") | old manuscript `sections/methods.tex:231-232`; `doc/metrics_primer.md:165` | settled |
| Rule of thumb | abs(mean)/s.d. larger than about 5 with almost no sign reversal = steady circulation locked on one side; small with many reversals = meandering or undecided | `doc/metrics_primer.md:149-155` | unverified (a reading aid, not a fixed threshold) |
| Independence from the discharge used for normalization | Within a run a / U_p is one positive constant c (U_p is set once per run). With w(t) = <omega>(t): mean_t(c w) = c mean_t(w) and std_t(c w) = c std_t(w), hence R_lock = abs(mean_t w) / std_t w. c cancels, so R_lock is the same whether U_p is built from the nominal or from the run-average discharge. The branch sign and the sign persistence are unchanged for the same reason (c > 0) | `scripts/s30_compute_metrics.m:58-59`, `:77-81`; `src/metrics/compute_frame_metrics_circ.m:61`, `:98`; `paper/README.md:125-127`; `doc/settled_and_retracted.md:63-65` | settled |
| Numerical confirmation | R_lock computed from the raw column `omega_mean` (no normalization) equals R_lock from `I_circ` to four decimals in all 12 runs | `frame_metrics.csv`, arithmetic in this task (Appendix B, columns "R" and "R_from_omega") | computed (cross-check) |
| Do not confuse | "Independent of the discharge value used for normalization" is a property of the definition. The value of R_lock does differ between discharge levels (next rows) | `paper/README.md:121-127` | settled |
| Values, gauge axis | low 0.97-5.56, medium 1.91-10.30, high 6.65-13.20; level medians 3.60 / 8.70 / 11.76 (median of four = mean of the two middle runs) | `paper/README.md:121-122`; `local/derived/metrics/branch_stats.csv:2-13` (`R_lock`); `doc/metrics_primer.md:181-182` | computed (repo code) |
| Values, time-proportional axis | Level medians 3.0 / 7.3 / 10.7 | `doc/qdip_jet_check.md:67`; `cfd/campaign.md:173` | unverified in the repo sense (scratch computation); reproduced in section 9 |
| Relation to discharge (experiment only) | Level medians against the run-average discharge (0.219 / 0.392 / 0.623 L/s): exponent 1.13 from low to high, 0.65 from medium to high; replicate scatter is large | `cfd/campaign.md:157`, `:160-165`; `doc/settled_and_retracted.md:28`, `:45` | settled (gauge axis) |
| Standing among the metrics | R_lock, the branch sign and the sign persistence are a convention for reading the primary metric I_circ, fixed for all runs; they are not new primary metrics | old manuscript `sections/methods.tex:234`; `AGENTS.md:152-158` | unverified (old manuscript wording) |
| Notation | `\Rlock` (R with subscript lock) may be confused with the Reynolds number (upright sans-serif R); open in the conventions | `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:174-175`; `paper/2026_journal_Shonai/jhr/notation.tex:52-55` | settled (open notation issue) |

## 3. Sign persistence

| fact | value | source (file:line) | status |
|---|---|---|---|
| Definition | P_sign = (number of pooled frames with sign(I_circ(t)) equal to the branch sign) / (number of pooled frames); same frames as sections 1 and 2 | `src/metrics/compute_branch_statistics.m:33`, `:131` | computed (repo code) |
| Zeros | A frame with I_circ exactly 0 would count as not sharing the sign; no such frame occurs in the 12 runs | `src/metrics/compute_branch_statistics.m:131`; `frame_metrics.csv`, arithmetic in this task (Appendix B, "nzero") | computed |
| Meaning as recorded | Stability seen from the frequency of reversals, complementary to R_lock (amplitude) | old manuscript `sections/methods.tex:232`; `doc/metrics_primer.md:166` | settled |
| Values, gauge axis | 1.000 in 10 of 12 runs; R0002 (low) 0.826; R0007 (medium) 0.970 | `local/derived/metrics/branch_stats.csv:3`, `:8` (`sign_persistence`); `doc/qdip_jet_check.md:68` | computed (repo code) |
| Values, time-proportional axis | 1.000 in 9 of 12 runs; R0003 0.972, R0007 0.896, R0002 0.817 | `doc/qdip_jet_check.md:68` | unverified in the repo sense (scratch computation); reproduced in section 9 |
| Symbol | `\Psign` | `paper/2026_journal_Shonai/jhr/notation.tex:56` | settled |

## 4. Second branch indicator (energy side)

| fact | value | source (file:line) | status |
|---|---|---|---|
| Definition | S(t) = (E_left(t) - E_right(t)) / (E_left(t) + E_right(t)) for each frame; indicator = sign( mean_t S(t) ) over the frames of B3 and B4 with finite E_left, E_right and I_circ | `scripts/checks/branch_sign_tests.py:23-27` | computed (repo script) |
| Order of operations | Mean over frames of the per-frame ratio (not the ratio of time-mean energies) | `scripts/checks/branch_sign_tests.py:25`, `:27` | computed (repo script) |
| E_left, E_right | Mean of u^2 + v^2 over the valid vectors of each half of the analysis domain | `src/metrics/compute_frame_metrics_basic.m:117-125` | computed (repo code) |
| Which half is "left" | The half with y smaller than the mid-line: `leftMask = Y < yMid`, `rightMask = Y >= yMid`. So S > 0 means more energy on the small-y side | `src/metrics/compute_frame_metrics_basic.m:113-115`, `:20-22`; `scripts/checks/branch_sign_tests.py:25` | computed (repo code) |
| Mid-line | yMid = 0.5 * (min y + max y) of the vector grid = 0.9853 m (grid y = 0.0413-1.9293 m), which is the centre line of the rectified image, i.e. L_y / 2 = 0.981 m in true length (**corrected 2026-11-22**: the 4 mm is a coordinate artefact, not a physical offset; `scripts/checks/jet_offset_by_band.py` now uses this mid-line as its reference, which lowers all recorded offsets below by 0.004 m) | `src/metrics/compute_frame_metrics_basic.m:110-113`; `doc/piv_conditions.md:48`; `doc/metrics_primer.md:76` | computed |
| Centre row | The grid row at y = 0.9853 m, the row nearest the port axis, satisfies Y >= yMid and belongs to the "right" half: 30 rows on the left (y = 0.041-0.954 m), 31 on the right (y = 0.985-1.929 m) | `src/metrics/compute_frame_metrics_basic.m:114-115`; grid read from `local/work/R0007/pivlab_single.mat`, arithmetic in this task | computed (cross-check) |
| Relation to the primary metric | I_asym(t) = abs(E_left - E_right) / (E_left + E_right) is the unsigned primary metric; S is its signed version. S is not written by the MATLAB pipeline; it exists only in the check script | `src/metrics/compute_frame_metrics_basic.m:127-130`; `scripts/checks/branch_sign_tests.py:25`; `paper/2026_journal_Shonai/jhr/notation.tex:58` (`\Sside`) | computed |
| Agreement with the circulation sign | sign(mean S) = sign(mean I_circ) in 12/12 runs | Appendix A1; `paper/README.md:135` | computed (repo script, this task; gauge axis) |
| Values | mean S: low +0.201 to +0.353; medium -0.252 to -0.269 and +0.267 (R0008); high -0.231 to -0.254. Fraction of frames with the sign of the mean: 1.00 in all 12 runs (per-run values in section 7) | Appendix A1 | computed (repo script, this task; gauge axis) |
| Time-proportional axis | Agreement 12/12 as well; abs(mean S) 0.18-0.35 | `frame_metrics.csv`, arithmetic in this task (Appendix B, part D) | computed (cross-check, not a repo tool) |
| "Independent" | The script and the plan call it "a second, independent branch indicator". It is built from kinetic energy rather than vorticity, but from the same PIV fields and the same frames | `scripts/checks/branch_sign_tests.py:6-8`; `paper/README.md:135` | settled as a description; see referee point 9 |

## 5. Jet lateral offset

### 5a. Definition

| fact | value | source (file:line) | status |
|---|---|---|---|
| Definition | For each time block: y_j = sum_k w_k (y_k - y_port) / sum_k w_k, with w_k = ( max(ubar_k, 0) )^2, ubar_k = block mean of the streamwise velocity u at lateral grid point y_k of one x station, y_port = 0.981 m | `scripts/checks/jet_offset_by_band.py:15-27` | computed (repo script) |
| Name of the method | "Forward-momentum centroid": the centroid of the squared positive streamwise velocity across the basin width | `scripts/checks/jet_offset_by_band.py:8-10`; `cfd/campaign.md:403` | settled |
| x station | The grid column nearest to x = 1.0 m; on the present grid that column is x = 0.989 m | `scripts/checks/jet_offset_by_band.py:15`, `:20`; grid from `local/work/R0001/pivlab_single.mat`, arithmetic in this task (Appendix C) | computed |
| Lateral extent | All 61 grid points of the column, y = 0.041-1.929 m (spacing 31.5 mm) | `scripts/checks/jet_offset_by_band.py:17`, `:23-26`; `doc/piv_conditions.md:44-48` | computed |
| Block length | 20 s nominal = round(20 x frame rate) frames: 100 frames at 4.995 Hz (R0001) or 200 frames at 9.990 Hz (medium runs) = 20.02 s. Blocks do not overlap; trailing frames that do not fill a block are dropped | `scripts/checks/jet_offset_by_band.py:15`, `:18-19`, `:22-23`; Appendix C | computed |
| Averaging | Block mean ignoring missing vectors; a point with no valid vector in the block gets weight 0. The weight is the square of the block-mean velocity (not the block mean of the square) and negative (return) flow gets weight 0 | `scripts/checks/jet_offset_by_band.py:23-24` | computed (repo script) |
| Port-axis value | y_port = 0.981 m = L_y / 2 | `scripts/checks/jet_offset_by_band.py:9`, `:26`; `config/constants.m:22` | settled |
| Sign | Positive = centroid on the large-y side of the port axis. A positive offset goes with a negative I_circ (section 1) | `scripts/checks/jet_offset_by_band.py:26`; Appendix A2 | computed |
| Time stamp | Centre of the block, measured from the first PIV frame of the analysed sequence: 10, 30, 50, ... s. The gauge depth of that first frame is 30.0 mm in all 12 runs (`frame_metrics.csv`, `depth_m`) | `scripts/checks/jet_offset_by_band.py:25` | computed (repo script); that the first PIV frame is the start of the video recording is unverified by audit (`src/metrics/assign_depth_bands.m:27-28` mentions a head/tail video trim; see section 11, C13) |
| Band of a block | `band_id` of the frame at the block centre in `frame_metrics.csv` (gauge axis). The gauge depth is not monotone in time, so the band sequence of the blocks need not be either: in R0001 blocks labelled B1 occur up to t = 751 s although B2 starts at t = 731 s (Appendix A2) | `scripts/checks/jet_offset_by_band.py:31-34` | computed (repo script); gauge axis |
| Thresholds used in the script | "Deflected": abs(y_j) > 0.2 m (first block that exceeds it). "Straight": abs(y_j) <= 0.07 m (longest run of consecutive blocks) | `scripts/checks/jet_offset_by_band.py:41-48` | computed (repo script); no rationale recorded (Gaps) |
| Origin of the definition | Same function as panel (a) of an exploratory figure made for the reassessment of 2026-11-15, which plotted R0005, R0006, R0008 and R0007 | `tmp/gyre_diagnosis/fig2_evidence.py:8-18`, `:24-30`; `scripts/checks/jet_offset_by_band.py:8-10`; `cfd/campaign.md:375-378`, `:403` | settled (`tmp/` is gitignored, machine-local) |
| Symbol | `\yjet` | `paper/2026_journal_Shonai/jhr/notation.tex:57` | settled |

### 5b. Values for the five runs available (bands on the gauge axis)

| run | level | branch sign | B1 mean [min, max] (m) | B2 | B3 | B4 | first block with abs(y_j) > 0.2 m | source | status |
|---|---|---|---|---|---|---|---|---|---|
| R0001 | low | + | -0.273 [-0.39, -0.13] | -0.355 [-0.42, -0.28] | -0.380 [-0.43, -0.30] | -0.384 [-0.43, -0.30] | t = 130 s | Appendix A2 | computed (repo script, this task) |
| R0005 | medium | - | +0.337 [+0.15, +0.43] | +0.411 [+0.38, +0.44] | +0.434 [+0.41, +0.45] | +0.444 [+0.42, +0.47] | t = 70 s | Appendix A2 | computed (repo script, this task) |
| R0006 | medium | - | +0.362 [+0.30, +0.42] | +0.439 [+0.41, +0.46] | +0.421 [+0.37, +0.46] | +0.440 [+0.39, +0.47] | t = 10 s (the first block; already +0.384 m) | Appendix A2, C | computed (repo script, this task) |
| R0007 | medium | - | +0.020 [-0.02, +0.06] | +0.062 [+0.04, +0.08] | +0.062 [-0.00, +0.10] | +0.118 [+0.10, +0.15] | never | Appendix A2 | computed (repo script, this task) |
| R0008 | medium | + | -0.284 [-0.43, -0.05] | -0.396 [-0.42, -0.36] | -0.406 [-0.43, -0.37] | -0.430 [-0.46, -0.41] | t = 130 s | Appendix A2 | computed (repo script, this task) |

### 5c. Statements derived from 5b

| fact | value | source (file:line) | status |
|---|---|---|---|
| Time at which the direction is set | abs(y_j) first exceeds 0.2 m at 10-130 s after the start of the recording (R0006 10 s, R0005 70 s, R0001 and R0008 130 s), i.e. within B1 (h < a) | `paper/README.md:128-129`; `doc/settled_and_retracted.md:22`; Appendix A2 | settled |
| Resolution of those times | They are block-centre times of 20 s blocks (the crossing lies within about +-10 s of the stated time) | `scripts/checks/jet_offset_by_band.py:25`, `:47-48` | computed |
| Depth at the first crossing | Gauge depth 36.0, 36.0, 30.5, 39.1 mm and time-proportional depth 34.9, 34.9, 30.7, 38.6 mm for R0001, R0005, R0006, R0008: inside B1 (30-50 mm) on both axes | PIV fields and `frame_metrics.csv`, arithmetic in this task (Appendix C) | computed (cross-check) |
| Saturation | abs(y_j) saturates at 0.38-0.44 m (B3 and B4 band means of the four deflected runs: 0.380-0.444 m); the plan quotes "+-0.38-0.44 m", the campaign note "about 0.42 m" for R0005, R0006, R0008 | `paper/README.md:129`; `cfd/campaign.md:403-404`; Appendix A2 | settled |
| Saturation relative to the half-width | 0.380 / 0.981 = 0.39 to 0.444 / 0.981 = 0.45 of the half-width L_y / 2 | arithmetic in this task on the row above | computed (cross-check) |
| R0006 | Already deflected in the first block (+0.384 m at t = 10 s): the branch can be selected before the recording starts | `paper/README.md:130`; `doc/settled_and_retracted.md:22`; Appendix C | settled |
| R0008 | Starts at -0.05 m (first block) and saturates in about 5 min | `cfd/campaign.md:404-405`; Appendix A2, C | settled |
| R0008 "response time about 50 s" | Read off a hand-set logistic curve, -0.42 / (1 + exp(-(t - 107) / 46)), drawn over the data; the script contains no fit | `tmp/gyre_diagnosis/fig2_evidence.py:26-27`; `cfd/campaign.md:405` | unverified |
| R0007 | Band means +0.02 to +0.12 m; never exceeds 0.2 m; single blocks reach +0.151 m (t = 911 s, B4); longest run of consecutive blocks within +-0.07 m is 440 s (t = 0-440 s); 32 of 54 blocks are within +-0.07 m and 49 of 54 within +-0.12 m | Appendix A2, C | computed (repo script and cross-check, this task); differs from the recorded wording (section 11, C1, C2) |
| R0007, mean field | Mean surface field is a symmetric pair of gyres | `cfd/campaign.md:405-406`; `doc/settled_and_retracted.md:26` | unverified (no script named for it) |
| Attachment point | The deflected jet attaches to the sidewall at x of about 1.5 m (R0005, R0006, R0008) | `cfd/campaign.md:403-404` | unverified (no script named for it) |
| What grows with submergence | The jet direction is set early; what grows as the port becomes submerged is the basin-scale net circulation (I_circ) | `paper/README.md:132`; `doc/settled_and_retracted.md:22` | settled for the five runs; see section 11, C8 for the high level |
| Retracted wording | "The branch is fixed when the submergence of the jet is complete" (old manuscript) is wrong | `paper/README.md:133`; old manuscript `sections/results.tex:88`, `:148` | settled (retracted) |

### 5d. What is not available

| fact | value | source (file:line) | status |
|---|---|---|---|
| Runs without a jet-offset series | Seven: R0002, R0003, R0004 (low) and R0009, R0010, R0011, R0012 (high). Their `pivlab_single.mat` are on the WS, not on this Mac | `paper/README.md:134`, `:169-170`; `scripts/checks/jet_offset_by_band.py:4-5`, `:29`; `doc/settled_and_retracted.md:32`; listing of `local/work/*/pivlab_single.mat` in this task | GAP |
| Coverage by level | low 1 of 4, medium 4 of 4, high 0 of 4 | rows above | computed |
| Planned use | A 12-run time series of the jet offset is intended as a main figure once the files are transferred | `paper/README.md:169-170` | settled (pending item 5) |

## 6. Statistical tests

Sign pattern used by all three tests (rows = days, columns = levels; from `metadata/runs.csv:3-14`
and `local/derived/metrics/branch_stats.csv:2-13`, `branch_sign`):

| day | low | medium | high |
|---|---|---|---|
| 20260416 | + (R0001) | - (R0005) | - (R0009) |
| 20260420 | + (R0002) | - (R0006) | - (R0010) |
| 20260421 | + (R0003) | - (R0007) | - (R0011) |
| 20260422 | + (R0004) | + (R0008) | - (R0012) |

| fact | value | source (file:line) | status |
|---|---|---|---|
| Input to the tests | The sign patterns are typed into the script (4/0 and 0/4 for Fisher; + + + + / - - - + / - - - - for the trend); they are not read from `branch_stats.csv`. They match the table above | `scripts/checks/branch_sign_tests.py:44-45`, `:54-55` | computed (repo script) |
| (1) Trend test: statistic | Level scores 0, 1, 2 (low, medium, high). T = sum of the level scores of the positive runs. Observed T = 1 (four positive runs at score 0, one at score 1) | `scripts/checks/branch_sign_tests.py:51-55` | computed (repo script) |
| (1) Null hypothesis as implemented | The five positive signs are distributed over the 12 runs at random: each of the C(12,5) = 792 subsets is equally likely (sign exchangeable over runs, irrespective of level and of day; number of positive runs fixed at 5) | `scripts/checks/branch_sign_tests.py:56-60` | computed (repo script) |
| (1) p-value | p = P(T <= 1) = 4 / 792 = 0.0051, one-sided (lower tail: positive signs concentrated at low discharge) | Appendix A1; `scripts/checks/branch_sign_tests.py:59-61`; `paper/README.md:136` (quoted as 0.005) | computed (repo script, this task) |
| (1) Arithmetic | T = 1 is the smallest possible value (five positives cannot all sit in the four low runs); 4 subsets reach it. The permutation distribution is symmetric (T = 1..9: 4, 28, 88, 172, 208, 172, 88, 28, 4), so the two-sided value is 8 / 792 = 0.0101 | enumeration in this task | computed (cross-check, not a repo tool) |
| (1) Name | The script calls it "Cochran-Armitage-like ... exact permutation test of a monotone trend" | `scripts/checks/branch_sign_tests.py:51-52`; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:143` | settled |
| (2) Fisher exact test: table | Low versus high only: rows low / high, columns positive / negative = [[4, 0], [0, 4]]. The four medium runs are not used | `scripts/checks/branch_sign_tests.py:44` | computed (repo script) |
| (2) Null hypothesis as implemented | With the margins fixed (4 low, 4 high, 4 positive, 4 negative) the sign is independent of the level (hypergeometric) | `scripts/checks/branch_sign_tests.py:44-46` | computed (repo script) |
| (2) p-value | One-sided 1 / C(8,4) = 1 / 70 = 0.0143; two-sided 2 / 70 = 0.0286. The observed table is the most extreme one possible, so no smaller p can be obtained with 4 + 4 runs | Appendix A1; `scripts/checks/branch_sign_tests.py:45-46` | computed (repo script, this task) |
| (2) Where quoted | Not quoted in the plan (only tests 1 and 3 are) | `paper/README.md:136` | settled |
| (3) Within-day test: event | Low and high have opposite signs on all four days, in the same orientation (low positive, high negative) | `scripts/checks/branch_sign_tests.py:47` | computed (repo script) |
| (3) Null hypothesis as implemented | Each run is positive or negative with probability 1/2, independently of the level, of the other run of the same day and of other days; then P(low +, high -) = 1/4 on each day | `scripts/checks/branch_sign_tests.py:47-48` | computed (repo script) |
| (3) p-value | (1/4)^4 = 1/256 = 0.0039 for the observed orientation; 2 (1/4)^4 = 2/256 = 0.0078 for "opposite on all four days in one common orientation, whichever it is" | Appendix A1; `scripts/checks/branch_sign_tests.py:49-50` | computed (repo script, this task) |
| (3) Value quoted in the plan | "Within-day pairs p = 0.008", i.e. the either-orientation value | `paper/README.md:136` | settled |
| (3) Runs used | Low and high of each day (8 runs); medium not used | `scripts/checks/branch_sign_tests.py:47-50` | computed (repo script) |
| Design behind the tests | Randomized complete block: 4 days (blocks) x 3 levels; the order of the runs within a day was randomized ("no confounding with order") | `cfd/campaign.md:409`; `doc/settled_and_retracted.md:30`; `metadata/runs.csv:3-14`; old manuscript `sections/methods.tex:11` | user-confirmed (2026-11-15) |
| Outflow | The 12 outflow runs were made one run per day (12 different dates) and have no block structure. The function itself processes every non-excluded run in `runs.csv`; `s40` then keeps the inflow runs only, so `branch_stats.csv` and the figure contain no outflow row | old manuscript `sections/methods.tex:11`; `metadata/runs.csv:15-26`; `src/metrics/compute_branch_statistics.m:77-83`; `scripts/s40_make_paper_figures.m:153` | settled (wording corrected by audit) |
| Depth axis | The tests use the signs only; the signs are the same on both depth axes (12/12), so the p-values do not depend on the axis | `doc/qdip_jet_check.md:66`; section 9 | settled |
| Other output of the same script | Its block 2 prints port Reynolds and Froude numbers from the level discharges 0.219 / 0.392 / 0.623 L/s with an assumed viscosity of 1.0e-6 m^2/s. The water temperature is an open placeholder; do not quote these as measured | `scripts/checks/branch_sign_tests.py:36-41`; `paper/README.md:90`; `config/constants.m:61` | unverified (assumed viscosity) |

## 7. Per-run table (gauge axis, nominal normalization of I_circ)

Source of all columns except S: `local/derived/metrics/branch_stats.csv:2-13` (written by
`scripts/s40_make_paper_figures.m:152-156` from `src/metrics/compute_branch_statistics.m`; file dated
2026-10-26). Column S (mean energy-side index): Appendix A1. Status: computed (repo code / repo
script). All 12 rows were reproduced from `frame_metrics.csv` in this task (Appendix B).

| run | day | level | branch sign | mean I_circ | s.d. I_circ | R_lock | sign persistence | frames | run-average discharge (L/s) | mean S |
|---|---|---|---|---|---|---|---|---|---|---|
| R0001 | 20260416 | low | + | +0.006827 | 0.001617 | 4.22 | 1.000 | 3910 | 0.2180 | +0.353 |
| R0002 | 20260420 | low | + | +0.001213 | 0.001252 | 0.97 | 0.826 | 3936 | 0.2227 | +0.201 |
| R0003 | 20260421 | low | + | +0.005495 | 0.001843 | 2.98 | 1.000 | 3958 | 0.2195 | +0.283 |
| R0004 | 20260422 | low | + | +0.006493 | 0.001167 | 5.56 | 1.000 | 4323 | 0.2070 | +0.347 |
| R0005 | 20260416 | medium | - | -0.009295 | 0.001246 | 7.46 | 1.000 | 4446 | 0.4032 | -0.269 |
| R0006 | 20260420 | medium | - | -0.007790 | 0.000756 | 10.30 | 1.000 | 4455 | 0.4047 | -0.252 |
| R0007 | 20260421 | medium | - | -0.001744 | 0.000912 | 1.91 | 0.970 | 4777 | 0.3727 | -0.261 |
| R0008 | 20260422 | medium | + | +0.007727 | 0.000776 | 9.95 | 1.000 | 4709 | 0.3809 | +0.267 |
| R0009 | 20260416 | high | - | -0.009770 | 0.000883 | 11.07 | 1.000 | 4247 | 0.6336 | -0.231 |
| R0010 | 20260420 | high | - | -0.009832 | 0.000789 | 12.46 | 1.000 | 4324 | 0.6320 | -0.231 |
| R0011 | 20260421 | high | - | -0.007669 | 0.001153 | 6.65 | 1.000 | 4324 | 0.6145 | -0.254 |
| R0012 | 20260422 | high | - | -0.009479 | 0.000718 | 13.20 | 1.000 | 4465 | 0.5973 | -0.231 |

Notes to the table.

| fact | value | source (file:line) | status |
|---|---|---|---|
| Normalization of the I_circ columns | Nominal discharge of the level (section 1). With the run-average discharge instead, mean and s.d. of I_circ would both be multiplied by Q_nominal / Q_run (between 1.12 and 1.34, different for each run); sign, R_lock and sign persistence would not change | `scripts/s30_compute_metrics.m:47-59`; ratio from `branch_stats.csv` (`Q_run_mean_Lps`) and `metadata/flow_levels.csv:2-4`, arithmetic in this task | computed |
| Run-average discharge | Q = A x abs(h_end - h_start) / T over the whole record, A = 5.7918 m^2; ignores the feed-channel plan area below h = a (about 1%) | `src/metrics/compute_branch_statistics.m:37-45`, `:101-105` | settled; absolute value unverified (Gaps) |
| Column not to be used | `Q_transit_Lps` in the same file is a band-wise discharge and is retracted | `src/metrics/compute_branch_statistics.m:47-52`; `doc/settled_and_retracted.md:17`, `:42`; `doc/metrics_primer.md:175-179` | settled (retracted) |
| Figure made from this table | `fig_branch_selection.png`: (a) band-mean signed I_circ against h/a, one line per run; (b) day x level matrix of the sign, labelled with R_lock; (c) R_lock against the run-average discharge. Colour = branch, marker = level. Gauge axis; drawn with grid lines, whereas JHR asks for Times New Roman and no grid lines | `scripts/s40_make_paper_figures.m:144-254` (grid: `:200`, `:247`); `paper/README.md:103`, `:172` | computed (repo code); to be redrawn |

## 8. Run-average discharges of the bistable pair and of the medium level

| fact | value | source (file:line) | status |
|---|---|---|---|
| R0007 (medium, negative, weakest lock) | 0.3727 L/s (quoted as 0.373) | `local/derived/metrics/branch_stats.csv:8`; `paper/README.md:116-117` | settled |
| R0008 (medium, positive) | 0.3809 L/s (quoted as 0.381) | `local/derived/metrics/branch_stats.csv:9`; `paper/README.md:116-117` | settled |
| Difference | 0.0082 L/s = 2.2% of R0007 (2.15% of R0008) | `paper/README.md:116-117`; arithmetic in this task on `branch_stats.csv` | settled |
| Medium level, four runs | R0005 0.4032, R0006 0.4047, R0007 0.3727, R0008 0.3809 L/s; range 0.373-0.405 L/s (8.2% of the mean) | `local/derived/metrics/branch_stats.csv:6-9`; `paper/README.md:118` | settled |
| Medium level, summary | Median 0.392 L/s (the "level" figure used across the repo), mean 0.390 L/s; 0.75-0.81 of the nominal 0.50 L/s | `doc/settled_and_retracted.md:16`; `doc/metrics_primer.md:28`; arithmetic in this task on `branch_stats.csv` | settled; the level figures are medians of four runs |
| Other levels | low 0.207-0.223 L/s (median 0.219, mean 0.217); high 0.597-0.634 L/s (median 0.623, mean 0.619) | `local/derived/metrics/branch_stats.csv:2-5`, `:10-13`; `doc/settled_and_retracted.md:16` | settled |
| Position of the pair within the level | R0007 and R0008 are the two lowest-discharge medium runs; the two higher ones (R0005, R0006, 0.403-0.405 L/s) are both firmly negative (R_lock 7.5 and 10.3). R0008 is 3.2% below the mean of the other three medium runs | `local/derived/metrics/branch_stats.csv:6-9`, arithmetic in this task | computed; see referee point 7 |
| Day pattern in the discharge | The run of 20260422 has the lowest discharge of its level at low and high and the second lowest at medium; the run of 20260421 has the lowest at medium | `local/derived/metrics/branch_stats.csv:2-13`, arithmetic in this task | computed (cross-check) |
| Rule for quoting discharge | Run average only (`Q_run_mean_Lps`); no band-wise, level-derived discharge | `paper/README.md:119-120`; `doc/settled_and_retracted.md:17` | settled |
| Absolute value | Rests on the gauge readings at 30 mm and 100 mm; the gauge span is unverified | `paper/README.md:156-160`; `doc/settled_and_retracted.md:23` | unverified (pending item 2) |

## 9. Depth axis: gauge (as computed) versus time-proportional (primary)

| fact | value | source (file:line) | status |
|---|---|---|---|
| Decision | The time-proportional depth is the primary axis; the gauge depth is reported as a sensitivity check | `doc/settled_and_retracted.md:20`; `paper/README.md:61-63` | user-confirmed (2026-11-22) |
| Time-proportional depth | The straight line in time joining the start (30 mm) and the end (100 mm) of the record; same normalized time as `s31` | `doc/qdip_jet_check.md:60`; `paper/README.md:61` | settled |
| State of the implementation | Not implemented in `s31`. `frame_metrics.csv` (`band_id`), `band_metrics.csv`, `branch_stats.csv`, `fig_branch_selection.png` and both check scripts are on the gauge axis | `paper/README.md:63`, `:167-168`; `scripts/checks/branch_sign_tests.py:24`; `scripts/checks/jet_offset_by_band.py:31-34` | settled (pending item 4) |
| Recorded effect on the branch quantities | Signs unchanged in 12/12 (low 4/4 positive, high 4/4 negative, medium 3 negative / 1 positive). R_lock level medians 3.6 / 8.7 / 11.8 -> 3.0 / 7.3 / 10.7 (still monotone). Runs with sign persistence 1.000: 10/12 -> 9/12 (R0003 0.972; R0007 0.970 -> 0.896; R0002 0.826 -> 0.817) | `doc/qdip_jet_check.md:64-68`; `cfd/campaign.md:173` | settled as the recorded assessment |
| Provenance of those numbers | Computed in a scratchpad by swapping the depth only in the 24 `frame_metrics.csv`; "not made a repo tool" | `doc/qdip_jet_check.md:57-62` | unverified (not reproducible from a repo tool) |
| Cross-check in this task | Same recipe (h = 30 mm + 70 mm x (t - t_0) / T; frames with 60 <= h <= 100 mm): medians 3.02 / 7.27 / 10.73; persistence 1.000 in 9/12 with R0003 0.972, R0007 0.896, R0002 0.817; signs 12/12 unchanged. It reproduces the recorded values | `frame_metrics.csv`, arithmetic in this task (Appendix B, part D) | computed (cross-check, not a repo tool) |
| Change in frame counts | Recorded: B3 +14 to +16%, B4 +40 to +45%. These are level totals (audit recomputation with the frames of the four runs of a level summed: B3 +13.5 to +16.6%, B4 +39.5 to +44.3%); run by run the change is B3 +11 to +25% and B4 +37 to +54%. Pooled frames (B3 + B4) per run: 5197-6211 instead of 3910-4777 | `doc/qdip_jet_check.md:84`; Appendix B, part D; `frame_metrics.csv`, arithmetic in the audit | computed (cross-check; level-total versus per-run distinction added by audit) |
| Axis-free items | The sign pattern, the three tests, and the times at which the jet offset first exceeds 0.2 m | sections 5c, 6 | computed |
| Axis-dependent items | Mean and s.d. of I_circ, R_lock, sign persistence, mean S, frame counts, the by-band jet offsets, the shallow-band sign exceptions (B1 on both axes, B2 on the time-proportional axis only; section 1) | sections 1-5, 7 | computed |

Per-run values on the time-proportional axis (cross-check of this task; **not from a repo tool, do
not quote before `s31` is extended**; nominal normalization; source `frame_metrics.csv`, Appendix B,
part D; status: computed (cross-check)).

| run | level | branch sign | mean I_circ | s.d. I_circ | R_lock | sign persistence | frames | mean S |
|---|---|---|---|---|---|---|---|---|
| R0001 | low | + | +0.006473 | 0.001619 | 4.00 | 1.000 | 5309 | +0.354 |
| R0002 | low | + | +0.001112 | 0.001204 | 0.92 | 0.817 | 5197 | +0.180 |
| R0003 | low | + | +0.004658 | 0.002279 | 2.04 | 0.972 | 5271 | +0.285 |
| R0004 | low | + | +0.006071 | 0.001348 | 4.50 | 1.000 | 5591 | +0.349 |
| R0005 | medium | - | -0.008785 | 0.001501 | 5.85 | 1.000 | 5740 | -0.273 |
| R0006 | medium | - | -0.007564 | 0.000871 | 8.69 | 1.000 | 5720 | -0.255 |
| R0007 | medium | - | -0.001420 | 0.001056 | 1.35 | 0.896 | 6211 | -0.259 |
| R0008 | medium | + | +0.007554 | 0.000814 | 9.28 | 1.000 | 6077 | +0.268 |
| R0009 | high | - | -0.009941 | 0.000993 | 10.01 | 1.000 | 5480 | -0.230 |
| R0010 | high | - | -0.009968 | 0.000870 | 11.46 | 1.000 | 5494 | -0.227 |
| R0011 | high | - | -0.007417 | 0.001152 | 6.44 | 1.000 | 5650 | -0.253 |
| R0012 | high | - | -0.009575 | 0.000725 | 13.22 | 1.000 | 5813 | -0.228 |

Level ranges on the time-proportional axis (same cross-check): low 0.92-4.50, medium 1.35-9.28,
high 6.44-13.22.

## 10. Terms and symbols fixed for this subsection

| fact | value | source (file:line) | status |
|---|---|---|---|
| Terms | branch / branch selection, bistability, net circulation, lock strength, sign persistence, jet lateral offset, randomized complete block design, replicate, exact permutation test | `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:129-135`, `:141-143` | settled |
| Macros | `\Icirc`, `\Rlock`, `\Psign`, `\yjet`, `\Sside`, `\Band{3}`, `\Band{4}` | `paper/2026_journal_Shonai/jhr/notation.tex:46`, `:49`, `:55-58` | settled |
| Authoritative files named by the conventions | Branch statistics: `src/metrics/compute_branch_statistics.m`, `scripts/checks/branch_sign_tests.py`; jet offset: `scripts/checks/jet_offset_by_band.py` | `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:158-159` | settled |
| Position in the paper | Branch selection by discharge is the main result; the results order is constancy of discharge -> inflow mean field (short) -> branch selection -> dependence on h/a (secondary) -> outflow | `paper/README.md:55-59`; `doc/settled_and_retracted.md:21` | user-confirmed (2026-11-22) |
| No CFD | No CFD figure or number in the text | `paper/README.md:17-18`, `:92` | user-confirmed |

## 11. Conflicts between sources

| id | conflict | sources | what the data in this task show |
|---|---|---|---|
| C1 | "R0007 stays at or below 0.12 m over the whole run" | `paper/README.md:131`; `doc/settled_and_retracted.md:22` | True for the band means (largest +0.118 m, B4). Single 20 s blocks reach +0.151 m; 5 of 54 blocks exceed 0.12 m (Appendix A2, C) |
| C2 | "R0007 runs straight within +-0.07 m for about 700 s" | `cfd/campaign.md:405` | The longest run of consecutive blocks within +-0.07 m is 440 s; the first block beyond 0.07 m is at t = 450 s (+0.073 m). Up to t = 691 s every block is within +-0.08 m (Appendix A2, C) |
| C3 | Level discharges 0.219 / 0.392 / 0.623 L/s are called "run averages" | `doc/settled_and_retracted.md:16`; `doc/metrics_primer.md:28`; `scripts/checks/branch_sign_tests.py:38` | They are medians of the four run averages of each level; the means are 0.217 / 0.390 / 0.619 L/s (`branch_stats.csv`) |
| C4 | "The branch statistics do not depend on the water level and are unaffected" (written about the retracted band-wise discharge) | `doc/metrics_primer.md:178-179` | The pooled frames are selected with gauge depth bands, so R_lock and the sign persistence do change with the depth axis (`doc/qdip_jet_check.md:66-68`; section 9). Only the signs are unaffected |
| C5 | Discharge difference of the opposite-sign medium run: "1.4%" versus "2.2%" | old manuscript `sections/conclusions.tex:13` versus `sections/results.tex:92` and `paper/README.md:116-117` | 2.2% (R0008 against R0007); 3.2% against the mean of the other three medium runs. 1.4% is not reproduced from the run-average discharge by any pairing. Audit: it is reproduced by the retracted band-wise column `Q_transit_Lps` (R0008 0.4916 against R0007 0.4846 L/s = 1.44%; `local/derived/metrics/branch_stats.csv:8-9`), so 1.4% is a figure of the retracted discharge (`doc/settled_and_retracted.md:17`, `:42`) and must not be used |
| C6 | "The branch is fixed when the submergence of the jet is complete" | old manuscript `sections/results.tex:88`, `:148` | Retracted (`paper/README.md:133`; `doc/settled_and_retracted.md:22`) |
| C7 | Exclusion of B1 and B2 justified by "I_unst an order of magnitude larger" | `src/metrics/compute_branch_statistics.m:12-13`; `doc/metrics_primer.md:171`; old manuscript `sections/methods.tex:234` | On the time-proportional axis the contrast shrinks to a factor of 3-7, and 65-75% of the B1 value is a within-band trend (`doc/qdip_jet_check.md:83-86`, `:94-96`; `paper/README.md:57`). The rule stands; that supporting phrase should not be reused |
| C8 | "What grows with submergence is the basin-scale net circulation (I_circ)" | `paper/README.md:132`; `doc/settled_and_retracted.md:22` | Holds for the low and medium runs (band-mean abs(I_circ) grows from B1 to B4). In three of the four high runs (R0009, R0010, R0012) abs(I_circ) is largest in B1 (0.011-0.013) and slightly smaller in B4 (0.009-0.010); gauge axis, `band_metrics.csv`, arithmetic in this task. The jet-offset evidence behind the statement contains no high run |
| C9 | Sense of rotation of the positive branch | `doc/metrics_primer.md:144-147`, `:186` ("clockwise (I_circ < 0)", no frame stated); `scripts/s40_make_paper_figures.m:148-150` (counterclockwise in the x-right, y-up figure frame); `src/metrics/compute_frame_metrics_circ.m:21-22` and `compute_frame_metrics_basic.m:20-21` (small y is the upper image half, in which case positive would be clockwise in the camera image) | Unresolved: the sense is defined only relative to the figure frame (Gaps) |
| C10 | Split plane of the energy halves | `src/metrics/compute_frame_metrics_basic.m:18-20` (says "the basin's geometric symmetry plane y = Ly/2") versus `:113` (code uses the mid-point of the grid, 0.9853 m) | 4 mm difference; the centre row goes to the "right" half (section 4) |
| C11 | "x = 1.0 m" | `scripts/checks/jet_offset_by_band.py:1`, `:9`; `paper/README.md:128` | The grid column actually used is x = 0.989 m (Appendix C) |
| C12 | "Run length" printed by the jet-offset script | `scripts/checks/jet_offset_by_band.py:35` | It is the centre time of the last block (for example 1832 s for R0001), not the record length (1859.9 s) |
| C13 | Depth at the start of the recording, which is the time origin of the jet-offset series | `cfd/campaign.md:408` and `doc/settled_and_retracted.md:30` (20 mm) versus `metadata/runs.csv:3-14` and `paper/README.md:61` (30 mm) | Already an agreed placeholder (`paper/README.md:85-86`) |

## Points a referee may question

1. **Depth axis.** R_lock, the sign persistence and every by-band value are on the gauge axis, which
   the paper itself declares unreliable near h/a = 1. Values on the primary axis exist only as scratch
   arithmetic (section 9). The signs and the tests are axis-free.
2. **Choices made after seeing the data.** The summary quantities and the pooled bands (B3 + B4)
   were defined during the analysis (function added 2026-07-27, `doc/metrics_primer.md:157`), not
   before the experiments (April 2026, `metadata/runs.csv:3-14`). The pooling does have a recorded
   rationale (section 1, "Why the shallow bands (B1, B2) are excluded"), but one phrase supporting it
   is stale (section 11, C7). The x station (1.0 m), the block length (20 s) and the thresholds
   (0.2 m, 0.07 m) of the jet offset have no recorded rationale. The hypotheses of the tests were
   likewise formed after the fact (both check scripts entered the repository on 2026-11-22, commit
   b897a0b), so a one-sided p (test 1: 0.0051) is hard to defend; the two-sided value is 0.0101
   (enumeration in this task). [Wording corrected by audit: the earlier text listed B3 + B4 among
   the choices without a recorded rationale.]
3. **Independence of runs within a day, and the block design.** Tests 1 and 2 treat the 12 (or 8) runs
   as exchangeable and ignore the day blocks. A permutation of the same statistic within each day
   gives P(T <= 1) = (1/3)^4 = 1/81 = 0.012 one-sided (enumeration in this task; not in the script,
   not to be quoted unless the script is extended). Whether runs of one day are independent depends on
   the state of the basin between runs, which is not recorded (Gaps).
4. **Test 3 is not the classical paired sign test.** Its p (0.0039 / 0.0078) is the probability of a
   compound event (opposite signs on all four days and a common orientation) under a null in which
   every run is an independent fair coin. A classical sign test on four within-day differences cannot
   give less than (1/2)^4 = 0.0625 one-sided or 0.125 two-sided. In favour of the script's value:
   among nulls with independent runs and a common probability p of a positive sign, [p (1 - p)]^4 is
   largest at p = 1/2, so 0.0039 / 0.0078 are upper bounds within that family (arithmetic in this
   task).
5. **Sample size and multiplicity.** Four runs per level. Test 2 is already at its smallest attainable
   p (0.0143 / 0.0286). Three tests are run on the same 12 signs and overlap in the data they use; no
   correction is applied or discussed.
6. **What the tests show.** They show an association between sign and discharge level. They do not
   distinguish a discharge-dependent bias of the rig (an imperfection that changes sign with
   discharge) from branch selection in the sense of a bifurcation. Low and high are deterministic
   (4/4 each), which a referee may read as a bias.
7. **"Bistable" rests on one run.** R0008 is the only run on the other branch at medium. R0007 and
   R0008 are the two lowest-discharge medium runs (0.373 and 0.381 L/s); R0005 and R0006 (0.403 and
   0.405 L/s) are firmly negative. A referee may ask whether a threshold between about 0.38 and
   0.40 L/s explains the pattern as well as bistability does, the more so as the absolute discharge
   is unverified and the spread among the four runs of one level is up to 8% (section 8).
8. **R_lock.** (a) The s.d. is taken without detrending over windows of different length (283-303 s
   at high, 787-865 s at low on the gauge axis), so a slow drift of I_circ inside the window counts
   as "fluctuation"; (b) it contains PIV noise of the area-mean vorticity, computed without smoothing
   from 63 mm windows on a 31.5 mm grid (`doc/piv_conditions.md:45-46`); (c) frames are serially correlated and no uncertainty is
   attached; (d) it is not a t-statistic; (e) the symbol resembles the Reynolds number.
9. **Second indicator.** It is not statistically independent of I_circ (same fields, same frames).
   Its magnitude does not separate the nearly straight R0007 (-0.261, persistence 1.00) from the
   fully deflected runs (-0.25 to -0.27), so it identifies a side but not a degree of deflection.
   The grid row on the port axis is assigned to one half (section 4); the effect of that choice has
   not been checked.
10. **Jet offset.** Five runs, none at the high level and one at the low level. The centroid is taken
    over the whole width and over all forward-moving surface flow, not over the jet alone; it is a
    surface quantity at a single station. R0006 was already deflected in the first block, so "when
    the branch is selected" is not observed for it. Time zero is the start of the recording, whose
    depth is an open placeholder.
11. **Sense of rotation.** "Counterclockwise" is defined in the figure frame only (section 11, C9).
12. **Meaning of I_circ.** The area mean of the vorticity over the PIV grid equals the circulation
    along the perimeter of that grid divided by its area (Stokes' theorem; a mathematical remark, not
    from a source). The index therefore depends on the surface velocity along the grid edge, which
    lies 0.033-0.045 m off the walls (`doc/piv_conditions.md:74-75`).
13. **Normalization of I_circ.** The code normalizes with the nominal discharge although the run
    average is 0.75-0.89 of nominal (`doc/settled_and_retracted.md:16`). The comparison of mean
    I_circ between levels changes if the run-average discharge is used; R_lock, sign and persistence
    do not.
14. **Order within a day.** The randomization is user-confirmed, but the order actually run is not in
    `metadata/runs.csv` (`planned_order` is simply 1-12 by level and replicate).

## Gaps

Leave a `\PH{...}` (or do not write the statement) for each of these.

1. **Values on the primary (time-proportional) axis from a repo tool.** `s31` has no depth option yet;
   `branch_stats.csv` and the figure are on the gauge axis. Per-run values on the primary axis exist
   only as scratch arithmetic (section 9).
2. **Jet offset of seven runs** (R0002-R0004, R0009-R0012). No high run has a series.
3. **Orientation of the analysis frame in the laboratory**: which sidewall is y = 0, and whether the
   y-up figure is the view from above or its mirror image. Until known, "counterclockwise" can only
   be defined relative to the figure.
4. **Rationale for the jet-offset parameters**: x = 1.0 m, 20 s blocks, 0.2 m and 0.07 m thresholds.
5. **Response time of the deflection** ("about 50 s", R0008): a hand-set curve; no fit exists.
6. **Attachment point of the jet** ("x about 1.5 m") and the **mean field of R0007** ("symmetric pair
   of gyres"): recorded in `cfd/campaign.md:403-406` only, without a script.
7. **Order of the runs within each day, time between runs, and the state of the basin between runs**
   (drained and refilled, waiting time, residual motion). Needed for the independence assumption.
8. **Depth at the start of the recording** (20 mm or 30 mm) -- already an agreed placeholder.
9. **Uncertainty of R_lock, of the sign persistence and of the jet offset** (for example a block
   bootstrap): none computed.
10. **Robustness of the second indicator** to the assignment of the centre row and to PIV noise: not
    checked.
11. **Which tests the manuscript reports, and whether one- or two-sided**: no decision recorded. The
    plan quotes test 1 at p = 0.005 (one-sided) and test 3 at p = 0.008 (either orientation); test 2
    is not quoted.
12. **Which discharge defines U_p in the manuscript** (nominal, as in the code, or run average): to
    be stated by the writer; it changes the I_circ magnitudes but nothing else in this subsection.
13. **Absolute discharge** (gauge span unverified) and **water temperature / viscosity** -- already
    agreed placeholders; they affect the discharge column and any Reynolds number, not the branch
    quantities.

## Appendix: script output

Both repo scripts were run in this task on 2026-11-22 from the repository root on this Mac
(Python 3.13.5, numpy 2.3.3, pandas 2.3.3, h5py 3.16.0; HEAD b8295ed; `frame_metrics.csv` dated
2026-07-27, `pivlab_single.mat` dated 2026-07-18). Output is verbatim. Neither script writes a file.

### A1. `python3 scripts/checks/branch_sign_tests.py`

Block 2 of this output (Reynolds and Froude numbers) assumes a viscosity of 1.0e-6 m^2/s and uses
the level medians of the discharge; it is not evidence for Methods 2.6.

```
=== 1. second branch indicator: energy side vs circulation sign (B3+B4) ===
  R0001 low     circ +  side + (mean +0.353, persistence 1.00)
  R0002 low     circ +  side + (mean +0.201, persistence 1.00)
  R0003 low     circ +  side + (mean +0.283, persistence 1.00)
  R0004 low     circ +  side + (mean +0.347, persistence 1.00)
  R0005 medium  circ -  side - (mean -0.269, persistence 1.00)
  R0006 medium  circ -  side - (mean -0.252, persistence 1.00)
  R0007 medium  circ -  side - (mean -0.261, persistence 1.00)
  R0008 medium  circ +  side + (mean +0.267, persistence 1.00)
  R0009 high    circ -  side - (mean -0.231, persistence 1.00)
  R0010 high    circ -  side - (mean -0.231, persistence 1.00)
  R0011 high    circ -  side - (mean -0.254, persistence 1.00)
  R0012 high    circ -  side - (mean -0.231, persistence 1.00)
  => agree in 12/12 runs

=== 2. control parameter (run-average Q, nu = 1.0e-6 m^2/s) ===
  low     Q 0.219 L/s  U_p 0.0362 m/s  Re_p = U_p a/nu =  1991  Fr_p(h=a) = 0.049
  medium  Q 0.392 L/s  U_p 0.0648 m/s  Re_p = U_p a/nu =  3564  Fr_p(h=a) = 0.088
  high    Q 0.623 L/s  U_p 0.1030 m/s  Re_p = U_p a/nu =  5664  Fr_p(h=a) = 0.140

=== 3. exact tests of the sign pattern ===
  low vs high, Fisher exact: one-sided 0.0143, two-sided 0.0286
  within-day, same orientation on all 4 days: 0.0039 (either orientation: 0.0078)
  monotone trend over 3 levels (5 positive runs, exact permutation): p = 0.0051
```

### A2. `python3 scripts/checks/jet_offset_by_band.py`

PIV fields exist on this machine for R0001 and R0005-R0008 only. Times are block-centre times in
seconds from the first PIV frame; "run length" is the centre time of the last block; bands are on
the gauge axis.

```
R0001  run length 1832 s
   B1: t    10-  751 s   offset mean -0.273 m   range [-0.39, -0.13]
   B2: t   731- 1071 s   offset mean -0.355 m   range [-0.42, -0.28]
   B3: t  1091- 1411 s   offset mean -0.380 m   range [-0.43, -0.30]
   B4: t  1431- 1832 s   offset mean -0.384 m   range [-0.43, -0.30]
   longest stretch within +-0.07 m: 0 s; first time |offset| > 0.2 m: 130.12999986987 s
R0005  run length 991 s
   B1: t    10-  410 s   offset mean +0.337 m   range [+0.15, +0.43]
   B2: t   430-  551 s   offset mean +0.411 m   range [+0.38, +0.44]
   B3: t   571-  751 s   offset mean +0.434 m   range [+0.41, +0.45]
   B4: t   771-  991 s   offset mean +0.444 m   range [+0.42, +0.47]
   longest stretch within +-0.07 m: 0 s; first time |offset| > 0.2 m: 70.07000000007007 s
R0006  run length 991 s
   B1: t    10-  390 s   offset mean +0.362 m   range [+0.30, +0.42]
   B2: t   410-  551 s   offset mean +0.439 m   range [+0.41, +0.46]
   B3: t   571-  731 s   offset mean +0.421 m   range [+0.37, +0.46]
   B4: t   751-  991 s   offset mean +0.440 m   range [+0.39, +0.47]
   longest stretch within +-0.07 m: 0 s; first time |offset| > 0.2 m: 10.01000000001001 s
R0007  run length 1071 s
   B1: t    10-  410 s   offset mean +0.020 m   range [-0.02, +0.06]
   B2: t   430-  591 s   offset mean +0.062 m   range [+0.04, +0.08]
   B3: t   611-  811 s   offset mean +0.062 m   range [-0.00, +0.10]
   B4: t   831- 1071 s   offset mean +0.118 m   range [+0.10, +0.15]
   longest stretch within +-0.07 m: 440 s; first time |offset| > 0.2 m: never s
R0008  run length 1051 s
   B1: t    10-  410 s   offset mean -0.284 m   range [-0.43, -0.05]
   B2: t   430-  591 s   offset mean -0.396 m   range [-0.42, -0.36]
   B3: t   611-  791 s   offset mean -0.406 m   range [-0.43, -0.37]
   B4: t   811- 1051 s   offset mean -0.430 m   range [-0.46, -0.41]
   longest stretch within +-0.07 m: 20 s; first time |offset| > 0.2 m: 130.1300000001301 s
```

### B. Cross-check of the branch statistics (arithmetic in this task; not a repo tool)

One-off python on `local/derived/metrics/branch_stats.csv` and
`local/derived/metrics/R00xx/frame_metrics.csv`. Part A recomputes every column of
`branch_stats.csv` (values in parentheses are the CSV), R_lock from the un-normalized `omega_mean`
column ("R_from_omega"), R_lock with divisor N ("R_ddof0"), the applied a / U_p and the number of
frames with I_circ exactly zero ("nzero"). Part D repeats the pooling on the time-proportional
depth, h = h_first + (h_last - h_first) x (t - t_0) / T, frames with 0.06 <= h <= 0.10 m.

```
--- A. gauge axis: reproduce branch_stats.csv; R_lock from raw omega_mean ---
R0001 n 3910 (csv 3910)  mean +0.006827 (csv +0.006827)  sd 0.001617 (csv 0.001617)  R 4.2211 (csv 4.2211)  R_from_omega 4.2211  R_ddof0 4.2217  pers 1.0000 (csv 1.0000)  Q 0.2180 (csv 0.2180)  T 1859.9 s  dt 0.2002 s  a/U_p 1.331000..1.331000  nzero 0
R0002 n 3936 (csv 3936)  mean +0.001213 (csv +0.001213)  sd 0.001252 (csv 0.001252)  R 0.9692 (csv 0.9692)  R_from_omega 0.9692  R_ddof0 0.9694  pers 0.8262 (csv 0.8262)  Q 0.2227 (csv 0.2227)  T 1820.6 s  dt 0.2002 s  a/U_p 1.331000..1.331000  nzero 0
R0003 n 3958 (csv 3958)  mean +0.005495 (csv +0.005495)  sd 0.001843 (csv 0.001843)  R 2.9810 (csv 2.9810)  R_from_omega 2.9810  R_ddof0 2.9814  pers 1.0000 (csv 1.0000)  Q 0.2195 (csv 0.2195)  T 1846.6 s  dt 0.2002 s  a/U_p 1.331000..1.331000  nzero 0
R0004 n 4323 (csv 4323)  mean +0.006493 (csv +0.006493)  sd 0.001167 (csv 0.001167)  R 5.5645 (csv 5.5645)  R_from_omega 5.5645  R_ddof0 5.5651  pers 1.0000 (csv 1.0000)  Q 0.2070 (csv 0.2070)  T 1958.8 s  dt 0.2002 s  a/U_p 1.331000..1.331000  nzero 0
R0005 n 4446 (csv 4446)  mean -0.009295 (csv -0.009295)  sd 0.001246 (csv 0.001246)  R 7.4583 (csv 7.4583)  R_from_omega 7.4583  R_ddof0 7.4591  pers 1.0000 (csv 1.0000)  Q 0.4032 (csv 0.4032)  T 1005.4 s  dt 0.1001 s  a/U_p 0.665500..0.665500  nzero 0
R0006 n 4455 (csv 4455)  mean -0.007790 (csv -0.007790)  sd 0.000756 (csv 0.000756)  R 10.2981 (csv 10.2981)  R_from_omega 10.2981  R_ddof0 10.2992  pers 1.0000 (csv 1.0000)  Q 0.4047 (csv 0.4047)  T 1001.9 s  dt 0.1001 s  a/U_p 0.665500..0.665500  nzero 0
R0007 n 4777 (csv 4777)  mean -0.001744 (csv -0.001744)  sd 0.000912 (csv 0.000912)  R 1.9130 (csv 1.9130)  R_from_omega 1.9130  R_ddof0 1.9132  pers 0.9703 (csv 0.9703)  Q 0.3727 (csv 0.3727)  T 1087.9 s  dt 0.1001 s  a/U_p 0.665500..0.665500  nzero 0
R0008 n 4709 (csv 4709)  mean +0.007727 (csv +0.007727)  sd 0.000776 (csv 0.000776)  R 9.9515 (csv 9.9515)  R_from_omega 9.9515  R_ddof0 9.9525  pers 1.0000 (csv 1.0000)  Q 0.3809 (csv 0.3809)  T 1064.5 s  dt 0.1001 s  a/U_p 0.665500..0.665500  nzero 0
R0009 n 4247 (csv 4247)  mean -0.009770 (csv -0.009770)  sd 0.000883 (csv 0.000883)  R 11.0671 (csv 11.0671)  R_from_omega 11.0671  R_ddof0 11.0684  pers 1.0000 (csv 1.0000)  Q 0.6336 (csv 0.6336)  T 639.9 s  dt 0.0667 s  a/U_p 0.443667..0.443667  nzero 0
R0010 n 4324 (csv 4324)  mean -0.009832 (csv -0.009832)  sd 0.000789 (csv 0.000789)  R 12.4605 (csv 12.4605)  R_from_omega 12.4605  R_ddof0 12.4620  pers 1.0000 (csv 1.0000)  Q 0.6320 (csv 0.6320)  T 641.5 s  dt 0.0667 s  a/U_p 0.443667..0.443667  nzero 0
R0011 n 4324 (csv 4324)  mean -0.007669 (csv -0.007669)  sd 0.001153 (csv 0.001153)  R 6.6490 (csv 6.6490)  R_from_omega 6.6490  R_ddof0 6.6498  pers 1.0000 (csv 1.0000)  Q 0.6145 (csv 0.6145)  T 659.7 s  dt 0.0667 s  a/U_p 0.443667..0.443667  nzero 0
R0012 n 4465 (csv 4465)  mean -0.009479 (csv -0.009479)  sd 0.000718 (csv 0.000718)  R 13.1958 (csv 13.1958)  R_from_omega 13.1958  R_ddof0 13.1973  pers 1.0000 (csv 1.0000)  Q 0.5973 (csv 0.5973)  T 678.8 s  dt 0.0667 s  a/U_p 0.443667..0.443667  nzero 0

--- level summaries (gauge axis) ---
low     R_lock min 0.97 max 5.56 median 3.60 mean 3.43 | Q min 0.2070 max 0.2227 median 0.2188 mean 0.2168 | signs [1, 1, 1, 1]
medium  R_lock min 1.91 max 10.30 median 8.70 mean 7.41 | Q min 0.3727 max 0.4047 median 0.3921 mean 0.3904 | signs [-1, -1, -1, 1]
high    R_lock min 6.65 max 13.20 median 11.76 mean 10.84 | Q min 0.5973 max 0.6336 median 0.6233 mean 0.6193 | signs [-1, -1, -1, -1]
persistence == 1 exactly: 10 of 12
R0007 vs R0008 Q: 0.3726745098846682 0.38087517147137234 diff % of R0007 2.2004889975549955  diff % of R0008 2.153110047846874
medium range 0.3726745098846682 0.4046584647244055 spread % of mean 8.193364239662442
R0008 vs mean of other three medium runs %: -3.215011407942758
deep-band time spans [s] and sampling interval:
  R0001 low     deep bands t  1072.9- 1859.9 s ( 787.0 s of 1859.9 s)  n 3910  dt 0.2002 s
  R0002 low     deep bands t  1016.8- 1820.6 s ( 803.8 s of 1820.6 s)  n 3936  dt 0.2002 s
  R0003 low     deep bands t  1054.5- 1846.6 s ( 792.2 s of 1846.6 s)  n 3958  dt 0.2002 s
  R0004 low     deep bands t  1093.5- 1958.8 s ( 865.3 s of 1958.8 s)  n 4323  dt 0.2002 s
  R0005 medium  deep bands t   559.3- 1005.4 s ( 446.1 s of 1005.4 s)  n 4446  dt 0.1001 s
  R0006 medium  deep bands t   556.1- 1001.9 s ( 445.8 s of 1001.9 s)  n 4455  dt 0.1001 s
  R0007 medium  deep bands t   609.8- 1087.9 s ( 478.1 s of 1087.9 s)  n 4777  dt 0.1001 s
  R0008 medium  deep bands t   593.2- 1064.5 s ( 471.3 s of 1064.5 s)  n 4709  dt 0.1001 s
  R0009 high    deep bands t   356.6-  639.9 s ( 283.3 s of  639.9 s)  n 4247  dt 0.0667 s
  R0010 high    deep bands t   353.0-  641.5 s ( 288.5 s of  641.5 s)  n 4324  dt 0.0667 s
  R0011 high    deep bands t   371.2-  659.7 s ( 288.5 s of  659.7 s)  n 4324  dt 0.0667 s
  R0012 high    deep bands t   375.6-  678.8 s ( 303.2 s of  678.8 s)  n 4465  dt 0.0667 s

--- D. time-proportional axis (depth = 30 mm + 70 mm x (t - t0)/T), same band rule ---
  R0001 low     n 5309  mean +0.006473  sd 0.001619  R_lock 3.999  pers 1.0000  sign +  side mean +0.354
  R0002 low     n 5197  mean +0.001112  sd 0.001204  R_lock 0.924  pers 0.8170  sign +  side mean +0.180
  R0003 low     n 5271  mean +0.004658  sd 0.002279  R_lock 2.044  pers 0.9715  sign +  side mean +0.285
  R0004 low     n 5591  mean +0.006071  sd 0.001348  R_lock 4.505  pers 1.0000  sign +  side mean +0.349
  R0005 medium  n 5740  mean -0.008785  sd 0.001501  R_lock 5.851  pers 1.0000  sign -  side mean -0.273
  R0006 medium  n 5720  mean -0.007564  sd 0.000871  R_lock 8.687  pers 1.0000  sign -  side mean -0.255
  R0007 medium  n 6211  mean -0.001420  sd 0.001056  R_lock 1.345  pers 0.8962  sign -  side mean -0.259
  R0008 medium  n 6077  mean +0.007554  sd 0.000814  R_lock 9.284  pers 1.0000  sign +  side mean +0.268
  R0009 high    n 5480  mean -0.009941  sd 0.000993  R_lock 10.009  pers 1.0000  sign -  side mean -0.230
  R0010 high    n 5494  mean -0.009968  sd 0.000870  R_lock 11.457  pers 1.0000  sign -  side mean -0.227
  R0011 high    n 5650  mean -0.007417  sd 0.001152  R_lock 6.436  pers 1.0000  sign -  side mean -0.253
  R0012 high    n 5813  mean -0.009575  sd 0.000725  R_lock 13.215  pers 1.0000  sign -  side mean -0.228
low     R_lock min 0.92 max 4.50 median 3.02
medium  R_lock min 1.34 max 9.28 median 7.27
high    R_lock min 6.44 max 13.22 median 10.73
persistence == 1 exactly: 9 of 12
```

### C. Cross-check of the jet-offset series (arithmetic in this task; not a repo tool)

Same function as `scripts/checks/jet_offset_by_band.py:15-27`, printing the whole 20 s block series
(t in s, offset in m), the grid column used, and the depth at the first block with abs(offset) > 0.2 m
on both depth axes.

```
== R0001  x column 0.9892 m  block 100 frames = 20.02 s  blocks 92  frames used 9200 of 9291  branch sign +1
   t   : [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991, 1011, 1031, 1051, 1071, 1091, 1111, 1131, 1151, 1171, 1191, 1211, 1231, 1251, 1271, 1291, 1311, 1331, 1351, 1371, 1391, 1411, 1431, 1451, 1471, 1491, 1512, 1532, 1552, 1572, 1592, 1612, 1632, 1652, 1672, 1692, 1712, 1732, 1752, 1772, 1792, 1812, 1832]
   off : [-0.141, -0.127, -0.165, -0.162, -0.168, -0.166, -0.207, -0.182, -0.224, -0.246, -0.247, -0.257, -0.221, -0.284, -0.271, -0.284, -0.301, -0.205, -0.306, -0.336, -0.282, -0.331, -0.331, -0.35, -0.315, -0.385, -0.311, -0.331, -0.289, -0.326, -0.359, -0.313, -0.302, -0.377, -0.322, -0.289, -0.32, -0.385, -0.335, -0.284, -0.308, -0.341, -0.363, -0.308, -0.369, -0.412, -0.361, -0.391, -0.337, -0.331, -0.407, -0.416, -0.387, -0.362, -0.368, -0.38, -0.394, -0.365, -0.393, -0.416, -0.349, -0.369, -0.42, -0.37, -0.406, -0.434, -0.301, -0.334, -0.397, -0.396, -0.359, -0.391, -0.344, -0.347, -0.373, -0.305, -0.388, -0.4, -0.391, -0.32, -0.389, -0.397, -0.359, -0.434, -0.413, -0.371, -0.374, -0.388, -0.421, -0.423, -0.402, -0.428]
   first block centre with |off| > 0.2: 130.12999986987; offset in first block -0.141; max |off| 0.434 at t 1311; min |off| 0.127
   blocks within +-0.07: 0 of 92; within +-0.12: 0; t of blocks beyond 0.07: [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791]
   mean of last half of run -0.380; mean of last 10 blocks -0.401; sign changes after first 0.2 crossing: 0
   first crossing: t/T = 0.070 -> time-proportional depth 34.9 mm; gauge depth 36.0 mm
== R0005  x column 0.9892 m  block 200 frames = 20.02 s  blocks 50  frames used 10000 of 10045  branch sign -1
   t   : [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991]
   off : [0.146, 0.151, 0.176, 0.253, 0.303, 0.333, 0.356, 0.427, 0.429, 0.355, 0.36, 0.409, 0.34, 0.383, 0.357, 0.382, 0.385, 0.356, 0.383, 0.409, 0.393, 0.377, 0.38, 0.426, 0.408, 0.439, 0.434, 0.415, 0.425, 0.442, 0.45, 0.432, 0.451, 0.431, 0.441, 0.409, 0.42, 0.437, 0.415, 0.45, 0.435, 0.474, 0.423, 0.456, 0.433, 0.439, 0.457, 0.449, 0.459, 0.441]
   first block centre with |off| > 0.2: 70.07000000007007; offset in first block +0.146; max |off| 0.474 at t 831; min |off| 0.146
   blocks within +-0.07: 0 of 50; within +-0.12: 0; t of blocks beyond 0.07: [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791]
   mean of last half of run +0.438; mean of last 10 blocks +0.447; sign changes after first 0.2 crossing: 0
   first crossing: t/T = 0.070 -> time-proportional depth 34.9 mm; gauge depth 36.0 mm
== R0006  x column 0.9892 m  block 200 frames = 20.02 s  blocks 50  frames used 10000 of 10010  branch sign -1
   t   : [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991]
   off : [0.384, 0.34, 0.312, 0.328, 0.333, 0.368, 0.392, 0.405, 0.329, 0.37, 0.301, 0.324, 0.398, 0.347, 0.366, 0.377, 0.355, 0.4, 0.42, 0.386, 0.424, 0.43, 0.444, 0.436, 0.453, 0.455, 0.459, 0.409, 0.42, 0.371, 0.408, 0.416, 0.435, 0.4, 0.439, 0.458, 0.439, 0.392, 0.426, 0.453, 0.438, 0.417, 0.417, 0.433, 0.454, 0.466, 0.472, 0.45, 0.461, 0.441]
   first block centre with |off| > 0.2: 10.01000000001001; offset in first block +0.384; max |off| 0.472 at t 931; min |off| 0.301
   blocks within +-0.07: 0 of 50; within +-0.12: 0; t of blocks beyond 0.07: [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791]
   mean of last half of run +0.433; mean of last 10 blocks +0.445; sign changes after first 0.2 crossing: 0
   first crossing: t/T = 0.010 -> time-proportional depth 30.7 mm; gauge depth 30.5 mm
== R0007  x column 0.9892 m  block 200 frames = 20.02 s  blocks 54  frames used 10800 of 10869  branch sign -1
   t   : [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991, 1011, 1031, 1051, 1071]
   off : [0.027, 0.005, 0.021, 0.013, 0.021, 0.019, -0.025, -0.021, 0.031, 0.019, 0.059, 0.039, 0.034, 0.009, 0.031, 0.051, 0.005, 0.006, 0.023, 0.006, 0.036, 0.059, 0.073, 0.058, 0.058, 0.048, 0.073, 0.042, 0.073, 0.078, 0.059, 0.074, 0.038, -0.0, 0.058, 0.087, 0.021, 0.065, 0.082, 0.096, 0.103, 0.116, 0.105, 0.121, 0.114, 0.151, 0.147, 0.128, 0.101, 0.12, 0.095, 0.12, 0.106, 0.112]
   first block centre with |off| > 0.2: None; offset in first block +0.027; max |off| 0.151 at t 911; min |off| 0.000
   blocks within +-0.07: 32 of 54; within +-0.12: 49; t of blocks beyond 0.07: [450, 531, 571, 591, 631, 711, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991, 1011, 1031, 1051, 1071]
   mean of last half of run +0.089; mean of last 10 blocks +0.119; sign changes after first 0.2 crossing: n/a
== R0008  x column 0.9892 m  block 200 frames = 20.02 s  blocks 53  frames used 10600 of 10635  branch sign +1
   t   : [10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811, 831, 851, 871, 891, 911, 931, 951, 971, 991, 1011, 1031, 1051]
   off : [-0.049, -0.095, -0.11, -0.12, -0.175, -0.16, -0.227, -0.26, -0.276, -0.301, -0.333, -0.361, -0.356, -0.394, -0.413, -0.429, -0.383, -0.412, -0.387, -0.337, -0.391, -0.393, -0.364, -0.404, -0.399, -0.386, -0.402, -0.414, -0.382, -0.418, -0.392, -0.374, -0.406, -0.405, -0.412, -0.408, -0.402, -0.406, -0.428, -0.423, -0.411, -0.44, -0.426, -0.459, -0.45, -0.417, -0.431, -0.421, -0.424, -0.418, -0.422, -0.435, -0.43]
   first block centre with |off| > 0.2: 130.1300000001301; offset in first block -0.049; max |off| 0.459 at t 871; min |off| 0.049
   blocks within +-0.07: 1 of 53; within +-0.12: 3; t of blocks beyond 0.07: [30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 511, 531, 551, 571, 591, 611, 631, 651, 671, 691, 711, 731, 751, 771, 791, 811]
   mean of last half of run -0.417; mean of last 10 blocks -0.431; sign changes after first 0.2 crossing: 0
   first crossing: t/T = 0.122 -> time-proportional depth 38.6 mm; gauge depth 39.1 mm
```

## Audit (second reader)

Independent audit, 2026-11-22, same working tree (HEAD b8295ed; this file was the only file edited).
Method: every cited repo file was opened at the cited lines; both repo scripts were re-run with
python3 and their output compared with Appendix A1 and A2 by `diff` (identical); Appendix B (gauge
axis and time-proportional axis) and Appendix C were recomputed with separate one-off python from
`branch_stats.csv`, `band_metrics.csv`, the 12 `frame_metrics.csv` and the five `pivlab_single.mat`
(all reproduced to the digits printed); the permutation distributions and the three p-values were
re-enumerated. About 190 statements were checked: the 178 table rows of sections 1-11 and the 14
referee points, together with the three appendices. Ten were corrected (table below); five could not
be verified (list further down).

### Changed in place

| where | what was wrong | now |
|---|---|---|
| Section 1, "Size of the net circulation" | The row carried the old manuscript's "abs(I_circ) is less than one tenth of I_rot" as computed. Only the bound 0.013 had been checked. In `band_metrics.csv` abs(I_circ) / I_rot is 0.003-0.177 and exceeds 0.10 in 24 of 48 run-band cells (17 of 24 in B3 and B4) | Bound kept; the "one tenth" wording marked stale and not to be reused |
| Section 1, "Observation behind the exclusion" | "In B2-B4 no run differs from its deep-band sign" was placed next to "holds on both depth axes". On the time-proportional (primary) axis B2 has two exceptions: R0002 (-0.00031) and R0003 (-0.000001, i.e. zero) | Stated per axis. The B1 exceptions (R0002, R0003, R0007) are the same on both axes |
| Section 1, "U_p as implemented" | Source of the nominal discharge given as `metadata/flow_levels.csv`; the code reads the `nominal_Q_Lps` column of `metadata/runs.csv` (same values) | Source corrected |
| Section 5a, "Time stamp" | "First PIV frame (start of the recording)" asserted an identity that no source records | Reworded; marked unverified by audit (see below) |
| Section 5a, "Band of a block" | (addition) | Note that the gauge band sequence of the blocks is not monotone in time (R0001: B1 to 751 s, B2 from 731 s) |
| Section 6, "Outflow" | "No branch statistics are computed for them": the function does process outflow runs; `s40` drops them from the output | Reworded |
| Section 9, "Change in frame counts" | The recorded percentages read as per-run values next to per-run frame counts; they are level totals. Per run the spread is wider (B3 +11 to +25%, B4 +37 to +54%) | Both given |
| Section 9, "Axis-dependent items" | Listed "the B1 sign exceptions" only | B2 on the time-proportional axis added |
| Section 11, C5 | "1.4% is not reproduced by any pairing" | 1.4% is R0008 against R0007 in the retracted `Q_transit_Lps` column (1.44%); marked as a figure of the retracted discharge |
| Referee point 2 | The sentence listed the pooled bands (B3 + B4) among the choices "with no recorded rationale", contradicting section 1 | Reworded; commit date of the check scripts added (read-only `git log`) |

### Verified without change (the statements a manuscript sentence would rest on)

- All line references into `src/metrics/compute_branch_statistics.m`, `compute_frame_metrics_circ.m`,
  `compute_frame_metrics_basic.m`, `assign_depth_bands.m`, `scripts/s30_compute_metrics.m`,
  `scripts/s40_make_paper_figures.m`, both check scripts, `tmp/gyre_diagnosis/fig2_evidence.py`,
  `config/constants.m`, `config/metrics_defaults.m`, the three metadata tables, `doc/metrics_primer.md`,
  `doc/qdip_jet_check.md`, `doc/piv_conditions.md`, `doc/settled_and_retracted.md`, `paper/README.md`,
  `CONVENTIONS.md`, `notation.tex`, `cfd/campaign.md` (experimental lines only) and the old manuscript.
- Definitions: branch sign, pooling over B3 + B4 (frames pooled, not band means), R_lock with the
  sample s.d. (divisor N - 1), sign persistence, S and which half is "left" (`Y < yMid`, yMid =
  0.9853 m, 30 rows left / 31 right), the jet-offset definition (column x = 0.9892 m, 61 points,
  100- or 200-frame blocks = 20.02 s, weight = square of the positive block-mean u, y_port = 0.981 m).
- Independence of R_lock from the normalizing discharge: `I_circ / omega_mean` is one constant per run
  (1.3310, 0.6655, 0.4437 s) and R_lock from `omega_mean` equals R_lock from `I_circ` in 12/12 runs.
- The per-run table of section 7 (all 12 rows against `branch_stats.csv:2-13` and against a
  recomputation from `frame_metrics.csv`), the level ranges and medians (3.60 / 8.70 / 11.76), the
  discharges of section 8 (R0007 0.3727, R0008 0.3809, difference 2.2%; medians 0.219 / 0.392 /
  0.623, means 0.217 / 0.390 / 0.619 L/s), Q_nominal / Q_run = 1.12-1.34.
- Time-proportional axis: the 12-row table of section 9, medians 3.02 / 7.27 / 10.73, persistence
  1.000 in 9/12 (R0003 0.972, R0007 0.896, R0002 0.817), signs 12/12 unchanged, S agreement 12/12.
- Tests: T = 1, 4 / 792 = 0.0051 one-sided, distribution 4, 28, 88, 172, 208, 172, 88, 28, 4, two-sided
  8 / 792; Fisher 1 / 70 and 2 / 70; (1/4)^4 and 2 (1/4)^4; within-day permutation 1 / 81.
- Jet offset: the 5b table, first crossings at 10 / 70 / 130 / 130 s with depths 30.5-39.1 mm (gauge)
  and 30.7-38.6 mm (time-proportional), R0007 counts (32 and 49 of 54 blocks, longest straight
  stretch 440 s, maximum +0.151 m at t = 911 s), and conflicts C1, C2, C8, C11, C12.
- Energy-side index: mean S per run as in Appendix A1; the fraction of frames sharing the sign is
  exactly 1 in all 12 runs (the smallest single-frame abs(S) is 0.078, R0002).
- No retracted statement of `doc/settled_and_retracted.md` section 2 is carried as valid: the
  band-wise discharge, the transit-time method and "the branch is fixed when submergence is complete"
  appear only as retracted; no "start from still water"; no ultrasonic gauge; R_lock is not called
  saturated. No CFD result is in the sheet (the two rows citing `cfd/campaign.md:157-173` carry
  experimental numbers only).

### Unverified by audit

- Whether the first PIV frame is the first frame of the video recording (Section 5a "Time stamp";
  it decides what "10-130 s after the start of the recording" means). Same open point as C13.
- The three statements that rest on `cfd/campaign.md:403-406` alone and have no script: attachment
  at x of about 1.5 m, the mean field of R0007 as a symmetric pair of gyres, the response time of
  about 50 s. Not recomputed here (already marked unverified or listed under Gaps).
- The randomized order within a day and "no confounding with order": a user confirmation recorded in
  `cfd/campaign.md:409`; nothing in `metadata/runs.csv` can confirm it.
- The laboratory orientation of the analysis frame (Gaps 3) and the absolute discharge (Gaps 13).
- The Stokes-theorem remark of referee point 12 has no source by construction; the code uses
  one-sided differences at the grid edge, so the identity is approximate for the discrete mean.

### Additional observations (not errors of the sheet)

- `doc/metrics_primer.md:30-31` still describes the analysis domain as a masked region that excludes
  the port vicinity. The code applies no mask (`doc/piv_conditions.md:233`; `valid_fraction` = 1.000
  on all 5612 = 92 x 61 grid points in every frame of the five runs checked). The row "Analysis
  domain" of section 1 is correct; the primer line is stale.
- The file `branch_stats.csv` (2026-10-26) is older than the last commit that touched
  `compute_branch_statistics.m` (2026-11-15, 0ab74d5); that commit changed comments only, and the file
  is reproduced by the current code path (Appendix B).
- On the time-proportional axis the pattern of C8 is the same: in R0009, R0010 and R0012 band-mean
  abs(I_circ) is 0.010-0.013 in B1 and 0.009-0.010 in B4 (cross-check, not a repo tool).

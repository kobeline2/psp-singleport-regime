# Evidence sheet -- Methods 2.5 "Flow metrics" (definitions as implemented)

Scope: the six flow metrics E, phi_lv, I_asym, I_circ, I_rot, I_unst, the depth bands B1-B4 and the band aggregation, exactly as the code computes them. Evidence only; no manuscript text. No CFD content.

**Read this first.**
1. The port velocity scale in every implemented index is built on the **nominal** discharge of the flow level, not on the measured run-average discharge (`scripts/s30_compute_metrics.m:46-58`).
2. All band-wise numbers that exist as files today are on the **gauge** depth axis. The time-proportional axis that the manuscript will use is not implemented in `s31` (`paper/README.md:61-63`, `:167-168`). Band-wise values are placeholders until it is.
3. The sign of I_circ is defined in the plotted frame (x to the right, y upward). Its handedness in the camera view or in the laboratory is **not confirmed** anywhere in the repo (section 4, Gap G1).
4. I_asym is an absolute value, split at the mid-point of the vector grid, and the central row of vectors is counted entirely in one half (section 3).

Conventions used in this sheet
- Paths are relative to the repo root. Line numbers are those of the working tree on 2026-11-22 (branch `cfd-campaign`, HEAD b8295ed). `git status` shows no uncommitted change in any code, config, metadata or old-manuscript file cited here; `doc/settled_and_retracted.md` has uncommitted edits, so its line numbers are those of the working tree.
- Short names: basic.m = `src/metrics/compute_frame_metrics_basic.m`; circ.m = `src/metrics/compute_frame_metrics_circ.m`; bands.m = `src/metrics/assign_depth_bands.m`; s30/s31/s32/s40 = `scripts/s30_compute_metrics.m`, `scripts/s31_map_waterlevel.m`, `scripts/s32_aggregate_band_metrics.m`, `scripts/s40_make_paper_figures.m`; defaults.m = `config/metrics_defaults.m`; constants.m = `config/constants.m`; primer = `doc/metrics_primer.md`; pivcond = `doc/piv_conditions.md`; qdip = `doc/qdip_jet_check.md`; settled = `doc/settled_and_retracted.md`; old methods / old results = `paper/2026_journal_Shonai/sections/methods.tex` / `results.tex` (frozen, raw material only).
- Authority: the implementation (`src/metrics/*.m`, `config/metrics_defaults.m`) is the source of truth for definitions (`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:157`). The primer is an explanation and says so itself (primer:5-9).
- "CSV check" = arithmetic done in this task with python3 on `local/derived/metrics/<run>/frame_metrics.csv` (R0001-R0024) and `local/derived/metrics/band_metrics.csv`. These files are machine-local (not in git), were written on 2026-07-27, and are on the gauge depth axis. A CSV check confirms what the code did. It is not a new result and must not be quoted as one.
- "derived" = algebra or arithmetic of this sheet from the cited lines; the statement itself is not written in the repo.
- ASCII math: `<.>` = arithmetic mean over grid cells, `abs()`, `sqrt()`, `d/dx`.

## 0. Common ground: input field, domain, velocity scale

| item | value | source (file:line) |
|---|---|---|
| Pipeline | s30 computes the frame-wise E, phi_lv, I_asym (basic.m) and I_circ, I_rot (circ.m). s31 attaches depth, h/a and band to each frame. s32 aggregates per run and band and forms I_unst and the SNR flag | s30:2-11, :69-90; s31:2-14; s32:2-11 |
| Input field | Canonical `piv` struct: `piv.x`, `piv.y` (static 2-D grids), `piv.u`, `piv.v` (frames on dimension 3), taken from the PIVLab variables `u_filtered`, `v_filtered`, i.e. after the validation filters and with rejected vectors interpolated; not the PIVLab-smoothed field (the importer loads only the `*_filtered` variables, `:43-53`; what PIVLab stores in them is taken from pivcond and was not checked against PIVLab itself). Units must contain m/s or the import stops | `src/io/import_pivlab_result.m:7-9`, `:43-53`, `:67-71`, `:84-92`; pivcond:28-30 |
| Frames used | Every PIV field of the run. Frame time is `time_s = (frame_idx - 1) * dt_pair_s` | basic.m:51-57; image-pair interval per level in pivcond:160-167 |
| Vector grid | 92 x 61 nodes (x by y) = 5612 vectors, spacing 16 px = 31.47 mm; extent x = 0.0452-2.9087 m, y = 0.0413-1.9293 m | pivcond:44-48; constants.m:106-115 (rounded to 0.045-2.909, 0.041-1.929, 0.0315); CSV check: `n_total` = 5612 in every frame of all 24 runs |
| Analysis domain Omega | The whole vector grid. No geometric mask and no port mask | pivcond:233; basic.m:86 (the only mask is "u and v finite"); old methods:130 |
| Area of Omega | 5.41 m^2 as the node-to-node extent (2.8635 m x 1.8880 m = 5.406 m^2), i.e. 93.3% of the plan area 5.7918 m^2 | old methods:130; derived from pivcond:48 and constants.m:24 |
| Area mean `<.>` | Unweighted arithmetic mean over the grid nodes that are valid. The grid is uniform, so this is an equal-area mean | basic.m:86, :99-104; circ.m:11, :95-100 |
| Invalid vectors | A cell is valid if u and v are both finite. Invalid cells are dropped from the numerator and the denominator (no zero fill) | basic.m:86-88, :98-99 |
| Invalid vectors in practice | None. PIVLab interpolates rejected vectors (`interpol_missing` on) and no mask is set (typevector 0 share 0% in the five inflow runs tabulated in pivcond), so the valid fraction is 1 everywhere | pivcond:30, :201-214; CSV check: minimum `valid_fraction` = 1.0000 and minimum `typevector_nonzero_fraction` = 1.0000 over all frames of R0001-R0024 (the second check was added by the audit: no vector is masked in any of the 24 runs) |
| Share of interpolated vectors | Inflow 1-3% (typevector = 2): R0001 2.86%, R0005 1.77%, R0006 1.32%, R0007 1.26%, R0008 0.95%. Not measured for the other inflow runs or for outflow | pivcond:201-219 |
| Port velocity scale U_p | U_p = Q_n / (a b), with Q_n the **nominal** discharge of the run's flow level (`nominal_Q_Lps` in `metadata/runs.csv`), a = 0.055 m, b = 0.11 m | s30:46-58; `metadata/runs.csv:1` (column), `:3-26`; `metadata/flow_levels.csv:2-4`; constants.m:43-45; `paper/2026_journal_Shonai/jhr/notation.tex:25` |
| U_p values | low 0.04132, medium 0.08264, high 0.12397 m s^-1 (Q_n = 0.25, 0.50, 0.75 L s^-1; a b = 0.00605 m^2). Same value for inflow and outflow and for all repetitions of a level | derived from s30:58; primer:25 gives medium = 0.0826; CSV check (threshold column = 0.2 x these values in all 24 runs) |
| Stated reason for the nominal value | "a fixed design value per level, so thresholds and normalized indices are comparable across repetitions and flow rates" | s30:47-50; primer:23-25 |
| Run-average discharge is not used in s30-s32 | Measured run averages are 0.75-0.89 of nominal for inflow (level means low 0.219, medium 0.392, high 0.623 L s^-1) and 0.78-1.00 for outflow | settled:16; qdip:50-51; primer:26-29 |
| Consequence of the nominal scale (derived) | Relative to the run-average port velocity, the inflow low-velocity threshold factor is 0.228 / 0.255 / 0.241 (low / medium / high) instead of 0.2, and I_circ and I_rot would be 1.14 / 1.28 / 1.20 times larger if normalized by the run-average U_p. The factor differs between levels by up to 12% | derived from settled:16 and s30:58 |
| Where the parameters of a run are recorded | `opts` struct saved in `frame_metrics.mat` (U_p_m_s, low_speed_threshold_m_s, alpha_u_th, smooth_sigma_circ); the threshold is also a column of `frame_metrics.csv` | s30:21, :59, :64, :93; basic.m:70, :146 |
| Driver scripts are templates | `s30` and `s31` hold a placeholder run ID (`s32` has none: it loops over every run of `runs.csv`); per-run copies are run from `tmp/`. The CSV checks in this sheet confirm alpha and U_p for all 24 runs | s30:20; s31:25; s32:45-46; `AGENTS.md:137-142` |

## 1. E -- area-mean squared surface speed

| item | value | source (file:line) |
|---|---|---|
| Formula | E(t) = <u^2 + v^2>_Omega = (1 / N_valid) * sum over valid cells of (u^2 + v^2). Units m^2 s^-2. No factor 1/2 | basic.m:99, :104 |
| Cells | All cells with finite u and v (5612 of 5612 in practice, section 0) | basic.m:86, :98-99 |
| Normalization | None. E is computed and stored dimensional | basic.m:104; primer:40-45 |
| Companion columns | `mean_speed` = <sqrt(u^2 + v^2)>, `rms_speed` = sqrt(E) | basic.m:100-103 |
| Comparison across flow levels | The primer requires E / U_p^2 for this and names two normalizations with different purposes (nominal Q: common footing between condition labels; run-average Q: physical scaling), "state which one was used". s30-s32 compute neither | primer:44-45, :203, :211-217 |
| What the old figure did | s40 plots the dimensional `E_mean` pooled over flow levels and repetitions on a log axis | s40:51, :90-92, :138 |
| Noise floor | E_noise = 2.0e-7 m^2 s^-2 (see section 8) | constants.m:100-104 |

## 2. phi_lv -- low-velocity area fraction

| item | value | source (file:line) |
|---|---|---|
| Formula | phi_lv(t) = (number of valid cells with sqrt(u^2 + v^2) < u_th) / (number of valid cells). Strict inequality | basic.m:99-100, :106-108 |
| Threshold | u_th = alpha * U_p, alpha = 0.2, U_p on the nominal discharge (section 0) | s30:61-64; defaults.m:11-17 |
| Where alpha is set | `M.alpha_u_th = 0.2` in defaults.m:17; this is the value s30 reads (`opts = metrics_defaults()`). The same number is duplicated as `C.metrics.alpha_u_th` in constants.m:98, which s30 does not read | s30:21, :63; defaults.m:17; constants.m:98 |
| u_th values | low 0.00826, medium 0.01653, high 0.02479 m s^-1 | derived from s30:58, :63; CSV check: column `low_speed_threshold_m_s` = 0.008264 / 0.016529 / 0.024793 in all runs of the level, both modes |
| Why 0.2 | Fixed from the pilot analysis (2026-07): the inflow phi_lv resolves the h/a dependence (about 0.22 shallow to about 0.60 submerged), while the outflow surface stays below u_th almost everywhere (phi_lv about 1); the outflow saturation is reported as a finding, not as a defect of the metric | constants.m:90-98; primer:59-62; old methods:187 |
| Denominator | Number of valid cells, not a fixed Area(Omega). Identical here because every cell is valid | basic.m:107; section 0 |
| Function default (not used) | basic.m falls back to an absolute 0.02 m s^-1 if no threshold is passed. s30 always passes u_th | basic.m:28-29; s30:69-71 |
| Normalization | Dimensionless; depends on Q only through u_th | primer:204 |

## 3. I_asym -- left-right asymmetry index

| item | value | source (file:line) |
|---|---|---|
| Formula | I_asym(t) = abs(E_L - E_R) / (E_L + E_R), with E_L = <u^2 + v^2> over valid cells with piv.y < y_mid and E_R = <u^2 + v^2> over valid cells with piv.y >= y_mid. NaN if E_L + E_R is not finite or not positive | basic.m:113-130 |
| Absolute or signed | **Absolute** (unsigned), taken per frame before any time averaging. The band value is the mean of the per-frame absolute values | basic.m:129; s32:25, :87; primer:67-74 |
| Signed counterpart | Not a stored metric. E_left and E_right are written per frame, so a signed (E_L - E_R) / (E_L + E_R) can be formed afterwards; `scripts/checks/branch_sign_tests.py` does so ("+ = more energy at small y") | basic.m:143-146; `scripts/checks/branch_sign_tests.py:20-28`; `paper/2026_journal_Shonai/jhr/notation.tex:58` |
| Direction of the split | Across y (the transverse direction). The mirror plane runs along x because the port sits at the centre of the short side wall | basic.m:18-22 |
| Meaning of the labels | L = the half with the smaller piv.y values (called "upper image half" in the header), R = the other half. They are not left and right of an observer | basic.m:20-22 |
| How the mid-line is chosen | y_mid = 0.5 * (min + max) of the finite piv.y values, i.e. the mid-point of the y extent of the vector grid. It is not L_y / 2 and not the port axis | basic.m:110-115, :212-224 |
| Numerical y_mid | 0.9853 m (= 0.5 x (0.0413 + 1.9293)); 0.985 m with the rounded constants | derived from pivcond:48; constants.m:114 |
| Offset from the basin centreline y = 0.981 m (= 1.962 / 2) | +0.0043 m, towards larger piv.y; 0.14 of the grid spacing, 0.22% of the basin width | derived from pivcond:48 and constants.m:22 |
| Same offset in the PIV coordinate scale (derived) | piv.y carries the single calibration factor 1.96669 mm px^-1, which is 0.24% too large in y (true 1.9620 mm px^-1). In piv.y coordinates the wall-to-wall mid-line is therefore at about 0.9833 m and the offset is about +0.002 m. Either way it is far below one grid spacing (31.47 mm) | derived from pivcond:35, :62, :70-76 |
| Central row | The grid has 61 rows in y, so y_mid falls on the central row (row 31, y = 0.9853 m). Because the R mask is `>=`, that row belongs to R: L = 30 rows (2760 cells), R = 31 rows (2852 cells) | basic.m:114-115; pivcond:47-48; CSV check: (E_R - E) / (E_R - E_L) = 0.49180 = 2760 / 5612 in every frame of all 24 runs |
| Consequence of the central row (derived) | E_L and E_R are means, so the unequal cell count does not bias by itself. But the row on the port axis, which holds the core of a straight jet, is counted entirely in E_R. A perfectly symmetric jet therefore gives E_R > E_L and I_asym > 0. The size of this floor has not been evaluated (Gap G3) | derived from basic.m:114-125 |
| Normalization | None needed: a ratio of two E values, so U_p and the calibration cancel | primer:75, :205 |
| What it does not tell | The direction of the bias. That is carried by the signed I_circ | primer:141-142; old methods:200 |

## 4. I_circ -- signed net circulation index

| item | value | source (file:line) |
|---|---|---|
| Formula | I_circ(t) = (a / U_p) * <omega>_Omega, with omega = dv/dx - du/dy | circ.m:4, :8, :61, :91-98 |
| Normalization | a = 0.055 m (passed by s30 from constants), U_p on the nominal discharge; a / U_p = 1.3310, 0.6655, 0.4437 s for low, medium, high | s30:56-58, :77-81; circ.m:61; CSV check: `I_circ / omega_mean` = 1.33100 / 0.66550 / 0.44367 in all runs of the level |
| Cells in the mean | All cells where omega is finite (5612 of 5612 in practice). With an invalid vector, omega would be NaN at every node whose stencil touches it and those nodes would be dropped | circ.m:95-98; section 0 |
| Finite-difference scheme | MATLAB `gradient(F, dx, dy)`: central differences (F(i+1) - F(i-1)) / (2 h) at interior nodes, one-sided differences at the edge rows and columns | circ.m:88-93 |
| Grid spacing | dx = mean(diff(piv.x(1,:))), required positive; dy = mean(diff(piv.y(:,1))), signed. Both 31.47 mm (16 px) in magnitude. The central stencil spans 62.9 mm, the size of the final interrogation window (32 px, 50% overlap) | circ.m:148-176; pivcond:24, :44-46 |
| Smoothing before differentiation | Available (NaN-aware Gaussian, sigma in grid cells) but **off**: sigma = `M.smooth_sigma_circ` = 0 | circ.m:33-36, :79-86, :131-146; defaults.m:27-31; s30:80; primer:90-91 |
| Signed | Yes. The band value is the signed mean over the frames of the band | circ.m:97-98; s32:25, :87 |
| Derived property of the estimator | With this difference scheme, no NaN and sigma = 0, the sum of dv/dx over the N nodes of a row telescopes to (3 v_N - v_(N-1) - 3 v_1 + v_2) / (2 dx) (the row mean is this divided by N), and likewise for du/dy along a column. I_circ therefore depends only on the tangential velocity in the two outermost rows and columns of the grid (nodes within about 0.03-0.08 m of the walls): it is, to within the discretization, the circulation around the perimeter of Omega divided by its area (discrete Stokes theorem), scaled by a / U_p | derived from circ.m:91-98; checked numerically in this task with the same scheme on a random 61 x 92 field (difference 3e-17); repeated by the audit with the closed form above (area mean of omega against the closed form, difference 3e-17) |
| Sign convention, code header (verbatim) | "positive I_circ = net counterclockwise rotation in the (piv.x rightward, piv.y increasing with row) coordinate system. If piv.y increases downward (image convention), positive I_circ is clockwise in physical (y-upward) space. Confirm the piv.y direction for your dataset." | circ.m:19-22 |
| Sign convention, mathematics (derived) | With dx > 0 and dy signed, omega is the vorticity in the right-handed (piv.x, piv.y) system whatever the row order, provided v is the velocity component along +piv.y. Positive is then counterclockwise in any drawing with piv.x to the right and piv.y upward | derived from circ.m:91-93, :148-176 |
| Is the plotted frame y-upward? | Yes for the band-mean field figures: `hold on` (:36) precedes `YDir normal` (:39) and `imagesc` (:47), x is to the right, and (u, v) are drawn with `quiver` on those axes. The figure of the old manuscript made by this function shows y increasing upward from 0 to 2 m (seen by the audit). **Not established for the quiver movie (unverified by audit):** the code sets `YDir normal` at :95, but the `imagesc` call at :99 comes while `hold` is still off (`hold on` is at :100), and a high-level `imagesc` call in MATLAB normally resets the axes to `YDir reverse`. MATLAB was not run, so do not cite the movie for the orientation | `src/viz/plot_band_mean_fields.m:36-39`, `:46-47`, `:58`; `paper/2026_journal_Shonai/fig/R0001_band_mean_field.png`; `src/viz/make_piv_quiver_movie.m:95`, `:99-101` |
| Statements of the convention elsewhere | "I_circ > 0 is counterclockwise in the (x right, y up) analysis frame of the band-mean field figures, i.e. the jet attached to the y < y_port sidewall" | s40:148-150; same in old methods:223; old results:74-75, :88 |
| Other mentions | primer:92 (the sign depends on the direction of piv.y, see the code header); primer:145-147 (R0006 clockwise, I_circ < 0; R0008 counterclockwise, I_circ > 0). `paper/README.md:114-115` gives the signs only (low 4/4 positive, high 4/4 negative, medium 3 negative and 1 positive) and names no frame | as cited |
| Internal consistency | Old results put the port at the centre of the left short wall and report that the jet of R0001 (low, positive) deflects to the small-y side; a jet on the small-y wall drives counterclockwise flow in a y-up drawing. The second indicator sign(E_L - E_R) (+ = more energy at small piv.y) agrees with the sign of I_circ in 12 of 12 inflow runs. Both agree with "positive = counterclockwise in the (x right, piv.y up) frame = jet on the small-piv.y wall", and the second supports indirectly that v points along +piv.y. Audit: the 12 of 12 agreement was recomputed from the CSV files; in the band-mean figure of R0001 (y upward; mean I_circ over B3 + B4 = +0.0068) the jet runs to the small-y wall, the basin-scale circulation is counterclockwise, and the arrows follow the curved high-speed band, as they would not if v were reversed | old results:45-46, :50; `paper/README.md:135`; `scripts/checks/branch_sign_tests.py:20-34`; `paper/2026_journal_Shonai/fig/R0001_band_mean_field.png`; CSV check |
| Direction of piv.y in the camera image | The header of basic.m calls the small-piv.y half the "upper image half", i.e. piv.y increases down the image. If that holds, the y-up figures are a vertical mirror of the camera image and positive I_circ is **clockwise** in the camera view | basic.m:20-21; circ.m:21-22 |
| Physical handedness | **Unconfirmed.** No file in git records the PIVLab axis setting, the orientation of the rectified image relative to the laboratory, or which physical side wall lies at small y (Gap G1, G2) | rectification click order only: `src/piv/select_rectification_points.m:31-35` |
| Per-run reduction (branch sign, lock strength, sign persistence) | Outside this sheet; implemented in `src/metrics/compute_branch_statistics.m` over the pooled frames of B3 + B4 | `src/metrics/compute_branch_statistics.m:11-15`, `:27-34` |

## 5. I_rot -- rotation activity index

| item | value | source (file:line) |
|---|---|---|
| Formula | I_rot(t) = (a / U_p) * <abs(omega)>_Omega | circ.m:5, :99-100 |
| omega, cells, differences, smoothing, normalization | Identical to I_circ: same omega field, all 5612 nodes, central differences with one-sided edges on the 31.47 mm grid, sigma = 0, a / U_p on the nominal discharge | section 4; CSV check: `I_rot / omega_abs_mean` = 1.33100 / 0.66550 / 0.44367 |
| Purpose | <omega> is near zero both without rotation and when counter-rotating cells cancel; <abs(omega)> stays large only when rotation is present | circ.m:13-17; primer:86-88 |
| Unlike I_circ | It depends on the whole field, not only on the perimeter (compare the derived property in section 4) | derived from circ.m:99 |
| Sensitivity | A derivative quantity: sensitive to resolution and smoothing | primer:90, :206 |
| Standing | Written by s30 and labelled "Primary" in the old manuscript table; the list of primary metrics in `AGENTS.md` does not name it | s30:87-90; old methods:283-286; `AGENTS.md:148-153` |

## 6. I_unst -- band-wise unsteadiness index

| item | value | source (file:line) |
|---|---|---|
| Formula | I_unst(B_k) = std{E(t) over the frames with band_id = B_k} / mean{E(t) over the same frames}: the coefficient of variation of the dimensional E within the band. NaN if the mean is not finite or zero | s32:99-106 |
| Standard deviation | MATLAB `std(vals, 0, 'omitnan')`: sample standard deviation, divisor N - 1. The mean is `mean(vals, 'omitnan')` | s32:87, :89; CSV check: I_unst of `band_metrics.csv` reproduced from `frame_metrics.csv` with divisor N - 1 (relative difference over the 96 run-bands: median 3e-15, maximum 3e-12; with divisor N the maximum is 1.6e-3; figures of the audit, which found the 3e-15 first given here to be the median, not the maximum) |
| Unit of evaluation | One value per run and band. Repetitions are not pooled in s32 | s32:5-11, :66-69 |
| Frames per band (current files, gauge axis) | Inflow B1 3527-4276, B2 1393-1979, B3 1584-2054, B4 2151-2723; outflow B1 505-1890, B2 311-1087, B3 372-1380, B4 514-1938 | CSV check (`n_frames`); primer:104-105 ("10^3 class") |
| Includes the within-band trend | Yes. Every change of E during the stay in the band counts, including a monotonic trend, so the value cannot be read directly as a fluctuation intensity | primer:101-103; old methods:245; qdip:94 |
| Values as computed (gauge axis) | Inflow B1 0.35-0.40, B2 0.08-0.13, B3 and B4 0.03-0.05 | old results:62; qdip:83 |
| What those ranges are | Ranges of the three flow-level means (each a mean of 4 runs): B1 0.354 / 0.399 / 0.385, B2 0.077 / 0.087 / 0.134 (low / medium / high). The per-run range is wider: B1 0.335-0.445 | CSV check |
| Values on the time-proportional axis | Inflow B1 0.28-0.33, B2 0.09-0.20, B3 and B4 0.05-0.10. The contrast between B1 and B3/B4 shrinks from "about one order" to "about 3-7 times" | qdip:83, :86 (one-off calculation, not a repo tool: qdip:59-62) |
| Detrended values, as reported | After removing a linear trend in time from E(t) within each band: inflow B1 0.09-0.19, B2 0.03-0.04, B3 and B4 about 0.02 | old results:64; qdip:94-96 (section dated 2026-10-26: qdip:8, :57) |
| Share of the trend in B1, as reported | "5-8 tenths" of the inflow B1 value is the linear trend | old methods:245; `paper/README.md:57`; settled:21 |
| Share of the trend in B1, other statement | "65-75%" | qdip:95 |
| B1 to B2 drop after detrending, as reported | "about 4 times" / "3-5 times"; the sharp drop survives | old results:64 / qdip:96 |
| Where strong short-time fluctuation remains | Only the high level at h/a = 0.7-0.9 | old results:64; qdip:96-97 |
| Outflow high B1 | 0.76 as computed, 0.42 detrended; the "about twice the inflow" comparison is kept | old results:121; qdip:97-98 |
| Cross-check of the detrended values (gauge axis) | Least-squares line of E against time_s over the frames of the band, residual standard deviation (N - 1) over the band mean. Level means: B1 0.085 / 0.130 / 0.190, B2 0.029 / 0.025 / 0.041, B3 0.021 / 0.018 / 0.018, B4 0.030 / 0.020 / 0.020 (low / medium / high). Per-run B1 0.074-0.217. Outflow high B1 runs 0.38, 0.41, 0.39, 0.50, mean 0.42. This reproduces the reported figures | CSV check (not a repo tool; do not quote) |
| Cross-check of the trend share in B1 | Share taken as 1 - (detrended value) / (value as computed), i.e. on the standard deviation: by level means 76% / 67% / 51% (low / medium / high); per run 42-78%. This supports "5-8 tenths"; "65-75%" does not cover the high level. Neither source says how the share was defined; taken on the variance instead, the same data give 66-95% per run (added by the audit) | CSV check |
| Axis of the detrended values | Gauge axis. The note lists the finding among points that hold "on either axis" (qdip:89) but gives numbers for the gauge axis only (Gap G5) | qdip:89-99 |
| Normalization | A ratio, so free of U_p and of the discharge | primer:101, :207 |

## 7. Depth bands B1-B4

| item | value | source (file:line) |
|---|---|---|
| Edges in m | B1 [0.030, 0.050), B2 [0.050, 0.060), B3 [0.060, 0.075), B4 [0.075, 0.100]. Half-open, except the deepest band, which includes its upper edge | `metadata/depth_bands.csv:2-5`; bands.m:51-63 |
| Edges in h/a | As tabulated: 0.55-0.91, 0.91-1.09, 1.09-1.36, 1.36-1.82. These are two-decimal roundings of 0.5455, 0.9091, 1.0909, 1.3636, 1.8182 (a = 0.055 m) | `metadata/depth_bands.csv:2-5`; derived with constants.m:45 |
| Labels | shallow (h < a); transition around h/a = 1; moderately submerged; clearly submerged | `metadata/depth_bands.csv:2-5` |
| Position of h = a | h = 0.055 m is the mid-point of B2 | derived from `metadata/depth_bands.csv:3` |
| Band abscissa used in the old figures | `h_over_a_mid` = mean of the two rounded h/a edges: 0.73, 1.00, 1.225, 1.59 | s32:79; CSV check (`band_metrics.csv`) |
| Depth of a frame, as implemented | **Gauge depth.** The logger record and the PIV record are taken as co-extensive and aligned by normalized time: logger sample i of N_w maps to (i - 1) / (N_w - 1), a frame to (t - t_min) / (t_max - t_min); the depth is linearly interpolated onto the frames; h/a = depth / a | bands.m:21-28, :38-49; s31:61-70 |
| Band of a frame, as implemented | By the value of that depth, band by band | bands.m:51-65 |
| Consequence 1 (gauge axis) | The reading is quantized to 1 mm and steps backwards, so the frames of a band need not be contiguous in time. In the current files B1 is non-contiguous in all 12 inflow runs and B2 in 11 of 12 (R0001: 239 backward steps in 9291 frames); in all 12 outflow runs the depth never steps backwards and every band is contiguous (extended by the audit from the two runs first checked, R0013 and R0021) | s31:27-29; CSV check |
| Consequence 2 (gauge axis) | A frame outside all bands gets an empty band and is dropped by s32. In the current files this happens in three inflow runs shortly after the start (within the first 15 s), where the interpolated gauge depth dips to 0.0290 m and stays just below 0.0300 m: R0005 7 frames, R0009 23, R0011 55 | bands.m:19, :54; s31:98-101; s32:68; CSV check |
| Definition for the manuscript | Bands are to be defined on the **time-proportional depth** (the straight line from 30 mm at the start to 100 mm at the end of the record); the gauge depth is reported alongside as a sensitivity check | `paper/README.md:61-63`; settled:20 |
| Implementation status | Not implemented: s31 has no depth option, and the band values and figures have not been recomputed | `paper/README.md:63`, `:167-168`; s31:64-79 |
| Under the time-proportional depth (derived) | h = 0.030 + 0.070 u for inflow (reversed for outflow), u the normalized frame time. The bands become fixed, contiguous fractions of the record: B1 2/7 = 28.6%, B2 1/7 = 14.3%, B3 1.5/7 = 21.4%, B4 2.5/7 = 35.7%. No frame can fall outside | derived from `metadata/depth_bands.csv:2-5` and `paper/README.md:61`; direction of the change agrees with qdip:84 (frames B1 -25 to -27%, B2 -15 to -19%, B3 +14 to +16%, B4 +40 to +45%) |
| Depth-axis evidence in full | See `paper/2026_journal_Shonai/jhr/evidence/methods_discharge_depth.md` section 6 | -- |
| Columns not consulted | `used_for_plot` and `used_for_metrics` of the band table are not read by s32 (all four are true) | s32:66; `metadata/depth_bands.csv:1-5` |

## 8. Band aggregation (s32) and the SNR flag

| item | value | source (file:line) |
|---|---|---|
| Unit | One row per run and band; repetitions stay separate and are pooled only when figures are made | s32:5-11 |
| What is averaged | Arithmetic mean over the frames of the band, NaN omitted, of E, phi_lv, I_asym, I_circ, I_rot, mean_speed, rms_speed, valid_fraction, depth_m, h_over_a, q_actual_Lps (columns `*_mean`). Each frame has equal weight | s32:22-26, :82-87 |
| Spread | Sample standard deviation (N - 1), NaN omitted, of E, phi_lv, I_asym, I_circ, I_rot (columns `*_std`) | s32:27, :88-90 |
| Signed and unsigned means | `I_circ_mean` is a signed mean over frames; `I_asym_mean` is a mean of per-frame absolute values | s32:25, :87; circ.m:98; basic.m:129 |
| I_unst | `E_std / E_mean` of the same row (section 6) | s32:99-106 |
| SNR | `E_snr` = `E_mean` / E_noise with E_noise = 2.0e-7 m^2 s^-2 | s32:29-32, :112; constants.m:104 |
| Flag | `E_resolved` = (E_snr finite and E_snr >= 3); the threshold `E_snr_min = 3` is set in defaults.m:22 | s32:113; defaults.m:19-22 |
| Meaning of the flag | A band with E_resolved false is resolution-limited: its E-based scalars (E, I_unst, I_rot, I_circ) are not to be interpreted quantitatively | s32:108-111; primer:46-48; constants.m:102-103 |
| Origin of the noise floor (verbatim) | "Measured PIV noise floor of E ... from the pilot batch: outflow-low runs sit at rms displacement ~0.06 px/frame ~ the PIV uncertainty, giving E ~ 2e-7" | constants.m:100-104 |
| What the constant is | The level of E in the outflow low runs themselves, taken to be noise because their displacement is at the sub-pixel accuracy; no independent noise measurement (for example PIV of still water) is recorded (Gap G6) | constants.m:100-104; pivcond:184-192; CSV check: outflow low E_snr = 0.49-1.15 in all 16 run-bands |
| One constant for all image-pair intervals (derived) | A displacement of 0.06 px is 1.25e-7 m^2 s^-2 at the outflow interval (0.3337 s) but 3.5e-7 / 1.4e-6 / 3.1e-6 m^2 s^-2 at the inflow intervals (0.2002 / 0.1001 / 0.0667 s). The constant is thus tied to the outflow interval; with a floor that is fixed in pixels the inflow SNR would be lower than tabulated, though still far above 3 | derived from pivcond:35, :160-167 and constants.m:100-104 |
| Flag in the current files (gauge axis) | Inflow: minimum E_snr 419, all resolved. Outflow resolved: high B1 (4 of 4 runs; E_snr 70.9, 49.5, 21.7, 5.8), high B4 (4 of 4; 5.0-7.5), medium B1 in 1 of 4 runs (R0020, 4.44). Everything else is unresolved | CSV check; compare old results:27 |
| Pooling at figure time (old figure) | Mean and sample standard deviation over the run-band rows of all repetitions and flow levels of a mode; open marker where E_resolved is false for the majority of contributing runs | s40:43-49, :90-94, :138 |
| Column not to be used | `q_actual_Lps_mean` (band-wise discharge from the level record) is still written but is retracted | s32:26; settled:17 |
| Row count | `band_metrics.csv` has 100 rows: 24 experimental runs x 4 bands plus 4 rows of a non-experimental run (C0001), which s40 removes before plotting | CSV check; s40:34-40 |

## Mismatches between the old manuscript and the code

Old manuscript = `paper/2026_journal_Shonai/sections/methods.tex` ("Metrics and regime classification", L163-295) and `results.tex`.

| # | old manuscript | code / data | sources |
|---|---|---|---|
| M1 | U_p = Q / (a b) without saying which Q; elsewhere "the actual discharge of each run was evaluated ... and used in the analysis" | The metrics use the nominal discharge of the level for U_p, hence for u_th, I_circ and I_rot. The run-average discharge enters none of s30-s32 | old methods:107-111, :182-187, :21 vs s30:46-58 |
| M2 | The basin is split "at the centreline" into Omega_L and Omega_R | Split at the mid-point of the y extent of the vector grid (0.9853 m in grid coordinates, which is the centre line of the rectified image and so the basin centre line; see the correction under section 3); the central row of vectors goes entirely to one half (30 vs 31 rows) | old methods:189 vs basic.m:113-115; section 3 |
| M3 | "The numerical differentiation and smoothing conditions needed for the vorticity were common to all conditions" | No smoothing is applied (sigma = 0). The scheme (central differences, one-sided at the edges, 31.47 mm spacing) is not stated | old methods:219 vs defaults.m:31, circ.m:83-93 |
| M4 | Positive I_circ is "counterclockwise in the analysis frame (x right, y up; the frame of the figures)", jet attached to the wall at y < y_port | Consistent with the plotting code. But the code header warns that positive is clockwise in physical space if piv.y increases downward, and basic.m describes small piv.y as the upper image half. The manuscript does not say that the figure frame may be a mirror image of the camera view | old methods:223 vs circ.m:19-22, basic.m:20-21, `src/viz/plot_band_mean_fields.m:39` |
| M5 | h(t) in the definition of I_unst is "the water depth at time t" | Gauge depth interpolated by normalized time; the manuscript is to use the time-proportional depth, which is not implemented | old methods:243 vs bands.m:38-49; `paper/README.md:61-63` |
| M6 | "5-8 tenths" of the inflow B1 value is the linear trend | The other record says "65-75%". CSV check: 51-76% by level means, 42-78% per run | old methods:245 vs qdip:95; section 6 |
| M7 | E_noise is presented as the noise floor "of this measurement system", equivalent to about 0.06 px per image pair | One constant taken from the outflow low runs; the conversion from 0.06 px depends on the image-pair interval, and at the inflow intervals it gives an E that is 3 to 25 times the value at the outflow interval | old methods:247 vs constants.m:100-104; section 8 |
| M8 | E is used for the residual-motion check (below 5% of the pre-stop value for 5 min), and runs "started from still water" | The two thresholds exist only as constants; no function or script uses them. "Started from still water" is retracted and must not be written | old methods:51, :126, :266 vs constants.m:117-119 (no other occurrence in `src/`, `scripts/`); `paper/README.md:85-87`; settled:30, :48 |
| M9 | "Every frame was assigned to a band; no frame fell outside" | 85 frames of three inflow runs are unassigned in the current files (R0005 7, R0009 23, R0011 55; interpolated gauge depth from 0.0290 m to just below 0.0300 m) and are dropped by s32 | old results:21 vs CSV check; bands.m:54; s32:68 |
| M10 | "All bands of outflow low and medium have SNR < 4.5 ... and were judged resolution-limited"; outflow high B1 "SNR about 37" | The flag is per run and band with the criterion SNR >= 3: R0020 (medium) B1 has 4.44 and is flagged resolved. "About 37" is the mean of four runs spanning 5.8-70.9 | old results:27 vs s32:113; CSV check |
| M11 | The port axis is at y = 1.0 m | The basin centreline is at 0.981 m (measured width 1.962 m); the jet-offset script uses 0.981 m | old results:45-46, :50 vs constants.m:22; `scripts/checks/jet_offset_by_band.py:9`, `:26` |
| M12 | The I_unst ranges (B1 0.35-0.40 etc.) read as ranges over conditions | They are ranges of the three flow-level means; per-run values spread more (B1 0.335-0.445) | old results:62 vs CSV check |
| M13 | phi_lv = Area(speed < u_th) / Area(Omega) | Fraction of valid cells; identical in practice because every cell is valid | old methods:176-181 vs basic.m:107 |
| M14 | I_rot is listed as a primary metric | `AGENTS.md` lists five primary metrics without I_rot | old methods:283-286 vs `AGENTS.md:148-153` |

Points where the old manuscript and the code agree (checked): I_asym as an absolute value (old methods:192, :200; basic.m:129); Omega = the whole vector grid without a port mask (old methods:130; pivcond:233); alpha = 0.2 (old methods:187; defaults.m:17); the band edges and their half-open form (old methods:92-95; bands.m:51-63); the SNR criterion of 3 (old methods:247; defaults.m:22); the factor a / U_p inside or outside the mean (old methods:210, :216; circ.m:98, :100).

Stale statements outside the manuscript, found on the way

| # | where | what | sources |
|---|---|---|---|
| S1 | primer, section 0 | Says Omega is a masked region that excludes the port vicinity. The code applies no mask; the primer itself says so further down | primer:30-31 vs primer:246-247, :268-269; pivcond:233 |
| S2 | primer, header | Names the equations of the old `methods.tex` as the authority for definitions; that file is now frozen | primer:5-9 vs `paper/README.md:70-71`; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:157` |
| S3 | basic.m header | Says the split is "about the basin's geometric symmetry plane y = Ly/2"; the code uses the grid mid-point | basic.m:18-19 vs basic.m:113 |
| S4 | defaults.m header | Calls the low-speed threshold "provisional"; a few lines below alpha is "fixed at 0.2 after the pilot analysis", and the value is hard-coded in two files | defaults.m:5-6 vs defaults.m:11-17; constants.m:98 |
| S5 | qdip, section 0 heading | Still headed "undecided: the depth axis"; the axis was decided on 2026-11-22 | qdip:30 vs settled:20 |

## Gaps

Each item is something the writer must leave as a placeholder or word around. None was hunted down.

| # | gap | why it matters for 2.5 | where the answer would come from |
|---|---|---|---|
| G1 | Physical handedness of positive I_circ: whether "counterclockwise" holds in the camera view from above or only in the y-up figure frame. Unknown: the direction of piv.y relative to the image rows as set in the PIVLab calibration, whether the rectified image is a true top view, and the confirmation that v points along +piv.y | The sign convention is the backbone of the branch result. Until confirmed, the sign can be defined only relative to the figure frame and to the wall at y < y_port | `local/work/<run>/PIVlab_setting.mat` (not in git), one raw frame against one plotted field, or the experimenter; circ.m:22 asks for exactly this check |
| G2 | Which physical side wall of the basin (as seen in the laboratory, for example left or right looking from the port into the basin) is the wall at small y | Needed to describe the two branches in physical terms and to look for a facility bias | experimenter; rectification record `local/work/<run>/rectification.mat` |
| G3 | Size of the I_asym floor caused by counting the central row (port axis) entirely in one half, and whether it matters for the signed energy-side index | A straight symmetric jet does not give I_asym = 0 as implemented; it also tilts the signed index towards the large-y half | recomputation with the central row excluded or split (not done) |
| G4 | All band-wise values on the time-proportional depth. `s31` has no depth option; the files hold gauge-axis values only | The manuscript defines the bands on the time-proportional depth; every band number in Methods or Results is a placeholder until recomputed | implementation in `s31`, then `s32` and `s40` (`paper/README.md:167-168`) |
| G5 | Detrended I_unst on the time-proportional axis, and a repo script for the detrending. The reported values are on the gauge axis; the procedure is described only as "remove the linear trend in time" | The weight given to I_unst depends on it (`paper/README.md:55-57`) | a small tool beside `s32`; qdip:59-62 states that the 2026-10-26 calculation was not made a repo tool |
| G6 | Basis of the noise floor: how 0.06 px and 2e-7 m^2 s^-2 were obtained, and whether one constant should serve all image-pair intervals. No independent noise measurement is recorded | The SNR flag decides which outflow bands may be read quantitatively. The outflow fields are also due to be re-processed with a longer image-pair interval (settled:31; `paper/README.md:137-139`, `:155`); since the constant is tied to the present outflow interval (section 8), the outflow SNR values and flags in this sheet are provisional (added by the audit) | pilot notes or a still-water PIV record, if one exists; otherwise state the floor as an estimate from the outflow low runs |
| G7 | Confirmation that sigma = 0 was the value actually used for all 24 runs. It is stored in `opts` inside each `frame_metrics.mat`, which has no CSV column; not read in this task | "No smoothing" is a stated parameter | `local/derived/metrics/<run>/frame_metrics.mat` (`opts.smooth_sigma_circ`) |
| G8 | Which discharge normalizes E if the manuscript reports E / U_p^2, and whether the manuscript keeps the nominal U_p for u_th, I_circ and I_rot as implemented. A decision, not a number | The run-average discharge is 0.75-0.89 of nominal and the ratio differs between levels (section 0) | paper-1 decision; primer:211-217 requires stating the choice |
| G9 | Noise contribution to I_rot (and to I_circ) from differencing unsmoothed vectors on the 31.47 mm grid, and any sensitivity test to sigma | I_rot is a mean of absolute values, so random error adds a positive offset | not documented; primer:90 and :206 only warn |
| G10 | Measurement uncertainty of any of the six metrics (propagated PIV error, repeatability within a run) | None is documented, so none can be stated | not in the repo |
| G11 | Share of interpolated vectors for the seven inflow runs not on this machine and for all outflow runs | The statement "1-3% interpolated" covers 5 inflow runs only | pivcond:218-219 (to be checked on the laboratory workstation) |
| G12 | Whether I_rot is a primary metric | `AGENTS.md` and the old manuscript differ (M14) | paper-1 decision |
| G13 | Whether the old convention of pooling band values over flow levels and repetitions is kept in the new figures, and with which E | The old figure pooled the dimensional E over three flow levels | paper-1 decision; s40:51, :90-94 |

## Audit (second reader)

Done on 2026-11-22 by a second agent, independently of the writer. Only this file was edited.

Method
- All 134 table rows of sections 0-8, of the mismatch table (M1-M14) and of the stale-statement table (S1-S5) were read against the lines they cite. Every cited file was opened at the cited lines: the five metric sources, `s30`-`s32`, `s40`, `metrics_defaults.m`, `constants.m`, the three metadata tables, the primer, pivcond, qdip section 0, settled, `paper/README.md`, the old `methods.tex` and `results.tex`, `import_pivlab_result.m`, the two plotting functions, `branch_sign_tests.py`, `jet_offset_by_band.py`, `compute_branch_statistics.m`, `select_rectification_points.m`, `notation.tex`, `AGENTS.md`.
- Every "CSV check" and every "derived" number was recomputed with python3 from `local/derived/metrics/<run>/frame_metrics.csv` (R0001-R0024) and `band_metrics.csv`, or by hand from the cited constants.
- The sheet was compared with `doc/settled_and_retracted.md` sections 1 and 2.

What was changed
1. Section 4, "Derived property of the estimator": the closed form was given as the row mean of dv/dx; it is the row sum (the mean carries a further factor 1/N). The conclusion (I_circ depends only on the two outermost rows and columns) stands and was reproduced numerically. "To within the discretization" was added to the Stokes statement.
2. Section 4, "Is the plotted frame y-upward?": confirmed for the band-mean field figures (code order and the PNG of the old manuscript). The same claim for the quiver movie was downgraded to **unverified by audit**: in `make_piv_quiver_movie.m` the `imagesc` call (:99) follows `YDir normal` (:95) with `hold` off, which normally resets the axis direction.
3. Section 4, "Internal consistency": audit evidence added (12 of 12 recomputed; the R0001 figure shows a counterclockwise basin-scale circulation with the jet on the small-y wall, and R0001 has positive I_circ).
4. Section 6, "Standard deviation": the relative difference 3e-15 is the median over the 96 run-bands; the maximum is 3e-12.
5. Section 6, "Cross-check of the trend share in B1": the definition of the share (on the standard deviation) was written out, with the variance-based figure beside it, because neither source defines it.
6. Section 0, "Driver scripts are templates": `s32` has no run ID; only `s30` and `s31` do.
7. Section 0, "Invalid vectors in practice": the typevector table of pivcond covers five inflow runs only; the CSV column `typevector_nonzero_fraction` (1.0000 in all 24 runs) was added as the evidence that covers every run.
8. Section 0, "Input field": source lines :43-53 added; the meaning of the PIVLab `*_filtered` variables is marked as taken from pivcond.
9. Section 7, "Consequence 1": the outflow statement was extended from two runs to all 12 (no backward step, every band contiguous).
10. Section 7, "Consequence 2", and M9: the depth of the unassigned frames reaches 0.029999 m in R0005, so "0.0290-0.0299 m" was reworded.
11. Gap G6: pointer added to the pending re-processing of the outflow fields (settled:31), which makes the outflow SNR values and flags provisional.

Recomputed and confirmed without change
- 5612 vectors and valid fraction 1 in every frame of the 24 runs; threshold column = 0.2 U_p (0.008264 / 0.016529 / 0.024793 m s^-1); a / U_p = 1.33100 / 0.66550 / 0.44367 s from both `I_circ / omega_mean` and `I_rot / omega_abs_mean`.
- (E_R - E) / (E_R - E_L) = 0.49180 = 2760 / 5612 in every frame of the 24 runs, i.e. 30 rows in L and 31 in R.
- y_mid = 0.9853 m in grid coordinates. **Corrected 2026-11-22 (main session, recomputed from the stored grid of R0007):** the grid rows sit at pixels 21-981 of the 1001-pixel rectified image, so y_mid is pixel 501, the image centre; with the walls mapped to pixels 1 and 1001 its true position is 500 x 1.962 mm = 0.981 m. The "+0.0043 m offset from 0.981 m" compares a grid coordinate (pixel index times the single scale 1.96669 mm) with a true length and is not a physical offset; area of Omega 5.406 m^2 = 93.3% of 5.7918 m^2.
- Threshold factors 0.228 / 0.255 / 0.241 and I_circ factors 1.14 / 1.28 / 1.20 relative to the run-average discharge.
- Frames per band; I_unst level means and per-run ranges; detrended level means (B1 0.085 / 0.130 / 0.190, B2 0.029 / 0.025 / 0.041, B3 0.021 / 0.018 / 0.018, B4 0.030 / 0.020 / 0.020), per-run B1 0.074-0.217; outflow high B1 0.38, 0.41, 0.39, 0.50 (mean 0.42; as computed 0.756); trend share 76 / 67 / 51% by level and 42-78% per run.
- Non-contiguous bands (B1 in 12 of 12 inflow runs, B2 in 11 of 12; R0001 239 backward steps in 9291 frames); unassigned frames 7 / 23 / 55 = 85.
- SNR: inflow minimum 419; outflow high B1 70.9, 49.5, 21.7, 5.8 (mean 36.9); high B4 5.0-7.5; R0020 B1 4.44; outflow low 0.49-1.15 in 16 run-bands; `band_metrics.csv` 100 rows of which 4 are C0001.
- Noise-floor conversions 1.25e-7 / 3.5e-7 / 1.4e-6 / 3.1e-6 m^2 s^-2; band edges in h/a; time-proportional band fractions 2/7, 1/7, 1.5/7, 2.5/7.
- The time-proportional figures quoted from qdip:83-84 were reproduced as level values (I_unst B1 0.28-0.33, B2 0.09-0.20, B3 and B4 0.045-0.10; frame counts B1 -25 to -27%, B2 -15 to -19%, B3 +14 to +17%, B4 +40 to +44%).

Not verified by the audit
- The orientation of the quiver movie (item 2 above). MATLAB was not run.
- Anything stored only in `.mat` files: `opts.smooth_sigma_circ` of each run (Gap G7), the direction of piv.y against the row index, the PIVLab axis setting (Gap G1). The sign convention therefore remains "counterclockwise in the y-up figure frame, jet on the small-y wall" and nothing more.
- What PIVLab writes into `u_filtered` and `v_filtered`; the sheet relies on pivcond:28-30 and :201.
- The "+0.002 m" offset in the PIV coordinate scale assumes that piv.y = 0 lies on the wall; the origin of the PIVLab coordinates is not recorded in git. **Corrected 2026-11-22:** there is no physical offset; see above.
- The size of the I_asym floor from the central row (Gap G3) was not computed.

Check against `doc/settled_and_retracted.md`
- No retracted statement is carried as valid. The still-water start (settled:48), the band-wise discharge `q_actual_Lps` (settled:17) and the old "no frame fell outside the bands" appear only as warnings (M8, section 8, M9).
- The depth axis (settled:20), the nominal-to-run-average ratio (settled:16) and the weight of I_unst (settled:21) are stated as settled there.
- No CFD result is used. C0001 is mentioned only as four non-experimental rows that `s40` removes; S1 cites the primer's comparison checklist only for the definition of Omega.

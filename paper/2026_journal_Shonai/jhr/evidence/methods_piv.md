# Evidence sheet -- Methods 2.4 "Surface particle image velocimetry"

Prepared 2026-11-22 for the JHR manuscript (paper 1). Evidence only; no manuscript text.

- Paths are relative to the repository root. `local/` is the gitignored, machine-local data root
  (this Mac); files under it are not in Git and may differ on the lab workstation (WS).
- Line numbers refer to the working tree on 2026-11-22. `doc/settled_and_retracted.md`,
  `literature/review_master.tex` and `cfd/campaign.md` had uncommitted edits at that time, so their
  line numbers can shift.
- "old manuscript" = `paper/2026_journal_Shonai/sections/methods.tex` (frozen source material, may be
  stale). "PC" = `doc/piv_conditions.md`, the designated authority for PIV settings
  (`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:156`; PC:3-5).
- Status vocabulary: **settled** (listed as settled in `doc/settled_and_retracted.md` or decided by
  the user), **recorded** (present in a record: setting file, manifest, code, constants, PC),
  **unverified** (stated somewhere but not backed by a record, contradicted elsewhere, or obtained
  only by arithmetic in this task), **GAP** (not recorded; leave a `\PH{...}`).
- "checked in this task" = read-only inspection with python (scipy / csv) of the per-run files under
  `local/work/` and `local/derived/` on this Mac. These are cross-checks of the record, not new
  results, and are not reproducible from a repo tool. Quote the recorded value, not the cross-check,
  unless the row says the record is silent.
- `cfd/campaign.md` is cited once, for an experimental fact only. No CFD result is in this sheet.
- Literature claims usable in 2.4 (PIVlab, LSPIV, PIV design rules, uncertainty) are in the sibling
  sheet `paper/2026_journal_Shonai/jhr/evidence/methods_literature.md` (sections 1.1-1.5). They are
  not repeated here.

**Read this first (four things the old manuscript and PC do not tell the writer).**

1. A third validation filter was on in all 24 runs: a correlation-coefficient filter, threshold 0.5.
   It is in the setting files and in `doc/qdip_jet_check.md:174`, but missing from PC section 1 and
   from the old manuscript (section 4 below, conflict C1).
2. The outflow fields were processed with an image-pair interval that gives 0.05-0.16 pixel of
   displacement (level values of PC:184-186; single runs reach 0.22 pixel in the cross-check of
   section 5). The re-analysis with a longer interval has NOT been done. Methods must describe the
   0.334 s processing that exists (section 6).
3. Algorithm, sub-pixel estimator and correlation-quality setting are recorded only as numeric codes
   (all = 1). Their names are a GAP until someone opens the setting in the PIVlab GUI once.
4. The noise floor of E was taken from the outflow-low runs themselves, not from a still-water
   recording, and its derivation is recorded in one code comment only (section 8).

## 1. Camera, video and rectification

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Camera arrangement | One fixed camera above the basin, viewing the whole basin | old manuscript `methods.tex:124` (only source) | unverified (frozen manuscript; no record) |
| Camera model, lens, mounting height, raw frame size, shutter | not recorded | no file read in this task records them; raw `piv.mp4` is not on this Mac (`local/raw/R0001/` holds `waterlevel.csv` only) | GAP |
| Source video frame rate | 29.97 Hz (manifest value 29.97002997 = 30000/1001) | `local/work/R0001/piv_manifest.csv:2` (`source_video_fps_hz`), same in R0002, R0005, R0006, R0009, R0013, R0017, R0021, R0024; PC:193; old manuscript `methods.tex:124`, `:145` | recorded |
| One PIV video per run | `piv.mp4` is the only input of the pipeline; a separate `timelapse.mp4` exists but is not used for PIV | `doc/piv_preprocessing_protocol.md:16-30`; `metadata/runs.csv:1` (columns `piv_video_file`, `timelapse_video_file`) | recorded |
| Rectification method | Projective transform fitted to four manually clicked points, the inner water-domain corners of the basin (order: top-left, top-right, bottom-right, bottom-left); applied to every frame with `imwarp` | `doc/piv_preprocessing_protocol.md:70-84`, `:108-113`; `src/piv/select_rectification_points.m:96-101`, `:127-128`, `:139-140`; `src/piv/prepare_piv_frames.m:92-94` | recorded |
| One transform per run | Corners are picked once per run on video frame 1 and reused for the whole run | `scripts/s10_prepare_frames.m:25-28`, `:133-141`; `local/work/<run>/rectification.mat` (`rect.frame_idx` = 1 in R0001, R0005, R0006, R0009, R0013, R0021, R0024; checked in this task) | recorded |
| Rectified image size | 1501 x 1001 pixel (Nx = round(3.0/0.002)+1, Ny = round(2.0/0.002)+1) | `src/piv/select_rectification_points.m:93-94`; `config/constants.m:29-38`; `scripts/s10_prepare_frames.m:137-139`; PIVlab setting `size_of_the_image` = [1001, 1501] in all 24 `local/work/<run>/PIVlab_setting.mat` (checked in this task); old manuscript `methods.tex:124`, `:146` | recorded |
| What the rectified image covers | The inner basin, 2.952 m x 1.962 m (measured inner dimensions) | PC:57; `config/constants.m:16-24`; `doc/settled_and_retracted.md:25`; old manuscript `methods.tex:147` | settled |
| True scale of the rectified image | x: 2952 mm / 1500 pixel intervals = 1.9680 mm per pixel; y: 1962 mm / 1000 = 1.9620 mm per pixel (corners are mapped to pixel centres 1 and 1501, 1 and 1001) | PC:62, PC:70-72; `src/piv/select_rectification_points.m:96-101` | recorded |
| Anisotropy of the rectified image | 0.31% between x and y; PC judges it negligible against other error sources | PC:70-72 | recorded |
| Scale used for velocities and coordinates | Single PIVlab calibration: reference length 2952 mm over 1501 pixel gives 1.96669 mm per pixel (`realdist` = 2952, `calxy` = 0.00196669 m per pixel; calibration points at x = 0.5 and 1501.5 pixel) | PC:35, PC:62; `local/work/<run>/PIVlab_setting.mat` keys `realdist`, `calxy`, `pointscali` (24 runs identical; checked in this task) | recorded |
| Error of that scale | -0.07% against the true x scale, +0.24% against the true y scale; velocity error within +/-0.25% | PC:62, PC:66-68 | recorded |
| "2 mm per pixel" label | `rect.pixel_size_m` = 0.002 only sets the output image size; it does not enter velocities or coordinates. The nominal 3.0 m x 2.0 m target grid is a processing choice, not basin geometry | PC:63, PC:66-68; `config/constants.m:26-38`; `src/piv/select_rectification_points.m:16-23` | recorded |
| Raw (pre-rectification) resolution | Clicked corners are 3045-3240 raw pixels apart along the long side and 2012-2121 along the short side, i.e. about 0.91-0.98 mm per raw pixel; the rectified image (1.97 mm per pixel) has about half the raw linear resolution. Corner coordinates reach x = 3583 (R0001), y = 2151 (R0011), so the raw frame is at least that large | `local/work/<run>/rectification.mat` (`rect.src_pts_px`; all 24 runs); arithmetic in this task and in the audit | unverified (computed, not in any record; the audit recomputed it over all 24 runs, the first pass had used 7) |
| Camera view between runs | The clicked corner positions differ between runs by up to about 220 raw pixels in x and about 65 in y (largest: top-right x = 3548 in R0007, 3330 in R0015). The inflow runs R0001-R0012 (recorded 16-22 April 2026) agree among themselves within about 60 pixels and the outflow runs R0013-R0024 (20 May-3 July 2026) within about 120 pixels; the two groups are offset (top-left x = 364-401 for inflow, 276-351 for outflow). This indicates that the view was not identical for all runs (the scatter of the manual clicks is included in these figures); each run has its own transform | same files as the row above (all 24 runs); `metadata/runs.csv` (column `date`); arithmetic in the audit | unverified (computed, not in any record). **Corrected by audit**: the first pass said "up to about 90 raw pixels" from the top-left corner of 7 runs; the other corners of the same 7 runs already differ by up to 176 |
| Interpolation used by the image warp | not set in the code (the call passes only the transform and the output view) | `src/piv/prepare_piv_frames.m:93`; `src/piv/select_rectification_points.m:140` | GAP (method not named in the record) |
| Elevation of the reference corners; effect of the level change on the scale | not recorded. The transform is fixed from frame 1 while the water surface moves through the analysed range of 30-100 mm, a change of at least 70 mm. The water level at frame 1 is itself an agreed placeholder (recording start at 20 or 30 mm for inflow) | no record; `scripts/s10_prepare_frames.m:27-28` shows only that frame 1 is used; `config/constants.m:52-54`; `paper/README.md:85-86` | GAP |
| Accuracy of the manual corner selection | not recorded | no record | GAP |

## 2. Image pre-processing before export

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Order of operations per frame | read frame -> projective rectification -> pre-processing -> write TIFF (no intermediate unrectified images) | `doc/piv_preprocessing_protocol.md:108-115`; `src/piv/prepare_piv_frames.m:83-100` | recorded |
| Pre-processing steps | (1) convert to greyscale, (2) flat-field: divide by a Gaussian-blurred copy of the frame, sigma = 30 pixel of the rectified image, (3) clip to the 1st-99th percentile and normalize to [0, 1], (4) invert intensity, (5) write as uncompressed 16-bit TIFF | `src/piv/preprocess_piv_frame.m:6-11`, `:18-26`, `:37-48`, `:65-66`; `src/piv/prepare_piv_frames.m:98-100`; `scripts/s10_prepare_frames.m:63-81`; `doc/piv_preprocessing_protocol.md:213-221` | recorded |
| Same options in all 24 runs | flat-field 'divide', sigma 30, clip [1 99], invert on, CLAHE off, median filter off, uint16, rectify first: identical in the per-run record of all 24 runs | `local/work/<run>/rectified_tif*/prepare_piv_frames_meta.mat` (variable `opts`, written by `src/piv/prepare_piv_frames.m:127`; 24 files checked in this task) | recorded |
| Why the inversion | "so particles appear bright" / "to make tracers bright" (so the tracers are darker than the background in the raw video) | `scripts/s10_prepare_frames.m:71-72`; `src/piv/preprocess_piv_frame.m:10` | recorded |
| PIVlab-internal image enhancement | all off: CLAHE off, high-pass off, Wiener filter off, intensity capping off; pre-processing was done only at the export stage, so nothing is applied twice | PC:31-34, PC:38-39; setting keys `clahe_enable`, `enable_highpass`, `wienerwurst`, `enable_intenscap` = 0 in 24 setting files (checked in this task) | recorded |
| Frame subsampling at export | every 6th / 3rd / 2nd source frame for inflow low / medium / high, every 10th for all outflow runs | `local/work/<run>/piv_manifest.csv:2` (`export_step_frames`); `local/work/<run>/rectified_tif*/prepare_piv_frames_meta.mat` (`opts.frame_step`: 6 for R0001-R0004, 3 for R0005-R0008, 2 for R0009-R0012, 10 for R0013-R0024; checked in this task) | recorded |

## 3. PIVlab processing

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Software | PIVlab (MATLAB); GUI settings saved per run as `PIVlab_setting.mat`, which is the authoritative record | `AGENTS.md:124-128`; PC:7-12; `doc/piv_preprocessing_protocol.md:140-147`, `:173` | recorded |
| PIVlab version, MATLAB version | not recorded | no key in the setting file names a version (80 keys listed in this task); `literature/review_master.tex:721` asks for the version to be stated in Methods | GAP |
| Settings identical across runs | All keys identical in the 24 runs except the image-pair interval | PC:14-17; re-checked in this task: of 80 keys only `PathName`, `time_inp`, `calu`, `calv` differ (`calu`, `calv` = `calxy` / interval) | recorded |
| Algorithm | `algorithm_selection` = 1. PC reads this as multi-pass FFT cross-correlation and adds that the GUI label must be confirmed once | PC:21 | unverified (numeric code only; name not in the record) |
| Pass 1 | window 128 pixel, step 32 pixel (75% overlap); 128 pixel = 251.7 mm | PC:22; arithmetic with PC:44 | recorded |
| Pass 2 | window 64 pixel, step 32 pixel (50% overlap); 64 pixel = 125.9 mm | PC:23 | recorded |
| Pass 3 (final) | window 32 pixel, step 16 pixel (50% overlap); 32 pixel = 62.9 mm | PC:24, PC:45 | recorded |
| Pass 4 | off (three passes) | PC:25 | recorded |
| Sub-pixel estimator | `subpix` = 1; name not recorded (PC: "GUI label to be confirmed once"). The PIVlab memo lists a Gauss 2x3-point and a 9-point peak estimator; which one code 1 denotes is not in the repo | PC:26; candidates from `literature/review_master.tex:710` ("ガウス 2x3 点 or 9 点"; the memo says no more than this) | GAP (numeric code only) |
| Correlation-quality setting | `CorrQuality_nr` = 1; name not recorded | PC:27 | GAP (numeric code only) |
| Repeat last pass | `repeat_last` = 0 (off) | PC:36 | recorded |
| Vector grid | 92 x 61 = 5612 vectors, spacing 16 pixel = 31.47 mm (constants round this to 31.5 mm) | PC:46-47; `config/constants.m:115`; `n_total` = 5612 in `local/derived/metrics/<run>/frame_metrics.csv` for all 24 runs (checked in this task) | recorded |
| Grid extent | x = 0.0452-2.9087 m, y = 0.0413-1.9293 m (measured from the canonical grid) | PC:48, PC:51-53; `config/constants.m:106-115` | recorded |
| Fields passed downstream | PIVlab's filtered fields (`u_filtered`, `v_filtered`, `typevector_filtered`), i.e. after validation and interpolation; no smoothed field is imported | `src/io/import_pivlab_result.m:43-53`, `:67-71`; `scripts/s20_import_piv_results.m:25-28`; `doc/piv_preprocessing_protocol.md:161-171` | recorded |
| Units | velocities are imported in m per s; an uncalibrated export is rejected | `src/io/import_pivlab_result.m:84-92` | recorded |
| Single interval per video | Each video was processed with one image-pair interval (variant `single_dt`); the dual-interval placeholders are unset | `scripts/s20_import_piv_results.m:58`, `:89`; `config/constants.m:81-83`; old manuscript `methods.tex:132` | recorded |

## 4. Vector validation and measured quality

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Standard-deviation filter | on, threshold 6 (standard deviations) | PC:28 | recorded |
| Local median filter | on, threshold 3 | PC:29 | recorded |
| Correlation-coefficient filter | on, threshold 0.5 (`do_corr2_filter` = 1, `corr_filter_thresh` = '0.5') in all 24 setting files. NOT listed in PC section 1 and not in the old manuscript | `local/work/<run>/PIVlab_setting.mat` (24 files checked in this task); `doc/qdip_jet_check.md:174` ("標準偏差 6σ, 局所中央値 3, 相関 0.5 のみ") | recorded (in the setting files; omitted from PC) |
| Velocity-limit filter | none | `doc/qdip_jet_check.md:174` | recorded |
| Brightness / contrast / notch filters | off (`do_bright_filter`, `do_contrast_filter`, `notch_filter` = 0) | `local/work/<run>/PIVlab_setting.mat` (24 files checked in this task) | recorded (setting files only; not in PC) |
| Interpolation of rejected vectors | on (`interpol_missing`); the interpolation method is not named in the record | PC:30 | recorded (method name: GAP) |
| Mask | none in PIVlab: masked vectors (type 0) are 0% | PC:201-209 | recorded |
| Vector-type code | 1 = measured, 2 = interpolated after filtering, 0 = masked | PC:201 | recorded |
| Share of interpolated vectors, inflow | R0001 (low) 2.86%; R0005-R0008 (medium) 1.77%, 1.32%, 1.26%, 0.95%. Measured share 97.1-99.1% | PC:203-211. Audit recount over all frames of `local/work/<run>/pivlab_single.mat` (`piv.typevector` == 2): 2.84%, 1.76%, 1.31%, 1.26%, 0.95%; type 0 = 0% | recorded (5 of 12 inflow runs; confirmed by audit to within 0.02 percentage points) |
| Share of interpolated vectors, inflow low R0002-R0004 and inflow high R0009-R0012 | not measured (their fields are not on this Mac) | PC:218; `paper/README.md:134`, `:169` | GAP |
| Share of interpolated vectors, outflow | not measured; PC expects it to be much higher than for inflow | PC:218-219 | GAP |
| Local share near the jet | In the jet read-out region the valid-vector ratio (share of type-1, i.e. measured, vectors) was 0.92-0.94 at h = 32-38 mm and 0.97-0.98 at h = 44-50 mm (five inflow runs: R0001, R0005-R0008) | `doc/qdip_jet_check.md:138`, `:148-158`, `:176`; `scripts/checks/qdip_jet_check.py:147-148`, `:172` | recorded |
| Recorded quality columns are saturated | `valid_fraction` and `typevector_nonzero_fraction` equal 1.000 in every run because they are evaluated after interpolation and do not separate type 1 from type 2; the meaningful quantity (share of type 1) is not yet a pipeline output | PC:211-217, PC:247; `src/metrics/compute_frame_metrics_basic.m:86-88`, `:95`; minimum over all frames = 1.0000 in 24 runs (checked in this task) | recorded |
| Peak locking | not checked; PC recommends one check because the inflow displacement is about 1 pixel | PC:188-189 | GAP |

## 5. Image-pair interval, vector rate and particle displacement

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| How the interval is set | Frames are subsampled at export (section 2) and consecutive exported frames are paired (`pair_step_frames` = 1) | `local/work/<run>/piv_manifest.csv:2`; `doc/piv_preprocessing_protocol.md:177-188` | recorded |
| Interval, inflow low | 0.2002 s (6 source frames); PIVlab `time_inp` 200.2 ms | PC:162; `local/work/R0001/piv_manifest.csv:2`; setting files R0001-R0004 | recorded |
| Interval, inflow medium | 0.1001 s (3 frames); `time_inp` 100.1 ms | PC:163; `local/work/R0005/piv_manifest.csv:2`; setting files R0005-R0008 | recorded |
| Interval, inflow high | 0.0667 s (2 frames; manifest 0.0667333 s); `time_inp` 66.7 ms | PC:164; `local/work/R0009/piv_manifest.csv:2`; setting files R0009-R0012 | recorded |
| Interval, outflow (all three levels) | 0.3337 s (10 frames; manifest 0.3336667 s); `time_inp` 333.7 ms | PC:165-167; `local/work/R0013/piv_manifest.csv:2`, `R0017`, `R0021`, `R0024`; setting files R0013-R0024 | recorded |
| Same interval within a level | yes; `time_inp` is the only setting that differs between conditions | PC:16-17; setting files (checked in this task) | recorded |
| Setting file vs manifest | PC says they agree exactly in all 24 runs. They agree to four significant figures: PIVlab converted with 66.7 and 333.7 ms, the manifest holds 66.7333 and 333.6667 ms (velocity bias +0.05% for inflow high, -0.01% for outflow) | PC:173; setting keys `time_inp`, `calu`; manifests; arithmetic in this task | recorded (the 0.05% remark is computed in this task) |
| Effective vector rate | 4.995 / 9.990 / 14.985 Hz for inflow low / medium / high, 2.997 Hz for outflow (old manuscript rounds to 5, 10, 15, 3 Hz). One velocity field per exported frame after the first: N images give N-1 fields (R0001: 9292 images, 9291 fields; R0005: 10046 and 10045; R0009: 9591 and 9590; R0013: 4878 and 4877; R0021: 1751 and 1750) | `local/work/<run>/piv_manifest.csv:2` (`effective_sequence_fps_hz`); `src/metrics/compute_frame_metrics_basic.m:51-54` (time = (k-1) x interval); `local/work/<run>/rectified_tif*/frame_manifest.csv` and `local/derived/metrics/<run>/frame_metrics.csv` row counts (checked in this task); old manuscript `methods.tex:132` | recorded |
| Consecutive fields share an image | follows from the row above (pairs 1-2, 2-3, ...), so successive fields are not independent samples | same sources as the row above | recorded |
| Fields per run | inflow 9095-10869; outflow low 4877-6228, medium 2701-2803, high 1734-1785 | row counts of `local/derived/metrics/<run>/frame_metrics.csv` (24 runs; checked in this task) | unverified (computed in this task) |
| Recorded duration of the PIV series | inflow low 1821-1959 s, medium 1002-1088 s, high 640-679 s; outflow low 1627-2078 s, medium 901-935 s, high 578-595 s | last `time_s` of `local/derived/metrics/<run>/frame_metrics.csv` (checked in this task) | unverified (computed in this task) |
| PIV series vs level-logger length | within 0.3 s in four runs; R0006 differs by 6.2 s (0.6%) | `doc/qdip_jet_check.md:178-179` | recorded |
| Rationale, inflow | The product interval x nominal discharge is constant: 200.2 x 0.25 = 50.05, 100.1 x 0.50 = 50.05, 66.7 x 0.75 = 50.03 (ms L s^-1), which equalizes the particle displacement between levels | PC:158-171 | recorded |
| Rationale as stated by the experimenter | not recorded as a rule. The old manuscript says the interval was chosen per level from a pilot analysis; the R0001 manifest note says "export_step_frames=6 selected as the best setting" | old manuscript `methods.tex:132`; `local/work/R0001/piv_manifest.csv:2` (notes) | unverified |
| The product against the measured discharge | With the run-average discharge (0.219 / 0.392 / 0.623 L s^-1) the product is 43.8 / 39.2 / 41.6, i.e. constant within about +/-6% | arithmetic in this task from PC:162-164 and `doc/settled_and_retracted.md:16` | unverified (computed in this task) |
| Rationale, outflow | none recorded: the same 333.7 ms was used for all three levels, so the displacement varies threefold between levels | PC:165-171 | recorded |
| Typical displacement, inflow | 0.96 / 0.98 / 1.29 pixel for low / medium / high (mean surface speed x interval / 1.9667 mm), i.e. 0.030-0.040 of the final 32-pixel window | PC:177-183 | recorded |
| Typical displacement, outflow | 0.05 / 0.08 / 0.16 pixel for low / medium / high, i.e. 0.002-0.005 of the final window | PC:184-186 | recorded |
| Cross-check of the displacement | Mean over all frames of every run (24 runs): inflow 1.02 / 1.04 / 1.40 pixel (runs 0.97-1.44), outflow 0.055 / 0.080 / 0.17 pixel (runs 0.052-0.22). Inflow values are 6-8% above PC's; PC:177 names the band-table column `mean_speed_mean` but not how bands and runs were combined. Audit: PC's six values are reproduced exactly (0.96 / 0.98 / 1.29 and 0.054 / 0.076 / 0.157 pixel) by the unweighted mean of `mean_speed_mean` over the 16 band rows (4 runs x 4 bands) of each mode and level in `local/derived/metrics/band_metrics.csv`; weighting the same rows by their frame counts gives 1.02 / 1.04 / 1.39 and 0.055 / 0.081 / 0.172, in line with this row. PC's values therefore depend on the band assignment (gauge depth axis at present) | `local/derived/metrics/<run>/frame_metrics.csv` (`mean_speed`), `piv_manifest.csv` (`dt_pair_s`), `calxy`; `local/derived/metrics/band_metrics.csv` (`mean_speed_mean`, `n_frames`); arithmetic in this task and in the audit | unverified (computed in this task; recomputed by audit with the same result) |
| PC's own assessment, inflow | About 1 pixel is small for correlation analysis (rule of thumb: a quarter of the window = 8 pixel) but measurable; accuracy is then governed by the sub-pixel estimator | PC:188-189 | recorded |

## 6. Outflow: what was done, and what is pending

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| What was actually done | All 12 outflow runs were processed with a 0.334 s interval (10 frames, 3 Hz) and otherwise the same settings as inflow | PC:14-17, PC:165-167; setting files and manifests R0013-R0024 | recorded |
| Resulting displacement | 0.05-0.16 pixel, comparable to or below a typical sub-pixel accuracy (PC quotes about 0.05-0.1 pixel without a source) | PC:184-186, PC:190 | recorded (the 0.05-0.1 pixel figure itself is unverified) |
| PC's conclusion | The outflow velocity field is at the noise floor in principle; the cause is the choice of interval | PC:190-192 | recorded |
| Cross-project position | Outflow surface field is currently at or below the noise floor; cause is the image-pair interval; fixable by re-exporting from the same source video; no new experiment needed. State: open, fixable | `doc/settled_and_retracted.md:31`; `paper/README.md:137-139` | settled (as an open item) |
| Why it is fixable | The source videos remain at 29.97 Hz, so frames can be re-paired with a longer interval and re-processed | PC:193-194 | recorded |
| Interval proposed for the re-analysis | about 6.7 s (200 frames) for outflow low and about 2.0 s (60 frames) for outflow high to reach about 1 pixel | PC:194-195 | recorded (proposal, not done) |
| Caveat attached to the proposal | Quasi-steadiness is argued from a drainage time of the order of 1700 s; out-of-plane motion and the level change must be checked on one run first | PC:196-197 | recorded |
| The 1700 s holds for outflow low only | Recorded series: low 1627-2078 s, medium 901-935 s, high 578-595 s | section 5, row "Recorded duration" | unverified (computed in this task) |
| Has the re-analysis been done? | NO. It is an open action in PC and item 1 of the pre-submission list | PC:245-246; `paper/README.md:154-155`; `doc/settled_and_retracted.md:31` | settled (pending) |
| Outflow fields available on this Mac | Scalar time series (`frame_metrics.csv`) exist for all 12 outflow runs; the vector fields (`pivlab_single.mat`) do not | PC:218; `local/derived/metrics/R0013/frame_metrics.csv` ... `R0024` (checked in this task) | recorded |

## 7. Analysis domain

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Definition of the domain | The whole PIV vector grid, the same in all runs | PC:233; `doc/metrics_primer.md:246-248`; `config/constants.m:106-115` | recorded |
| Extent | x = 0.045-2.909 m, y = 0.041-1.929 m, spacing 31.5 mm | `config/constants.m:113-115`; PC:48, PC:51-53 | recorded |
| Area | 5.41 m^2 (span of the outer grid nodes: 2.8635 m x 1.8880 m = 5.406 m^2) | PC:233; old manuscript `methods.tex:130`; arithmetic in this task from PC:48 | recorded |
| Share of the basin plan area | 93.3% of 5.7918 m^2 by the node span (95.9% if each of the 5612 nodes is given a 31.47 mm cell) | arithmetic in this task from PC:46-48 and `config/constants.m:24` | unverified (computed in this task) |
| Margin to the walls | PC: 0.045 m at the port wall, 0.043 m at the far wall; 0.041 and 0.033 m at the side walls. **Audit note**: these four values subtract PIVlab coordinates (pixel index x 1.96669 mm, origin at pixel 0) from the true dimensions. In pixel terms the grid is centred in the rectified image: nodes at pixel 23 to 1479 of 1-1501 in x and 21 to 981 of 1-1001 in y (PIVlab coordinate / `calxy` in `local/work/R0001/pivlab_single.mat`, same in R0005-R0008), i.e. 22 pixel from either end wall and 20 pixel from either side wall. With the true scales of section 1 that is about 43 mm at both end walls and about 39 mm at both side walls | PC:74-75; `config/constants.m:106-109`; audit arithmetic from `piv.x`, `piv.y`, `src/piv/select_rectification_points.m:96-101` (walls at pixel 1 and 1501, 1 and 1001) and PC:62 | recorded in PC; the symmetric 43 / 39 mm is unverified (computed by audit). Safe wording: "about 40 mm from the walls" |
| Port mask | None. The code applies no geometric mask; every finite vector enters the average | PC:233; `src/metrics/compute_frame_metrics_basic.m:86`, `:99-104`; `doc/metrics_primer.md:268-269` | recorded |
| Area average | Unweighted mean over the grid nodes | `src/metrics/compute_frame_metrics_basic.m:99-104` | recorded |
| Share of the domain near the port | "under 1%", contribution to area means called negligible | PC:233; old manuscript `methods.tex:130`; `doc/metrics_primer.md:268-269` | unverified (the extent that counts as "near the port" is not defined in any record) |
| Scale of that statement | 1% of the domain is 0.054 m^2 (a square of 0.23 m); a b x b square at the port is 0.22%; a strip b x 0.15 m is 0.31% | arithmetic in this task from PC:48 and `config/constants.m:44` (port width 0.11 m) | unverified (computed in this task) |
| What PIV sees next to the port | Within x < 0.15 m the PIV does not capture the jet (surface speed about 0.01 m s^-1) | `doc/qdip_jet_check.md:135` | recorded |
| "The grid starts inside the wall boundary layer" | The old manuscript says the wall boundary layers are excluded because the grid starts about 45 mm inside the walls | old manuscript `methods.tex:130` (only source) | unverified (no record or estimate supports it) |
| Mid-line used for the left-right split | Mid-point of the grid's y range, y = 0.9853 m in PIVlab coordinates. **Corrected by audit**: the first pass set this against "the basin centre line 0.981 m", which suggests a 4 mm offset. There is none: 0.9853 m is pixel 501, the centre of the 1001-pixel rectified image, and the side walls sit at pixel 1 and 1001, so the split line coincides with the basin centre line (true distance 0.981 m from either side wall) as far as the corner selection is accurate. The 4 mm is the labelling of the coordinates (single scale 1.96669 mm per pixel, origin at pixel 0), not a physical offset. The grid has 61 rows and the middle row lies on the line: 30 rows fall below it and 31 on or above it (the middle row is counted with `Y >= yMid`; checked on the stored `piv.y` of R0001 and R0006) | `src/metrics/compute_frame_metrics_basic.m:110-115`; `doc/metrics_primer.md:76`; arithmetic from PC:46-48 and `src/piv/select_rectification_points.m:96-101` | recorded (code); the pixel arithmetic is unverified (computed by audit). Belongs to 2.5; listed because it follows from the grid |

## 8. Noise floor, SNR criterion, "resolution-limited"

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Noise floor of E | 2.0e-7 m^2 s^-2, one constant for all runs | `config/constants.m:100-104`; `doc/metrics_primer.md:46`; `scripts/s32_aggregate_band_metrics.m:29-31` | recorded |
| How it was obtained | "From the pilot batch: outflow-low runs sit at rms displacement ~0.06 px/frame ~ the PIV uncertainty, giving E ~ 2e-7". That comment is the whole record | `config/constants.m:100-103`; old manuscript `methods.tex:247` repeats it | recorded (one code comment) |
| Derivation details | not recorded: which runs and frames, which statistic, the date, and where the "PIV uncertainty" of 0.06 pixel comes from | no record | GAP |
| Not a still-water measurement | The record derives the floor from outflow-low runs, not from a recording of water at rest. (`literature/review_master.tex:836` speaks of a still-water noise floor; no such measurement is recorded for this experiment) | `config/constants.m:100-103`; `literature/review_master.tex:836` | unverified (do not describe it as a null-displacement test) |
| Consistency check | Outflow-low run means: E = 1.33e-7 to 1.83e-7 m^2 s^-2, rms displacement 0.062-0.073 pixel. 2.0e-7 corresponds to 0.076 pixel at 0.334 s; 0.06 pixel corresponds to 1.25e-7 | `local/derived/metrics/R0013/frame_metrics.csv` ... `R0016`; arithmetic in this task | unverified (computed in this task) |
| The floor is tied to the outflow interval | A displacement uncertainty maps to a velocity as 1/interval. 2.0e-7 m^2 s^-2 equals 0.046 / 0.023 / 0.015 pixel at the inflow low / medium / high intervals; a 0.076-pixel floor would be 5.6e-7 / 2.2e-6 / 5.0e-6 m^2 s^-2 there. The record does not discuss this | arithmetic in this task from `config/constants.m:104`, PC:35, PC:162-167 | unverified (computed in this task; the record is silent) |
| SNR | band-mean E divided by the noise floor | `scripts/s32_aggregate_band_metrics.m:108-112`; `doc/metrics_primer.md:46-47` | recorded |
| Criterion | A band is "resolved" if SNR >= 3 (`E_snr_min` = 3), otherwise "resolution-limited" | `config/metrics_defaults.m:19-22`; `scripts/s32_aggregate_band_metrics.m:32`, `:113`; `config/constants.m:102-103` | recorded |
| Why 3 | not recorded | no record | GAP |
| Meaning of "resolution-limited" | The E-based scalars of that band (E, unsteadiness index, rotation activity index, net-circulation index) are not interpreted quantitatively | `scripts/s32_aggregate_band_metrics.m:108-111`; `doc/metrics_primer.md:47-48`; old manuscript `methods.tex:247` | recorded |
| Time-mean fields under the floor | Averaging is assumed to suppress random noise by about 1/sqrt(N), so a weak coherent mean can emerge when instantaneous fields are near the floor | `src/metrics/compute_band_mean_field.m:6-9`; old manuscript `methods.tex:247` | unverified (assumes independent errors; successive fields share an image, section 5) |
| Present outcome of the criterion | Inflow: 48 of 48 band rows resolved (SNR 419-25574). Outflow: 9 of 48 resolved (high B1 4 of 4, high B4 4 of 4, medium B1 1 of 4); all outflow-low bands have SNR 0.49-1.15 | `local/derived/metrics/band_metrics.csv` (columns `E_snr`, `E_resolved`; file dated 2026-07-27, gauge depth axis; counted in this task) | unverified (computed in this task; will move when the depth axis is switched) |

## 9. Tracer particles and illumination

| fact | value | source (file:line) | status (settled / recorded / unverified / GAP) |
|---|---|---|---|
| Tracer type | not recorded | PC:235-238; `paper/README.md:88`, `:163-164`; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md:69-71`; `cfd/campaign.md:246` | GAP (agreed placeholder) |
| Representative particle size | not recorded | PC:239; same files | GAP (agreed placeholder) |
| What is known about the tracers | Floating particles that follow the water surface (old manuscript); darker than the background in the raw image (the pre-processing inverts the image to make them bright) | old manuscript `methods.tex:126`; `scripts/s10_prepare_frames.m:71-72` | unverified (qualitative only) |
| "mm-scale tracers" | appears only as an assumption in the literature notes, not in any experimental record | `literature/review_master.tex:668`, `:723`, `:826` | unverified (do not use as a fact) |
| Seeding procedure and density | not recorded | no record | GAP |
| Illumination | not recorded; the old manuscript says only that illumination, background and camera set-up were kept constant in principle | PC:240; old manuscript `methods.tex:126` | GAP |
| Timelapse video | A second, timelapse video exists per run. The protocol and the old manuscript tie it to a check of quiescent initial conditions, which is retracted (the runs did not start from still water) | `doc/piv_preprocessing_protocol.md:20`; old manuscript `methods.tex:126`; `doc/settled_and_retracted.md:30`, `:48` | recorded (the "quiescent start" use: do not write) |

## Proposed content of the PIV settings table

Values are the recorded ones; `\PH{}` marks agreed placeholders. Pixel values refer to the rectified image.

| item | value |
|---|---|
| Source video frame rate | 29.97 Hz |
| Camera | `\PH{camera model, lens, raw frame size, height above the basin}` |
| Geometric correction | projective transform on the four inner corners of the basin, one transform per run |
| Rectified image | 1501 x 1001 pixel covering the inner basin, 2.952 m x 1.962 m |
| Image scale | 1.968 mm per pixel (x), 1.962 mm per pixel (y); velocities use a single calibration of 1.967 mm per pixel |
| Tracer particles | `\PH{type}`, `\PH{representative size}` |
| Illumination | `\PH{illumination}` |
| Pre-processing before export | flat-field division (Gaussian background, sigma = 30 pixel), clipping to the 1st-99th percentile, intensity inversion |
| Image enhancement inside PIVlab | none (CLAHE, high-pass, Wiener filter, intensity capping all off) |
| Software | PIVlab `\PH{version}` |
| Algorithm | `\PH{GUI name of algorithm code 1; PC reads it as multi-pass FFT cross-correlation}` |
| Interrogation windows | 128 -> 64 -> 32 pixel, three passes (final window 62.9 mm) |
| Window overlap | 75% (pass 1), 50% (passes 2 and 3) |
| Sub-pixel estimator | `\PH{GUI name of code 1}` |
| Vector grid | 92 x 61, spacing 16 pixel = 31.5 mm |
| Image-pair interval, inflow | 0.200 / 0.100 / 0.067 s (low / medium / high) |
| Image-pair interval, outflow | 0.334 s (all levels) |
| Vector rate | 5 / 10 / 15 Hz (inflow low / medium / high), 3 Hz (outflow) |
| Typical particle displacement | 0.96 / 0.98 / 1.29 pixel (inflow low / medium / high), 0.05 / 0.08 / 0.16 pixel (outflow low / medium / high) |
| Vector validation | standard-deviation filter (threshold 6), local median filter (threshold 3), correlation-coefficient filter (threshold 0.5) |
| Missing vectors | interpolated; 1-3% of vectors in the inflow runs examined (5 of 12) |
| Analysis domain | whole vector grid, x = 0.045-2.909 m, y = 0.041-1.929 m (5.41 m^2); no mask |
| Noise floor of E | 2 x 10^-7 m^2 s^-2 `\PH{how obtained, if more than "level of the outflow-low runs" is to be claimed}` |

Notes for the table: the row "Typical particle displacement" is not in the old table and is the one a
reviewer needs to judge the outflow data. If the outflow re-analysis is done before submission, the
two outflow rows and the displacement row change; nothing else does.

## Conflicts with the old manuscript

### A. Old PIV table (`methods.tex:136-161`) against `doc/piv_conditions.md`, row by row

| # | old table row (line) | old manuscript | `doc/piv_conditions.md` (or the setting files) | verdict |
|---|---|---|---|---|
| A1 | Source frame rate (`:145`) | 29.97 Hz | 29.97 Hz (PC:193) | same |
| A2 | Rectified resolution (`:146`) | 1501 x 1001 pixel, about 1.97 mm per pixel | calibration 1.9667 mm per pixel; true scale 1.9680 (x) and 1.9620 (y), 0.31% anisotropy; the 2 mm label is wrong but harmless (PC:35, PC:62-72) | consistent to three figures; the table omits the anisotropy and which scale the velocities use |
| A3 | Field of view (`:147`) | 2.952 m x 1.962 m, full basin | same dimensions (PC:57); the vector grid covers only x 0.045-2.909, y 0.041-1.929 m (PC:48) | same; grid extent not in the table |
| A4 | Geometric correction (`:148`) | projective transform, 4 inner corners | not covered by PC (see protocol and code, section 1) | no difference |
| A5 | Tracer type and size (`:149-150`) | "000" placeholders | not in any setting file; needs the experimenter (PC:235-239) | same gap; PC also lists illumination (PC:240), absent from the table |
| A6 | Software (`:151`) | "PIVlab (multi-pass cross-correlation)" stated as fact | `algorithm_selection` = 1, read as multi-pass FFT cross-correlation, "GUI label to be confirmed once" (PC:21); no version | the old table is more certain than the record; version missing in both |
| A7 | Interrogation window (`:152`) | 128 -> 64 -> 32 pixel, 3 passes | same (PC:22-25) | same |
| A8 | Window overlap (`:153`) | 75% (pass 1), 50% (passes 2-3) | same (PC:22-24) | same |
| A9 | Vector grid (`:154`) | 92 x 61, spacing 16 pixel = 31.5 mm | 92 x 61, 16 pixel = 31.47 mm (PC:46-47) | same after rounding. PC:227 still lists the manuscript as saying "about 33 mm": that entry is stale |
| A10 | Image-pair interval (`:155`) | 0.200, 0.100, 0.067 s (inflow), 0.334 s (outflow) | 200.2, 100.1, 66.7, 333.7 ms (PC:162-167) | same after rounding; the table omits the rationale (PC:169-171) and the displacement (PC:179-186) |
| A11 | Vector validation (`:156`) | standard-deviation filter (6 sigma) + local median filter, missing vectors interpolated | stdev 6, local median 3, interpolation on (PC:28-30) | the table omits the local-median threshold (it is in the text, `:128`). Neither the old table nor PC lists the correlation-coefficient filter (0.5) that is on in all 24 setting files |
| A12 | In-PIVlab enhancement (`:157`) | none (CLAHE, high-pass, Wiener, intensity capping off) | same (PC:31-34, PC:38-39) | same |
| A13 | Flat-field / contrast (`:158`) | divide flat-field (sigma = 30 px), 1-99% clip, invert, before export | flat-field division, 1-99% clip, inversion (PC:38-39); sigma = 30 is in the code and the per-run record, not in PC | same |
| A14 | (no row) | -- | `subpix` = 1, `CorrQuality_nr` = 1, `pass4` off, `repeat_last` off, calibration `realdist` / `calxy` (PC:25-27, PC:35-36) | not in the old table |
| A15 | (no row) | -- | measured displacement per condition (PC:179-186) and share of interpolated vectors (PC:203-209) | not in the old table |

### B. Old text of the PIV subsection (`methods.tex:121-134`, and `:247`) against the record

- **C1 (validation).** `methods.tex:128` names two filters. The setting files have three: the
  correlation-coefficient filter (threshold 0.5) is on in all 24 runs
  (`local/work/<run>/PIVlab_setting.mat`; `doc/qdip_jet_check.md:174`). PC section 1 omits it too.
- **C2 (purpose of the interval).** `methods.tex:132` says the interval keeps the typical particle
  displacement "in a range suited to correlation analysis". PC:184-192 shows 0.05-0.16 pixel for
  outflow, at or below sub-pixel accuracy, and calls the outflow field noise-floor "in principle".
  The old sentence cannot stand for outflow.
- **C3 (how the interval was chosen).** `methods.tex:132` says "chosen per flow level from a pilot
  analysis". PC:160-171: for inflow the product of interval and nominal discharge is constant; for
  outflow one interval was used for all levels, i.e. not chosen per level.
- **C4 (share of interpolated vectors).** `methods.tex:128` gives 1-3% for "the inflow condition".
  PC:203-209 has 0.95-2.86% from five runs (one low, four medium); no high-level run and no outflow
  run was measured (PC:218).
- **C5 (quiescent start).** `methods.tex:126` says a timelapse was taken to confirm the still-water
  starting condition. The still-water start is retracted (`doc/settled_and_retracted.md:30`, `:48`;
  `paper/README.md:85-87`). Do not carry this sentence.
- **C6 (noise floor).** `methods.tex:247` says the floor "was evaluated from the pilot analysis" at
  about 0.06 pixel per image pair. The record is one code comment that ties it to the outflow-low
  runs (`config/constants.m:100-103`); 2.0e-7 m^2 s^-2 corresponds to 0.076 pixel at the outflow
  interval, and 0.06 pixel to 1.25e-7 (arithmetic in this task). The old text also applies the single
  value to inflow runs whose interval is 1.7-5 times shorter (section 8).
- **C7 (1/sqrt(N)).** `methods.tex:247` claims noise suppression by about 1/sqrt(N) over "several
  hundred frames". Successive fields share an image (section 5), and
  `literature/review_master.tex:830` records that time-resolved series have far fewer effective
  samples than frames. No effective sample number is recorded.
- **C8 (wall boundary layer).** `methods.tex:130` says the wall boundary layers are not in the
  domain because the grid starts about 45 mm inside. No record supports this.
- **C9 (port share).** `methods.tex:130` and PC:233 say the port vicinity is under 1% of the
  domain; the extent of "vicinity" is defined nowhere (section 7).
- **C10 (effective rate).** `methods.tex:132` gives 5, 10, 15 and 3 Hz; the manifests hold 4.995,
  9.990, 14.985 and 2.997 Hz. Rounding only.

### C. Stale or conflicting statements in other repo files that touch 2.4 (do not copy)

- `doc/metrics_primer.md:30-31` says the experimental domain is a masked region that excludes the
  port vicinity. Its own section 4 (`:246-248`) and PC:233 say the domain is the whole grid with no
  mask. `literature/review_master.tex:287` ("port vicinity already excluded from the domain") and
  `doc/piv_preprocessing_protocol.md:273` (port region "can be masked") repeat the old plan.
- PC section 6 (PC:225-233) and section 7 (PC:238-240) cite manuscript line numbers (L121, L93,
  L113-114, L124, L123, L97, L116, L117, L95) that no longer match the frozen file; the rows are now
  at `methods.tex:154`, `:124`, `:146-147`, `:157`, `:156`, `:130`, `:149`, `:150`, `:126`.
- PC:116-118 and PC:148 still recommend the transit-time discharge; that is retracted
  (`doc/settled_and_retracted.md:42`). Not PIV, but it sits in the PIV record.
- PC:196 argues quasi-steadiness from a 1700 s drainage; that duration holds for outflow low only
  (section 6).
- "The outflow surface field is below the noise floor" (`doc/settled_and_retracted.md:31`,
  `paper/README.md:137`) is a blanket statement; by the SNR >= 3 criterion the present band table
  marks outflow-high B1 and B4 (and one medium B1) as resolved (section 8, last row). The writer
  should word the limitation through the displacement (section 5), which holds for all outflow runs.

## Gaps

Leave a placeholder for each; do not search or guess.

1. **Tracer particles**: type, material, representative size, seeding procedure and density
   (agreed placeholder; PC:235-239; `paper/README.md:88`, `:163`).
2. **Illumination**: light source and arrangement (PC:240).
3. **Camera**: model, lens, mounting height, raw frame size, exposure. Only the frame rate (29.97 Hz)
   is recorded.
4. **PIVlab version** (and MATLAB version).
5. **Names behind three numeric codes** in the setting file: `algorithm_selection` = 1, `subpix` = 1,
   `CorrQuality_nr` = 1 (PC:21, PC:26-27). One look at the PIVlab GUI with a setting file loaded
   closes all three. Also unnamed: the method PIVlab uses to interpolate rejected vectors.
6. **Outflow re-analysis** with a longer image-pair interval: not done (PC:245-246;
   `paper/README.md:155`). Methods must describe the existing 0.334 s processing and state its
   displacement. If the re-analysis is done, the outflow rows of the settings table, the displacement
   and the outflow validity statistics must be rewritten, and the single noise-floor constant must be
   reconsidered because it was derived at the 0.334 s interval.
7. **Share of interpolated vectors** for inflow low R0002-R0004, inflow high R0009-R0012 and all
   outflow runs (PC:218). Only five inflow runs are measured.
8. **Noise floor**: which runs, frames and statistic gave 2.0e-7 m^2 s^-2; the origin of the
   "about 0.06 pixel" PIV uncertainty; why the SNR threshold is 3; whether one constant in velocity
   units is meant to apply across the four image-pair intervals (`config/constants.m:100-104` is the
   only record).
9. **Rationale for the interval as the experimenter would state it** (constant product with the
   nominal discharge for inflow is an observed property of the settings, PC:169-171; the reason for
   one common interval in outflow is not recorded).
10. **Rectification details**: elevation of the four reference corners, the effect of the 30-100 mm
    level change on the image scale, accuracy of the manual corner selection, interpolation method of
    the warp.
11. **Definition of "port vicinity"** behind the "under 1% of the domain" statement, and any basis
    for the statement about wall boundary layers.
12. **Peak-locking check** for the inflow fields at about 1 pixel displacement: recommended in
    PC:188-189, not recorded as done.
13. **Effective number of independent samples** in a depth band (needed if the 1/sqrt(N) argument for
    time-mean fields is kept).
14. **Citation status**: whether PIVlab and the surface-PIV references may be cited is covered in
    `evidence/methods_literature.md`; this sheet adds no citation.

## Audit (second reader)

Audited 2026-11-22 by a second agent, independently of the first pass. Every repo file cited in
sections 1-9 and in "Conflicts" was re-opened at the cited lines. The per-run files under `local/`
(24 `PIVlab_setting.mat`, 24 `piv_manifest.csv`, 24 `rectification.mat`, 24
`prepare_piv_frames_meta.mat` and `frame_manifest.csv`, 24 `frame_metrics.csv`, `band_metrics.csv`,
and `pivlab_single.mat` of R0001 and R0005-R0008) were re-read with python, read-only, and every
number marked "computed in this task" was recomputed. No LaTeX, no MATLAB, no git state change.

### Changed in place

1. **Section 1, "Camera view between runs" (error).** The first pass said the clicked corners differ
   "by up to about 90 raw pixels". That is the top-left corner of 7 runs only; the other corners of
   the same 7 runs differ by up to 176 pixels, and over all 24 runs by up to about 220 pixels in x.
   Row rewritten with the 24-run figures and the inflow / outflow grouping.
2. **Section 7, "Mid-line used for the left-right split" (misleading).** The row set the split line
   (0.9853 m) against the basin centre line (0.981 m), which reads as a 4 mm offset. The 0.9853 m is
   pixel 501, the centre of the rectified image, so the split line is the basin centre line; the
   4 mm comes from the coordinate labelling. Row rewritten.
3. **Section 7, "Margin to the walls" (note added).** PC:74-75 gives 0.045 / 0.043 m and
   0.041 / 0.033 m. Those values subtract PIVlab coordinates from true dimensions. In pixel terms
   the grid is centred (22 pixel from either end wall, 20 pixel from either side wall), i.e. about
   43 mm and about 39 mm. PC's values are kept as the record; the audit arithmetic is added and
   marked unverified. `doc/piv_conditions.md` itself was not edited.
4. **Header item 2 and "Proposed content of the PIV settings table", row "Typical particle
   displacement".** Both said "0.05-0.2 pixel" for outflow. The recorded values are 0.05 / 0.08 /
   0.16 pixel (PC:184-186); 0.2 comes from the per-run cross-check (R0021: 0.22), which the sheet's
   own rule says not to quote in place of the record. Replaced by the recorded values.
5. **Section 1, "Elevation of the reference corners".** The row implied that frame 1 is at a water
   level of 30 mm. The level at the start of recording is an agreed placeholder
   (`paper/README.md:85-86`); the row now says so.
6. **Section 3, "Sub-pixel estimator".** "9-point (2D Gauss)" went beyond the memo, which says
   "ガウス 2x3 点 or 9 点" (`literature/review_master.tex:710`). Parenthesis removed.
7. **Section 1, "Raw (pre-rectification) resolution".** Recomputed over all 24 runs instead of 7
   (3045-3240 and 2012-2121 raw pixels; the 0.91-0.98 mm per raw pixel stands; largest y is 2151).
8. **Section 4, "Share of interpolated vectors, inflow".** Audit recount added (2.84 / 1.76 / 1.31 /
   1.26 / 0.95%, against PC's 2.86 / 1.77 / 1.32 / 1.26 / 0.95%). The "1-3%" statement stands.
9. **Section 4, "Local share near the jet".** Added that the ratio is the share of type-1 vectors
   (`scripts/checks/qdip_jet_check.py:147-148`, `:172`) and which five runs.
10. **Section 5, "Cross-check of the displacement".** Added how PC's table was obtained: it is
    reproduced exactly by the unweighted mean of `mean_speed_mean` over the 16 band rows of each
    mode and level. The 6-8% difference from the all-frame mean is the weighting, not an error.

### Confirmed without change (the statements a manuscript sentence would rest on)

- 80 keys per setting file; only `PathName`, `time_inp`, `calu`, `calv` differ between the 24 runs.
- Passes 128/32, 64/32, 32/16 pixel, pass 4 off, `repeat_last` 0; `algorithm_selection`, `subpix`,
  `CorrQuality_nr` all 1 and unnamed; no version key.
- Three validation filters in all 24 runs: standard deviation 6, local median 3,
  correlation coefficient 0.5 (`do_corr2_filter` = 1); interpolation on; brightness, contrast and
  notch filters off; CLAHE, high-pass, Wiener and intensity capping off.
- Calibration: `realdist` 2952, `calxy` 0.00196669 m per pixel = 2952 mm / 1501 pixel, calibration
  points at 0.5 and 1501.5 pixel, offsets 0; the 1.9680 / 1.9620 mm per pixel, -0.07% / +0.24% and
  0.31% figures.
- Manifests of all 24 runs: 29.97002997 Hz; export step 6 / 3 / 2 / 10; pair step 1; intervals
  0.2002 / 0.1001 / 0.0667333 / 0.3336667 s; the +0.05% and -0.01% remarks.
- Frame preparation identical in 24 runs (divide, sigma 30, clip 1-99, invert, no CLAHE, no median,
  uint16, rectify first); `rect.frame_idx` = 1 and 1501 x 1001 pixel in all 24 runs.
- Image and field counts (N images, N-1 fields), fields per run, durations of the series.
- Vector grid 92 x 61 = 5612, x = 0.0452-2.9087 m, y = 0.0413-1.9293 m, spacing 31.467 mm
  (`pivlab_single.mat` of five runs; `n_total` = 5612 in all 24 runs); area 5.406 m^2 and the
  93.3% / 95.9% shares; the 0.22% / 0.31% port-area figures.
- Displacement cross-check (inflow 1.02 / 1.04 / 1.40, outflow 0.055 / 0.080 / 0.17 pixel; run
  ranges 0.97-1.44 and 0.052-0.22).
- Noise-floor arithmetic: outflow-low E = 1.33e-7 to 1.83e-7 m^2 s^-2 and 0.062-0.073 pixel rms;
  2.0e-7 m^2 s^-2 = 0.076 pixel at 0.3337 s; 0.06 pixel = 1.25e-7; the per-interval equivalents.
- SNR counts from the present `band_metrics.csv`: inflow 48 of 48 (SNR 419-25574), outflow 9 of 48
  (high B1 4, high B4 4, medium B1 1), outflow low 0.49-1.15.
- All cited line numbers of the old manuscript (`methods.tex:124-134`, `:145-158`, `:247`), of
  `doc/piv_conditions.md`, `doc/piv_preprocessing_protocol.md`, `doc/qdip_jet_check.md`,
  `doc/metrics_primer.md`, `config/*.m`, `src/**/*.m`, `scripts/*.m`, `paper/README.md`,
  `doc/settled_and_retracted.md` and `literature/review_master.tex` (the eight cited lines, `:287`, `:668`, `:710`,
  `:721`, `:723`, `:826`, `:830`, `:836`, are in confirmed memos, not in an AI-DRAFT block; the
  sheet makes no literature claim of its own).
- Against `doc/settled_and_retracted.md`: no retracted statement is carried as valid. The
  still-water start, the transit-time discharge and the band-wise discharge appear only as "do not
  write". No CFD result is in the sheet; `cfd/campaign.md:246` is used for an experimental gap only.

### Could not be verified by the audit

- **Camera arrangement** ("one fixed camera above the basin"): old manuscript only. Stays unverified.
- **"Typical sub-pixel accuracy of about 0.05-0.1 pixel"** (PC:190) has no source in PC. A similar
  figure is in a confirmed literature memo (`literature/review_master.tex:825`); any citation must
  be taken from `evidence/methods_literature.md`, not from PC. Unverified by audit as a statement
  about this experiment.
- **Negative statements ("not recorded")** for camera, tracer, seeding and illumination: checked
  only by a keyword search of `doc/`, `metadata/` and the README files, which found nothing. The
  per-run `runlog.md` (required input per `doc/piv_preprocessing_protocol.md:28`; column
  `runlog_file` of `metadata/runs.csv`) and the raw videos are not on this Mac, so a record may
  exist on the lab workstation. The gaps stand; the run logs are where to look first.
- **Interpolated share** for R0002-R0004, R0009-R0012 and all outflow runs: no vector fields on
  this Mac. Stays a GAP.
- **That the three validation filters were applied to every frame with the recorded thresholds**:
  the setting file records the GUI state; the stored type-2 vectors (0.95-2.84%) show that
  validation and interpolation ran. Which filter rejected how many vectors is not recorded.
- **Stability of the mid-line row count** (30 / 31 rows): checked on R0001 and R0006 only. The
  middle row sits on the line to within single-precision rounding, so the split of that row is
  decided by rounding. Unverified for the other runs.

### Notes for the writer that fall outside this file

- `evidence/methods_literature.md`, row T2, describes the validation used here as two filters
  (standard deviation and local median). Per section 4 of this sheet there are three.
- `doc/piv_conditions.md` section 1 omits the correlation-coefficient filter, PC:74-75 gives wall
  margins in mixed coordinates, and PC:173 says "exact agreement" where the agreement is to four
  significant figures. PC is the designated authority, so these should be corrected there by its
  owner; this audit did not touch it.

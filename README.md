# psp-singleport-regime

Single-port reversible-basin experiments for pumped-storage reservoir surface-flow regime analysis.

## Overview

This repository contains the code, metadata, and project structure for a laboratory study of surface-flow regimes in a shallow rectangular basin with a single reversible inlet/outlet port. The project is motivated by pumped-storage upper reservoirs, but it is **not** intended as a strict scale model of a specific prototype. Instead, it is designed as a **prototype-informed laboratory experiment** to identify basin-scale flow regimes, mode asymmetry between inflow and outflow, transition around relative submergence \(h/a \approx 1\), and non-stationary behavior under outflow conditions.

The current paper scope is **flow-only**. Sedimentation and internal velocity measurements are outside the present scope and may be added in future studies.

## Research questions

The repository is organized around the following questions.

1. How different are the basin-scale surface-flow regimes under inflow and outflow, even though both use the same port geometry.
2. How does the relative submergence \(h/a\) control regime transition.
3. How can outflow unsteadiness be quantified beyond time-averaged vector fields.

## Experimental concept

- Basin plan dimensions: 3.0 m × 2.0 m
- Basin depth: 0.33 m
- Single reversible port at the center of the short side wall
- Port width: 0.11 m
- Port height: 0.055 m
- Water-depth range during recording:
  - Inflow: 0.03 m → 0.10 m
  - Outflow: 0.10 m → 0.03 m
- Flow-rate levels are controlled by nominal water-level change rates:
  - Low: 2.5 mm/min
  - Medium: 5.0 mm/min
  - High: 7.5 mm/min
- Corresponding nominal discharges:
  - Q1 = 0.25 L/s
  - Q2 = 0.50 L/s
  - Q3 = 0.75 L/s

Actual discharge may deviate from the nominal value, especially under shallow and partially free-surface conditions. Therefore, actual discharge is evaluated from recorded water-level time series and used in downstream analysis when needed.

## Analysis concept

The analysis is built around a unified pipeline.

- Video → MATLAB/PIVLab → canonical `.mat` format → metrics CSV
- Video → external PIV software → canonical `.mat` format → metrics CSV

The downstream analysis should not depend on whether the velocity field came from PIVLab or an external package. All inputs are normalized into a common MATLAB structure before metric computation.

The project keeps the option of a dual-\(\Delta t\) strategy for later use,
but the current routine workflow is **single-dt**: every run so far uses one
fixed frame interval end to end, and `piv.variant = "single_dt"` in the
canonical struct.

If a dual-\(\Delta t\) strategy is introduced later, the intended design is:

- A short frame interval to stabilize high-velocity regions.
- A long frame interval to improve sensitivity in low-velocity regions.
- A merged field, combining both, used for figures and metrics.

Such short/long frame-pair strategies should be kept explicit in
`piv_manifest.csv` and imported into canonical MATLAB outputs before
downstream metrics are computed.

## Primary metrics

The scientific target metrics are:

- \(E(t)\): basin-scale motion intensity
- \(\phi_{\mathrm{lv}}(t)\): low-velocity area fraction
- \(I_{\mathrm{asym}}(t)\): left-right asymmetry index
- \(I_{\mathrm{circ}}(t)\): circulation index
- \(I_{\mathrm{unst}}(B_k)\): band-wise unsteadiness index

The current `s30_compute_metrics.m` implementation computes the frame-wise
metrics available directly from `pivlab_single.mat`: `E(t)`,
`\phi_lv(t)`, and `I_asym(t)`, along with supporting speed and validity
columns. `I_circ(t)` and `I_unst(B_k)` are planned next-stage metrics.

Secondary metrics such as vortex-core location, dominant frequency, and supplementary vorticity maps may be used only when they provide reproducible physical insight.

## Repository policy

GitHub is used for:

- MATLAB code
- metadata tables
- project configuration templates
- documentation

The following are **not** stored in GitHub and should remain under the gitignored `local/` data root or another gitignored storage location.

- raw videos
- time-lapse videos
- water-level CSV files
- large intermediate `.mat` files
- derived figures and large result exports

## Recommended repository structure

```text
psp-singleport-regime/
├─ README.md
├─ .gitignore
├─ init.m
├─ config/
│  ├─ project_config_template.m
│  ├─ constants.m
│  └─ metrics_defaults.m
├─ metadata/
│  ├─ runs.csv
│  ├─ depth_bands.csv
│  └─ flow_levels.csv
├─ src/
│  ├─ io/
│  ├─ piv/
│  ├─ metrics/
│  ├─ qc/
│  └─ viz/
├─ scripts/
│  ├─ s10_prepare_frames.m
│  ├─ s20_import_piv_results.m
│  ├─ s25_preview_piv_movie.m
│  ├─ s30_compute_metrics.m
│  ├─ s35_plot_run_metrics_overview.m
│  └─ s40_make_paper_figures.m
└─ doc/
```

## Local Data Layout

By default, the repository uses a gitignored data root at `local/` under the repository root.

```text
local/
├─ raw/
│  ├─ R0001/
│  │  ├─ piv.mp4
│  │  ├─ timelapse.mp4
│  │  ├─ waterlevel.csv
│  │  └─ runlog.md
│  └─ ...
├─ work/
│  ├─ R0001/
│  │  ├─ rectification.mat
│  │  ├─ rectified_tif/
│  │  ├─ piv_manifest.csv
│  │  ├─ PIVlab_setting.mat
│  │  ├─ PIVlab_raw.mat
│  │  ├─ pivlab_single.mat
│  │  ├─ pivlab_proj/
│  │  └─ tmp_pivlab_long/
│  └─ ...
├─ derived/
│  ├─ piv/
│  ├─ metrics/
│  └─ qc/
└─ results/
    ├─ figures/
    ├─ tables/
    └─ drafts/
```

## Git workflow for one maintainer using two PCs

This repository assumes the following collaboration model:

- one maintainer edits code and metadata
- the maintainer may work from two different PCs
- students only pull updates and run the shared scripts on `main`

Recommended rules:

- treat `main` as a sync-only branch
- do not make code changes directly on `main`
- create one topic branch per task, for example `feature/frame-prep-cleanup`
- push that topic branch before moving to the other PC
- never rely on Git to sync `local/` data between PCs
- students should stay on `main` and update with `git pull --ff-only`

### Maintainer workflow

Start a new task on either PC:

```sh
git switch main
git pull --ff-only
git switch -c feature/frame-prep-cleanup
```

Commit and publish the work branch before changing PCs:

```sh
git add .
git commit -m "Refine frame prep workflow"
git push -u origin feature/frame-prep-cleanup
```

Resume the same task on the other PC:

```sh
git fetch origin
git switch main
git pull --ff-only
git switch --track origin/feature/frame-prep-cleanup
```

If the branch already exists locally on that PC, use:

```sh
git switch feature/frame-prep-cleanup
git pull --ff-only
```

When the task is ready for students, update `main` and fast-forward it:

```sh
git switch main
git pull --ff-only
git merge --ff-only feature/frame-prep-cleanup
git push origin main
```

If `git merge --ff-only` stops because the branch is behind `main`, rebase the work branch first:

```sh
git switch feature/frame-prep-cleanup
git rebase main
git switch main
git merge --ff-only feature/frame-prep-cleanup
git push origin main
```

### Student workflow

Students should not create code-editing branches unless explicitly asked. Their normal update command is:

```sh
git switch main
git pull --ff-only
```

### Important note about `local/`

Each PC has its own machine-local `local/` directory. Git keeps only the README files and placeholder `.gitkeep` files there.

Raw videos, TIFF sequences, PIVLab projects, temporary outputs, and local
MATLAB override files are not synchronized by Git. Daily/per-run script
settings live as disposable copies under the gitignored `tmp/` folder
(copy a script from `scripts/`, edit the copy, and run it from there). If
two PCs both need the same experiment data, copy or sync those files
outside Git using the lab's preferred storage method.

## Metadata tables

### `metadata/runs.csv`
Each row corresponds to one run.

Recommended columns:

- `run_id`
- `planned_order`
- `date`
- `operator`
- `mode`
- `flow_level`
- `nominal_dh_mm_min`
- `nominal_Q_Lps`
- `repetition`
- `start_depth_m`
- `end_depth_m`
- `raw_subdir`
- `piv_video_file`
- `timelapse_video_file`
- `waterlevel_file`
- `runlog_file`
- `piv_source`
- `run_status`
- `notes`
- `exclude_flag`

### `metadata/depth_bands.csv`
Representative depth bands used for visualization and regime comparison.

Suggested bands:

- B1: 0.03–0.05 m
- B2: 0.05–0.06 m
- B3: 0.06–0.075 m
- B4: 0.075–0.10 m

### `metadata/flow_levels.csv`
Nominal flow-rate levels.

- low = 2.5 mm/min = 0.25 L/s
- medium = 5.0 mm/min = 0.50 L/s
- high = 7.5 mm/min = 0.75 L/s

## Canonical MATLAB data structure

All PIV outputs should be converted to a common MATLAB structure, regardless of source.

Current minimal canonical fields for imported PIV are:

```matlab
piv.run_id
piv.source        % 'pivlab' or 'external'
piv.variant       % 'single_dt', 'short', 'long', or 'merged'
piv.x
piv.y
piv.u
piv.v
piv.typevector

piv.meta.source_video_fps_hz
piv.meta.effective_sequence_fps_hz
piv.meta.export_step_frames
piv.meta.pair_step_frames
piv.meta.dt_pair_s
piv.meta.calxy
piv.meta.calu
piv.meta.calv
piv.meta.units
piv.meta.preset_id
piv.meta.VDP
piv.meta.notes
piv.meta.setting_file
piv.meta.export_file
piv.meta.session_file
piv.meta.frame_count
```

In the current PIVLab importer, `x` and `y` are usually stored as static
2-D grids, while `u`, `v`, and `typevector` are stacked along the 3rd
dimension for frame index. The rest of the pipeline should operate only on
this canonical structure.

At the moment, routine PIVLab processing uses `variant = "single_dt"` and
writes `local/work/<run_id>/pivlab_single.mat`.

## Standard outputs

The implemented derived products are `frame_metrics.csv` (per frame) and
`band_metrics.csv` (per run × depth band). `run_summary.csv` is still
planned.

### 1. `run_summary.csv`
Planned product. One row per run.

Used for:

- run inventory
- nominal vs actual discharge summary
- QC flags

### 2. `band_metrics.csv`
Implemented product. One row per run × depth band (`s32_aggregate_band_metrics.m`).

Each run's frames are grouped into the four depth bands from
`metadata/depth_bands.csv` and the frame-wise metrics are averaged within
each band. Repetitions are kept as separate runs; pool by condition at
figure time.

Used for:

- representative regime comparisons
- band-wise metric summaries
- compact paper tables

### 3. `frame_metrics.csv`
Implemented product. One row per frame pair.

`s30_compute_metrics.m` writes the PIV-derived columns; `s31_map_waterlevel.m`
then fills `depth_m`, `h_over_a`, `band_id`, and `q_actual_Lps` by aligning
the run's `waterlevel.csv` to the PIV frame times (the recordings are
co-extensive, so the two series are matched by normalized time).

Used for:

- continuous \(h/a\)-based plots
- smoothing / aggregation after import
- exploratory and final figure generation

## MATLAB workflow

A typical workflow is expected to follow these steps.

1. Prepare rectified TIFF frames and optional PIVLab temporary sequences with `scripts/s10_prepare_frames.m`
2. Save the PIVLab workspace dump as `PIVlab_raw.mat` under `local/work/<run_id>/`
3. Import it into a canonical `.mat` structure with `scripts/s20_import_piv_results.m`
4. Optionally make a preview movie with `scripts/s25_preview_piv_movie.m`
5. Compute the current frame-wise metrics with `scripts/s30_compute_metrics.m`
6. Optionally make a quick-look metrics figure with `scripts/s35_plot_run_metrics_overview.m`
7. Create paper figures with `scripts/s40_make_paper_figures.m` after that stage is implemented

## Coding style

- MATLAB is the main language.
- Driver scripts live in `scripts/`.
- Reusable functions live in `src/`.
- Path-specific settings belong in a local config file and should not be committed.
- Daily script settings should usually be kept in disposable copies under the gitignored `tmp/` folder.
- Raw data and large derived files remain outside the Git repository.

## Current project status

The project is currently in the pilot-processing phase.

Completed or mostly fixed:

- core experimental concept
- run-level design
- representative depth-band design
- methods section backbone
- primary metrics definition
- repository architecture concept
- local data-root layout under `local/`
- PIVLab raw-to-canonical import for `PIVlab_raw.mat -> pivlab_single.mat`
- basic frame-wise metrics for `E(t)`, `phi_lv(t)`, and `I_asym(t)`
- water-level / depth mapping for `depth_m`, `h_over_a`, `band_id`, and
  `q_actual_Lps` (`s31_map_waterlevel.m`)
- run × depth-band aggregation into `band_metrics.csv` (`s32_aggregate_band_metrics.m`)
- quick-look preview movies and frame-metrics overview figures

Next steps:

1. continue pilot processing for inflow and outflow cases
2. verify frame-step choices and PIVLab settings across modes
3. implement band-wise metrics such as `I_unst(B_k)`
4. add circulation-related metrics such as `I_circ(t)`
6. freeze the analysis pipeline after pilot review
7. complete Results and Discussion around the finalized metrics

## Notes

This repository is intended to support both the paper and the experimental workflow. It should remain simple, explicit, and robust against changes in the upstream PIV package.

## Script philosophy

This project is intended to stay usable by a very small team over a multi-year period. The top-level `scripts/` folder is therefore intentionally kept coarse-grained:

- `s10_prepare_frames.m`
- `s20_import_piv_results.m`
- `s25_preview_piv_movie.m`
- `s30_compute_metrics.m`
- `s35_plot_run_metrics_overview.m`
- `s40_make_paper_figures.m`

Detailed logic should live in reusable functions under `src/`, while the scripts remain short driver entry points.


# How to use the software

## PIV preprocessing workflow

Raw PIV videos are not analyzed directly. Each run is first converted into a rectified and preprocessed TIFF sequence.

Standard workflow:

1. read one raw PIV video under `local/raw/<run_id>/`
2. select inner basin corners once and save `rectification.mat`
3. apply projective rectification and light preprocessing
4. export a TIFF sequence under `local/work/<run_id>/rectified_tif/`
5. use the TIFF sequence as the common input for either PIVLab or external PIV software

This design keeps geometric correction and low-level preprocessing independent from the later choice of PIV software.

### Why this design

The project supports two possible PIV routes:

- `video -> MATLAB / PIVLab -> canonical .mat -> metrics`
- `video -> external PIV software -> canonical .mat -> metrics`

To avoid duplicating downstream logic, both routes are expected to converge to a common canonical MATLAB structure after import.

## Metadata tables

The repository stores experimental metadata in CSV format under `metadata/`.

Current core tables are:

- `metadata/runs.csv` : run-level experiment table
- `metadata/depth_bands.csv` : representative depth bands for plotting and band-wise aggregation
- `metadata/flow_levels.csv` : nominal flow-level definitions

Metadata tables are version-controlled in GitHub. Large raw data, intermediate files, and derived outputs are stored outside the repository.

## Data storage policy

The repository stores:

- MATLAB code
- metadata tables
- lightweight documentation
- templates and configuration files

The local data root stores:

- raw videos
- water-level CSV files
- rectification files
- rectified TIFF sequences
- tool-specific working folders
- canonical PIV `.mat` files
- derived metrics CSV files
- paper figures and tables

This separation keeps the repository lightweight while preserving reproducibility.

## Recommended Per-Run Data Structure

Under `local/raw/<run_id>/`:

- `piv.mp4` or the filename recorded in `metadata/runs.csv`
- `timelapse.mp4`
- `waterlevel.csv`
- `runlog.md`

Under `local/work/<run_id>/`:

- `rectification.mat`
- `piv_manifest.csv`
- `PIVlab_setting.mat` or another clearly named PIVLab settings file
- `PIVlab_raw.mat`
- `pivlab_single.mat`
- `pivlab_proj/`
- `tmp_pivlab_<variant>/` as needed

Under `local/work/<run_id>/rectified_tif/`:

- `img_00001.tif`, `img_00002.tif`, ...
- processing manifest written by the preprocessing script

The default config uses `cfg.DATA_ROOT = fullfile(cfg.REPO_ROOT, 'local')`, `cfg.WORK_DIR = fullfile(cfg.DATA_ROOT, 'work')`, and `cfg.RECTIFIED_TIF_DIR = 'rectified_tif'`.

## PIVLab temporary sequence

When PIVLab works better with a temporary sequential TIFF folder, create one from the rectified TIFF sequence using `make_pivlab_sequence`. This preparation step now belongs in `scripts/s10_prepare_frames.m`.

Typical usage:

```matlab
runID = "R0009";

srcDir = fullfile(cfg.WORK_DIR, char(runID), cfg.RECTIFIED_TIF_DIR);
outDir = fullfile(cfg.WORK_DIR, char(runID), 'tmp_pivlab_long');

manifest = make_pivlab_sequence(srcDir, outDir, ...
    'frame_step', 3, ...
    'start_index', 1000, ...
    'prefix', 'img_', ...
    'digits', 4, ...
    'delete_existing', true, ...
    'copy_mode', 'copy', ...
    'write_manifest', true);
```

This creates a temporary renumbered sequence such as `img_1000.tif`, `img_1001.tif`, ... for PIVLab while keeping the rectified source TIFFs unchanged when `copy_mode = 'copy'`.

Students should follow the layout described in [local/README.md](local/README.md) when adding new experiment data.

## PIVLab save policy

In this project, PIVLab outputs should be managed with the minimum reproducibility layer needed for downstream analysis.

- save the PIVLab setting actually used for a run with "Save current PIVlab settings"
- store that setting file directly under `local/work/<run_id>/`
- use a descriptive filename such as `PIVlab_setting.mat` or `PIVlab_setting_10fps.mat`
- PIVLab session files are optional and are only needed while tuning in the GUI
- optional session files should be stored under `local/work/<run_id>/pivlab_proj/`
- the important run output is the raw workspace dump `PIVlab_raw.mat` under `local/work/<run_id>/`
- each run should also keep `local/work/<run_id>/piv_manifest.csv`

The run-level setting file is the authoritative record for the PIVLab GUI settings. It already stores items such as algorithm choice, interrogation window sizes, step sizes, and validation filter thresholds, so these do not need to be copied manually into the run manifest every time.

`piv_manifest.csv` should therefore stay small and record only run-specific context that is not reliably preserved by the setting file itself.

PIVLab should save the raw workspace dump as `PIVlab_raw.mat` under
`local/work/<run_id>/`. The MATLAB-side importer reads only the minimum
variables needed for canonical import:

- `x`
- `y`
- `u_filtered`
- `v_filtered`
- `typevector_filtered`
- `calxy`
- `calu`
- `calv`
- `units`

Recommended minimum fields in `piv_manifest.csv` are:

- `run_id`
- `source_video_fps_hz`
- `export_step_frames`
- `effective_sequence_fps_hz`
- `pair_step_frames`
- `dt_pair_s`
- `setting_file`
- `export_file`
- `session_file`
- `notes`

In the current workflow, one run corresponds to one `PIVlab_raw.mat` and one canonical `pivlab_single.mat`.

In short, the project keeps:

- run-level setting file: `local/work/<run_id>/PIVlab_setting*.mat`
- raw PIVLab export: `local/work/<run_id>/PIVlab_raw.mat`
- canonical imported result: `local/work/<run_id>/pivlab_single.mat`
- run-level manifest: `local/work/<run_id>/piv_manifest.csv`
- optional GUI session: `local/work/<run_id>/pivlab_proj/*.mat`

For routine processing, script-specific settings such as the current
`runID`, preview frame step, or temporary PIVLab sequence options should be
set in a disposable copy of the driver script placed under the gitignored
`tmp/` folder, for example `tmp/s10_R0012.m` copied from
`scripts/s10_prepare_frames.m`. Run the copy directly; the shared script
under `scripts/` stays untouched.

## Project startup

The project uses a local initialization script such as `init.m`, rather than a global MATLAB `startup.m`.

Typical usage:

```matlab
init
T = read_runs_table();
```

This keeps the project-local setup separate from the user's global MATLAB environment.

## Current analysis philosophy

The project is organized around the following principles:

- one run is the minimum management unit
- metadata tables define experimental conditions
- depth varies continuously within each run and is later grouped for representative analysis
- primary metrics are defined independently of the chosen PIV software
- image preparation should remain simple and stable

## See also

- `doc/piv_preprocessing_protocol.md`
- `metadata/README.md`
- `config/project_config_template.m`
- `local/README.md`
- `scripts/s10_prepare_frames.m`
- `scripts/s20_import_piv_results.m`
- `scripts/s25_preview_piv_movie.m`
- `scripts/s30_compute_metrics.m`
- `scripts/s35_plot_run_metrics_overview.m`
- `src/io/make_pivlab_sequence.m`

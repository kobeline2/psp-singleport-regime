# Scripts README

This folder contains the top-level MATLAB scripts that students and project members are expected to run.

The scripts are intentionally coarse-grained. Detailed logic should live in `src/`, while the scripts here serve as clear entry points for each stage of the workflow.

## Current Script List

- `s10_prepare_frames.m`
  Main preprocessing entry point.
  Reads one raw video, creates or updates `rectification.mat`, exports the rectified TIFF sequence, and creates a temporary PIVLab-ready sequence.

- `s20_import_piv_results.m`
  Imports `PIVlab_raw.mat` into the canonical MATLAB format.
  The current implementation saves `pivlab_single.mat` under
  `local/work/<run_id>/`.

- `s25_preview_piv_movie.m`
  Optional helper script for making a quick preview movie from PIVLab output.
  This is mainly for checking flow fields visually and is not part of the core pipeline.

- `s30_compute_metrics.m`
  Computes the current minimal frame-wise metrics from `pivlab_single.mat`.
  Depth / band mapping is intentionally left for a later stage.

- `s35_plot_run_metrics_overview.m`
  Makes a quick-look figure for one run from `frame_metrics.mat`.
  This is for exploratory inspection, not for final paper figures.
  The panel layout is data-driven and auto-sizes its grid, so it adapts as
  metrics are added.

- `s36_plot_divergence_field.m`
  Computes the surface horizontal divergence field `D = du/dx + dv/dy`
  (a secondary, exploratory metric) from `pivlab_single.mat`, saves the
  field to `local/derived/fields/<run_id>/divergence.mat`, and plots the
  time-mean divergence map. `D > 0` indicates divergence/upwelling and
  `D < 0` convergence/downwelling. The companion frame-wise scalar
  `D_rms(t)` is produced by `s30` and shown in the `s35` overview.

- `s40_make_paper_figures.m`
  Planned entry point for generating paper figures from derived outputs.
  Important: this script is currently a placeholder and is not yet implemented.

## What Students Should Usually Run

At the current project stage, most students should start with:

1. `s10_prepare_frames.m`
2. PIVLab or external PIV software outside this repository
3. `s20_import_piv_results.m` to save canonical PIV data
4. `s30_compute_metrics.m` for the current basic frame-wise metrics
5. `s35_plot_run_metrics_overview.m` when you want a quick visual summary of one case
6. Later paper-figure scripts after the corresponding functions are implemented

In other words, the current routine path is `s10_prepare_frames.m` -> `s20_import_piv_results.m` -> `s30_compute_metrics.m`, with `s35_plot_run_metrics_overview.m` as an optional quick-look step.

## Before Running Any Script

1. Open MATLAB in the repository root.
2. Make sure your experiment files are placed under `local/` as described in [local/README.md](local/README.md).
3. Confirm that the target `runID` exists in `metadata/runs.csv`.
4. Read the user settings at the top of the script before pressing Run.

Most scripts call `init` internally, so you usually do not need to run `init` manually first.

For scripts that you run often, prefer using the adjacent gitignored local
override files in `scripts/` so that the shared script stays clean.
For example:

- `scripts/s10_prepare_frames_local.m`
- `scripts/s20_import_piv_results_local.m`
- `scripts/s25_preview_piv_movie_local.m`
- `scripts/s30_compute_metrics_local.m`
- `scripts/s35_plot_run_metrics_overview_local.m`
- `scripts/s36_plot_divergence_field_local.m`

Each of these has a tracked `.example` file next to it. Copy the example,
remove `.example` from the name, and edit only the values you want to
change on your PC.

## How Students Should Update This Repository

This repository assumes that one maintainer edits the code, possibly from two PCs, while students only pull updates and run the shared scripts.

Student workflow:

```sh
git switch main
git pull --ff-only
```

Important:

- stay on `main` unless the maintainer explicitly asks you to use another branch
- do not commit code changes locally unless you were asked to edit the repository
- remember that `local/` is machine-local; Git will not sync your raw data or TIFFs from another PC
- `scripts/*_local.m` files are also machine-local in practice because they are gitignored

## How To Use `s10_prepare_frames.m`

Open [s10_prepare_frames.m](scripts/s10_prepare_frames.m) and update the user settings near the top:

- `runID`
  Set this to the run you want to process, for example `"R0009"`.

- `do_select_rectification`
  Set to `true` when you want to select or update the four basin corner points.
  Set to `false` when a valid `rectification.mat` already exists and you want to reuse it.

- `rectification_frame_idx`
  Frame number used when selecting the rectification points.

- `pivlab_variant`
  Used to name the temporary PIVLab sequence folder, for example `tmp_pivlab_long`.

- `opts`
  Controls TIFF export settings such as frame range, frame step, and preprocessing options.

- `pivlab_opts`
  Controls the temporary PIVLab-ready image sequence, including frame thinning and output numbering.

If you expect to change these values often, prefer creating
`scripts/s10_prepare_frames_local.m` by copying
`scripts/s10_prepare_frames_local.m.example` and overriding only the needed
variables there.

### What `s10_prepare_frames.m` Produces

For a run such as `R0009`, the script writes files under:

- `local/work/R0009/rectification.mat`
- `local/work/R0009/rectified_tif/`
- `local/work/R0009/tmp_pivlab_long/` or a similar variant-specific folder

## How To Use `s20_import_piv_results.m`

Open [s20_import_piv_results.m](scripts/s20_import_piv_results.m) and check these settings:

- `runID`
  Run to import, for example `"R0009"`.

- `export_file`
  PIVLab MAT file stored under `local/work/<run_id>/`.
  In the current workflow this should be `PIVlab_raw.mat`.
  The importer reads only the minimum variables needed for import:
  `x`, `y`, `u_filtered`, `v_filtered`, `typevector_filtered`,
  `calxy`, `calu`, `calv`, and `units`.

- `source_video_fps_hz`, `effective_sequence_fps_hz`, `export_step_frames`, `pair_step_frames`, `dt_pair_s`
  Timing metadata. If `local/work/<run_id>/piv_manifest.csv` contains a matching row for `export_file`, these can usually stay as `NaN`.

- `setting_file`, `session_file`, `preset_id`, `VDP`, `notes`
  Optional provenance fields. Use them when the manifest does not already record the needed information.

If you change `runID` often, prefer creating
`scripts/s20_import_piv_results_local.m` from the adjacent `.example` file.

### What `s20_import_piv_results.m` Produces

For a run such as `R0009`, the script writes the canonical single-dt file:

- `local/work/R0009/pivlab_single.mat`

## How To Use `s30_compute_metrics.m`

Open [s30_compute_metrics.m](scripts/s30_compute_metrics.m) and check:

- `runID`
  Run to process, for example `"R0009"`.

- `opts.low_speed_threshold_m_s`
  Provisional threshold used for `phi_lv(t)`.

- `opts.log_every`
  Progress log interval for long runs.

If you change `runID` or the threshold often, prefer creating
`scripts/s30_compute_metrics_local.m` from the adjacent `.example` file.

The current implementation computes only the frame-wise metrics that can be derived directly from `pivlab_single.mat`:

- `valid_fraction`
- `mean_speed`
- `rms_speed`
- `E`
- `phi_lv`
- `I_asym`

It also writes placeholder columns `depth_m`, `h_over_a`, and `band_id` so a later band-mapping step can reuse the same table schema.

### What `s30_compute_metrics.m` Produces

For a run such as `R0009`, the script writes:

- `local/derived/metrics/R0009/frame_metrics.csv`
- `local/derived/metrics/R0009/frame_metrics.mat`

## How To Use `s35_plot_run_metrics_overview.m`

Open [s35_plot_run_metrics_overview.m](scripts/s35_plot_run_metrics_overview.m) and check:

- `runID`
  Run to visualize, for example `"R0009"`.

- `smooth_span_frames`
  Moving-average span used for the bold trend line.

- `save_png`, `save_fig`, `show_figure`
  Controls how the overview figure is saved and whether it stays open.

This script reads `frame_metrics.mat` first and falls back to `frame_metrics.csv` if needed.
It currently summarizes:

- `E(t)`
- `phi_lv(t)`
- `mean_speed`
- `rms_speed`
- `I_asym(t)`
- `valid_fraction`

### What `s35_plot_run_metrics_overview.m` Produces

For a run such as `R0009`, the script writes:

- `local/results/figures/R0009_frame_metrics_overview.png`

If `save_fig = true`, it also writes:

- `local/results/figures/R0009_frame_metrics_overview.fig`

## Rectification Workflow

When `do_select_rectification = true`, the script opens the raw video frame and asks you to click:

1. top-left
2. top-right
3. bottom-right
4. bottom-left

After clicking the four points, the script shows a rectified preview. Accept it only if the transformed basin looks visually correct.

## Important Notes

- Do not rename run folders freely. Use the run IDs defined in `metadata/runs.csv`.
- Do not store raw videos or TIFF sequences outside `local/` unless the supervisors explicitly change the policy.
- `s40` is not ready for routine student use yet.
- If a script fails, save the error message and report which `runID` you were processing.

## See Also

- [local/README.md](local/README.md)
- [README.md](README.md)
- [piv_preprocessing_protocol.md](doc/piv_preprocessing_protocol.md)

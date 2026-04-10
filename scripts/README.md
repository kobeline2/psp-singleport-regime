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
  Planned entry point for computing frame-wise and band-wise metrics from canonical PIV outputs.
  Important: this script is currently a placeholder and is not yet implemented.

- `s40_make_paper_figures.m`
  Planned entry point for generating paper figures from derived outputs.
  Important: this script is currently a placeholder and is not yet implemented.

## What Students Should Usually Run

At the current project stage, most students should start with:

1. `s10_prepare_frames.m`
2. PIVLab or external PIV software outside this repository
3. `s20_import_piv_results.m` to save canonical PIV data
4. Later scripts after the corresponding metric and figure functions are implemented

In other words, the current routine path is `s10_prepare_frames.m` followed by `s20_import_piv_results.m`.

## Before Running Any Script

1. Open MATLAB in the repository root.
2. Make sure your experiment files are placed under `local/` as described in [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md).
3. Confirm that the target `runID` exists in `metadata/runs.csv`.
4. Read the user settings at the top of the script before pressing Run.

Most scripts call `init` internally, so you usually do not need to run `init` manually first.

For `s10_prepare_frames.m`, daily-use settings can also be overridden in
`local/settings/s10_prepare_frames_local.m` so that students do not need to
edit the shared script every time.

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
- remember that `local/` is machine-local; Git will not sync your raw data, TIFFs, or local settings from another PC

## How To Use `s10_prepare_frames.m`

Open [s10_prepare_frames.m](/Users/koshiba/Documents/git/psp-singleport-regime/scripts/s10_prepare_frames.m) and update the user settings near the top:

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
`local/settings/s10_prepare_frames_local.m` and overriding only the needed
variables there.

### What `s10_prepare_frames.m` Produces

For a run such as `R0009`, the script writes files under:

- `local/work/R0009/rectification.mat`
- `local/work/R0009/rectified_tif/`
- `local/work/R0009/tmp_pivlab_long/` or a similar variant-specific folder

## How To Use `s20_import_piv_results.m`

Open [s20_import_piv_results.m](/Users/koshiba/Documents/git/psp-singleport-regime/scripts/s20_import_piv_results.m) and check these settings:

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

### What `s20_import_piv_results.m` Produces

For a run such as `R0009`, the script writes the canonical single-dt file:

- `local/work/R0009/pivlab_single.mat`

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
- `s30` and `s40` are not ready for routine student use yet.
- If a script fails, save the error message and report which `runID` you were processing.

## See Also

- [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md)
- [README.md](/Users/koshiba/Documents/git/psp-singleport-regime/README.md)
- [piv_preprocessing_protocol.md](/Users/koshiba/Documents/git/psp-singleport-regime/doc/piv_preprocessing_protocol.md)

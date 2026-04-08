# Scripts README

This folder contains the top-level MATLAB scripts that students and project members are expected to run.

The scripts are intentionally coarse-grained. Detailed logic should live in `src/`, while the scripts here serve as clear entry points for each stage of the workflow.

## Current Script List

- `s10_prepare_frames.m`
  Main preprocessing entry point.
  Reads one raw video, creates or updates `rectification.mat`, exports the rectified TIFF sequence, and creates a temporary PIVLab-ready sequence.

- `s20_import_piv_results.m`
  Planned entry point for importing PIV results into the canonical MATLAB format.
  Important: this script is currently a placeholder and is not yet implemented.

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
3. Later scripts only after the corresponding import and metric functions are implemented

In other words, `s10_prepare_frames.m` is the main script that is currently ready for routine use.

## Before Running Any Script

1. Open MATLAB in the repository root.
2. Make sure your experiment files are placed under `local/` as described in [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md).
3. Confirm that the target `runID` exists in `metadata/runs.csv`.
4. Read the user settings at the top of the script before pressing Run.

Most scripts call `init` internally, so you usually do not need to run `init` manually first.

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

### What `s10_prepare_frames.m` Produces

For a run such as `R0009`, the script writes files under:

- `local/work/R0009/rectification.mat`
- `local/work/R0009/rectified_tif/`
- `local/work/R0009/tmp_pivlab_long/` or a similar variant-specific folder

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
- `s20`, `s30`, and `s40` are not ready for routine student use yet.
- If a script fails, save the error message and report which `runID` you were processing.

## See Also

- [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md)
- [README.md](/Users/koshiba/Documents/git/psp-singleport-regime/README.md)
- [piv_preprocessing_protocol.md](/Users/koshiba/Documents/git/psp-singleport-regime/doc/piv_preprocessing_protocol.md)

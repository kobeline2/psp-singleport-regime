# PIV Preprocessing Protocol

## Purpose
This document defines the standard procedure for preparing rectified and preprocessed image sequences for surface PIV analysis in the `psp-singleport-regime` project.

The goal is to convert one raw PIV video per run into a rectified TIFF sequence that can be used consistently in either of the following downstream routes:

- `video -> MATLAB / PIVLab -> canonical .mat -> metrics`
- `video -> external PIV software -> canonical .mat -> metrics`

This protocol is intentionally lightweight. It records the minimum required steps and files for reproducibility without introducing unnecessary manual bookkeeping.

In the default project setup, `data_root` corresponds to `local/` under the repository root.

## Scope
This protocol applies to the main PIV video of each run, for example:

- `local/raw/R0009/piv.mp4`

The timelapse video is not part of this preprocessing pipeline. It is used separately for checking quiescent initial conditions.

## Required inputs per run
Each run is assumed to have the following files under `local/raw/<run_id>/`:

- `piv.mp4` : main video for PIV analysis
- `timelapse.mp4` : timelapse video for residual-motion checks
- `waterlevel.csv` : water-level time series
- `runlog.md` : manual notes for the run

The processing pipeline described here only consumes `piv.mp4` directly.

## Output files
For each run, the current standard outputs are:

- `local/work/<run_id>/rectification.mat`
- `local/work/<run_id>/rectified_tif/img_00001.tif`, `img_00002.tif`, ...
- `local/work/<run_id>/rectified_tif/frame_manifest.csv` or equivalent manifest written by the processing script

No rectification preview PNG is required in the default workflow. The transform can be reproduced from `rectification.mat` when needed.

## Standard workflow

### Step 1. Initialize the project
Open MATLAB in the repository root and run:

```matlab
init
```

This loads the project paths and configuration.

### Step 2. Read the run table
Read `metadata/runs.csv` and select the target run:

```matlab
T = read_runs_table();
row = T(T.run_id == "R0009", :);
```

### Step 3. Select rectification points once
For a new run, create the rectification transform manually using the raw PIV video.

Use the inner water-domain corners, not the outer image frame.

After the 4 points are selected, the function computes a rectified preview
of the chosen frame. Confirm the preview only if the transformed basin
looks visually correct and the target aspect ratio is reasonable.

Click in the following order:

1. top-left
2. top-right
3. bottom-right
4. bottom-left

Example:

```matlab
rect = select_rectification_points(videoPath, rectFile, ...
    'run_id', "R0009", ...
    'frame_idx', 1, ...
    'Lx_m', 3.0, ...
    'Ly_m', 2.0, ...
    'pixel_size_m', 0.002, ...
    'operator', "A", ...
    'notes', "inner basin corners");
```

This writes `rectification.mat`.

### Step 4. Generate rectified TIFF frames
Once `rectification.mat` exists, generate the rectified and preprocessed image sequence:

```matlab
manifest = prepare_piv_frames(videoPath, frameDir, rectFile, opts);
```

The default implementation performs the following operations in sequence:

1. read one frame from the raw video
2. apply projective rectification
3. apply optional preprocessing
4. write TIFF output

The preferred workflow is to process frames directly from the video into rectified TIFF output. Intermediate unrectified TIFF sequences are not generated.

### Step 5. Optionally create a temporary PIVLab sequence
If PIVLab needs a temporary renumbered TIFF folder, create one from the rectified sequence:

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

This creates a temporary sequential folder for PIVLab without modifying the source rectified TIFF sequence when `copy_mode` is set to `copy`.

In the current project layout, this optional step belongs to `scripts/s10_prepare_frames.m`, not to the later PIV-result import step.

### Step 6. Save PIVLab outputs with minimal provenance
This project keeps PIVLab saving intentionally simple.

Reusable settings:

- save the PIVLab setting actually used for the run with PIVLab's "Save current PIVlab settings"
- store the setting file directly under `local/work/<run_id>/`
- use descriptive filenames such as `pivlab_setting_15fps.mat`

Optional GUI session:

- "Save PIVlab session" is not required for every run
- use it only when tuning or when a GUI checkpoint is genuinely helpful
- if used, store the session file under `local/work/<run_id>/pivlab_proj/`

Required run outputs:

- exported PIV result files should be stored directly under `local/work/<run_id>/`
- typical names are `pivlab_short.mat` and `pivlab_long.mat`
- for single-`\Delta t` operation, a single exported result file is acceptable
- each run should also keep `local/work/<run_id>/piv_manifest.csv`

The run-level setting file should be treated as the authoritative record for the PIVLab GUI settings. It already preserves items such as algorithm selection, interrogation window sizes, step sizes, and validation filter thresholds.

Therefore, `piv_manifest.csv` should not duplicate the full setting contents by hand. It should stay lean and only record run-specific context that the setting file does not capture well.

Recommended minimum columns in `piv_manifest.csv` are:

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

If one run produces multiple exported results, for example short- and long-`\Delta t` files, write one row per exported result in the same `piv_manifest.csv`.

The minimum reproducibility layer is therefore:

- run-level setting file: `local/work/<run_id>/pivlab_setting*.mat`
- exported PIV result: `local/work/<run_id>/*.mat`
- run-level manifest: `local/work/<run_id>/piv_manifest.csv`
- session file: optional

## Current default preprocessing settings
The current default settings are intentionally conservative.

```matlab
opts.preprocess.flatfield_mode = 'divide';
opts.preprocess.flat_sigma_px  = 30;
opts.preprocess.clip_prctile   = [1 99];
opts.preprocess.invert         = true;
opts.preprocess.do_clahe       = false;
opts.preprocess.do_median      = false;
opts.preprocess.output_class   = 'uint16';
```

These defaults should be treated as project-level starting values, not immutable truths. They may be updated after pilot testing, but once a setting is adopted for the main dataset, it should be kept fixed across runs unless a documented reprocessing decision is made.

## Rectification data structure
The rectification file stores a single struct named `rect`. The minimum expected fields are:

- `rect.version`
- `rect.run_id`
- `rect.video_file`
- `rect.frame_idx`
- `rect.created_at`
- `rect.operator`
- `rect.notes`
- `rect.corner_order`
- `rect.src_pts_px`
- `rect.dst_pts_px`
- `rect.basin.Lx_m`
- `rect.basin.Ly_m`
- `rect.pixel_size_m`
- `rect.Nx`
- `rect.Ny`
- `rect.tform`
- `rect.outputRef`

This is sufficient to re-apply or audit the transform later.

## Design principles

### 1. One canonical image sequence per run
Downstream PIV analysis should work from a single rectified TIFF sequence per run.

### 2. PIV source independence
Geometric correction and basic preprocessing should be shared across PIV workflows as much as possible. PIVLab and external software should differ mainly at the import stage, not in the image preparation stage.

### 3. Minimal but sufficient provenance
This project does not aim to over-document every image-processing action. Instead, the standard is:

- save the rectification transform
- save the processed TIFF sequence
- save a minimal processing manifest

### 4. Prefer reproducibility over aggressive enhancement
Image enhancement should remain simple and stable. Over-processing that changes particle appearance in a hard-to-interpret way should be avoided.

## Quality check after preprocessing
Before using the resulting TIFF sequence in PIV, visually inspect a small sample of frames and confirm the following:

- the basin is properly rectified
- the inner water domain is aligned and consistently framed
- tracer particles remain visible after preprocessing
- reflections are not excessively amplified
- the port-near region can be masked consistently in later analysis

If any of these checks fail, revise the rectification transform or preprocessing parameters before continuing.

## Notes on dual-\Delta t PIV
This preprocessing protocol is independent of the later dual-`\Delta t` PIV strategy.

Whether the velocity field is computed from short frame intervals, long frame intervals, or merged results, the preferred input is the same rectified TIFF sequence produced by this protocol.

## Recommended file locations
Repository side:

- `src/piv/select_rectification_points.m`
- `src/piv/prepare_piv_frames.m`
- `src/piv/preprocess_piv_frame.m`
- `src/io/make_pivlab_sequence.m`
- `scripts/s10_prepare_frames.m`

Data side:

- `local/work/<run_id>/rectification.mat`
- `local/work/<run_id>/rectified_tif/`
- `local/work/<run_id>/pivlab_setting*.mat`
- `local/work/<run_id>/piv_manifest.csv`
- `local/work/<run_id>/pivlab_proj/`

## Revision policy
This protocol may be updated during the pilot stage. Once pilot testing is complete and the main preprocessing settings are fixed, changes should be documented explicitly in the project notes.

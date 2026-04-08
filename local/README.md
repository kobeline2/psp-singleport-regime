# local/

This directory is the default data root for local experiment files.

Everything under `local/` is intended for machine-local working data. The repository keeps only this README and a few `.gitkeep` placeholder files. Raw videos, intermediate TIFF sequences, PIV projects, and result files should stay here and should not be committed.

## Two-PC note

`local/` belongs to one machine. Git does not synchronize the contents of:

- `local/raw/`
- `local/work/`
- `local/derived/`
- `local/results/`
- `local/settings/`

If the maintainer switches between two PCs, the Git branch should be pushed in the usual way, but the experiment files under `local/` must be copied or synced separately outside Git.

It is normal for two PCs to have different `local/` contents and different `local/settings/s10_prepare_frames_local.m` files.

## Standard Layout

```text
local/
├─ raw/
│  └─ R0001/
│     ├─ piv.mp4
│     ├─ timelapse.mp4
│     ├─ waterlevel.csv
│     └─ runlog.md
├─ work/
│  ├─ R0001/
│  │  ├─ rectification.mat
│  │  ├─ rectified_tif/
│  │  ├─ pivlab_proj/
│  │  └─ tmp_pivlab_long/
│  └─ exports/
├─ settings/
│  └─ s10_prepare_frames_local.m
├─ derived/
│  ├─ piv/
│  ├─ metrics/
│  └─ qc/
└─ results/
   ├─ figures/
   ├─ tables/
   └─ drafts/
```

## What Students Should Put Here

1. Create a run folder under `local/raw/` using the run ID from `metadata/runs.csv`, for example `R0009`.
2. Put the raw experiment files for that run into `local/raw/<run_id>/`.
3. Use these standard filenames when available:
   `piv.mp4`, `timelapse.mp4`, `waterlevel.csv`, `runlog.md`
4. Run `scripts/s10_prepare_frames.m` to create `rectification.mat`, `rectified_tif/`, and optional temporary PIVLab sequences under `local/work/<run_id>/`.
5. Keep tool-specific PIVLab project folders under `local/work/<run_id>/pivlab_proj/`.
6. Keep imported canonical MATLAB outputs under `local/derived/piv/`, metric CSV outputs under `local/derived/metrics/`, and QC files under `local/derived/qc/`.
7. Save paper figures and tables under `local/results/`.

## Local Script Settings

If you need to change `runID` or other daily-use options for `s10_prepare_frames.m`, do not edit the shared script every time.

Instead, create:

`local/settings/s10_prepare_frames_local.m`

This file is gitignored and can contain simple MATLAB assignments that overwrite the defaults in the shared script.

Example:

```matlab
runID = "R0009";
do_select_rectification = false;
rectification_frame_idx = 1;
make_pivlab_tmp = true;
pivlab_variant = "long";

opts.frame_step = 6;
opts.end_frame = Inf;

pivlab_opts.frame_step = 5;
pivlab_opts.start_index = 1000;
```

Important:

- You only need to write the values you want to change.
- `opts` and `pivlab_opts` already exist in the main script, so it is usually better to update individual fields such as `opts.frame_step` instead of rebuilding the whole struct from scratch.

## Naming Rules

- Run folder names should match `metadata/runs.csv`, for example `R0001`, `R0009`, `R0024`.
- Do not invent separate folder names for the same run.
- If a run is repeated or reprocessed, keep the run ID fixed and store the processed outputs under `local/work/<run_id>/` unless the workflow explicitly needs an extra subfolder.

## Important Notes

- Do not commit experiment data from `local/`.
- If you add a new run, update `metadata/runs.csv` in the repository as needed.
- If you need a new standard file or folder convention, update this README and the project docs together.

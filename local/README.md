# local/

This directory is the default data root for local experiment files.

Everything under `local/` is intended for machine-local working data. The repository keeps only this README and a few `.gitkeep` placeholder files. Raw videos, intermediate TIFF sequences, PIV projects, and result files should stay here and should not be committed.

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

## Naming Rules

- Run folder names should match `metadata/runs.csv`, for example `R0001`, `R0009`, `R0024`.
- Do not invent separate folder names for the same run.
- If a run is repeated or reprocessed, keep the run ID fixed and store the processed outputs under `local/work/<run_id>/` unless the workflow explicitly needs an extra subfolder.

## Important Notes

- Do not commit experiment data from `local/`.
- If you add a new run, update `metadata/runs.csv` in the repository as needed.
- If you need a new standard file or folder convention, update this README and the project docs together.

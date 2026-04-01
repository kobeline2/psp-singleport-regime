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

The project also supports a dual-\(\Delta t\) strategy.

- A short frame interval is used to stabilize high-velocity regions.
- A long frame interval is used to improve sensitivity in low-velocity regions.
- The final merged field is used for both figures and metrics.

## Primary metrics

The current primary metrics are:

- \(E(t)\): basin-scale motion intensity
- \(\phi_{\mathrm{lv}}(t)\): low-velocity area fraction
- \(I_{\mathrm{asym}}(t)\): left-right asymmetry index
- \(I_{\mathrm{circ}}(t)\): circulation index
- \(I_{\mathrm{unst}}(B_k)\): band-wise unsteadiness index

Secondary metrics such as vortex-core location, dominant frequency, and supplementary vorticity maps may be used only when they provide reproducible physical insight.

## Repository policy

GitHub is used for:

- MATLAB code
- metadata tables
- project configuration templates
- documentation

The following are **not** stored in GitHub and should remain in local/Dropbox storage.

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
├─ startup.m
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
│  ├─ s00_setup_project.m
│  ├─ s10_register_runs.m
│  ├─ s20_import_run_assets.m
│  ├─ s30_import_piv_short.m
│  ├─ s31_import_piv_long.m
│  ├─ s40_merge_dual_dt.m
│  ├─ s50_compute_frame_metrics.m
│  ├─ s60_aggregate_band_metrics.m
│  ├─ s70_export_csv.m
│  └─ s80_make_paper_figures.m
├─ docs/
└─ tests/
```

## External data layout

The repository assumes a separate data root on local storage or Dropbox.

```text
data_root/
├─ raw/
│  ├─ R0001/
│  │  ├─ piv.mp4
│  │  ├─ timelapse.mp4
│  │  ├─ waterlevel.csv
│  │  └─ runlog.md
│  └─ ...
├─ piv_exports/
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

## Metadata tables

### `metadata/runs.csv`
Each row corresponds to one run.

Recommended columns:

- `run_id`
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
- `piv_source`
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

Suggested fields:

```matlab
pivrun.run_id
pivrun.source        % 'pivlab' or 'external'
pivrun.variant       % 'short', 'long', or 'merged'
pivrun.frame_idx
pivrun.time_s
pivrun.depth_m
pivrun.h_over_a
pivrun.band_id
pivrun.x
pivrun.y
pivrun.u
pivrun.v
pivrun.mask
pivrun.meta
```

The rest of the pipeline should operate only on this canonical structure.

## Standard outputs

The project should generate three main CSV products.

### 1. `run_summary.csv`
One row per run.

Used for:

- run inventory
- nominal vs actual discharge summary
- QC flags

### 2. `band_metrics.csv`
One row per run × depth band.

Used for:

- representative regime comparisons
- band-wise metric summaries
- compact paper tables

### 3. `frame_metrics.csv`
One row per frame pair.

Used for:

- continuous \(h/a\)-based plots
- smoothing / aggregation after import
- exploratory and final figure generation

## MATLAB workflow

A typical workflow is expected to follow these steps.

1. Register runs in `metadata/runs.csv`
2. Import videos, time-lapse, water-level files, and logs
3. Import PIV results from PIVLab and/or external software
4. Convert them into a canonical `.mat` structure
5. Merge short- and long-\(\Delta t\) velocity fields
6. Compute frame-wise metrics
7. Aggregate metrics by depth band
8. Export CSV tables
9. Create paper figures

## Coding style

- MATLAB is the main language.
- Driver scripts live in `scripts/`.
- Reusable functions live in `src/`.
- Path-specific settings belong in a local config file and should not be committed.
- Raw data and large derived files remain outside the Git repository.

## Current project status

The project is currently in the pre-production phase.

Completed or mostly fixed:

- core experimental concept
- run-level design
- representative depth-band design
- methods section backbone
- primary metrics definition
- repository architecture concept

Next steps:

1. create repository structure
2. prepare metadata templates
3. run a pilot subset of experiments
4. verify that primary metrics are stable
5. freeze the analysis pipeline
6. process the remaining runs
7. complete Introduction, Results, and Discussion

## Notes

This repository is intended to support both the paper and the experimental workflow. It should remain simple, explicit, and robust against changes in the upstream PIV package.


# How to use the software

## PIV preprocessing workflow

Raw PIV videos are not analyzed directly. Each run is first converted into a rectified and preprocessed TIFF sequence.

Standard workflow:

1. read one raw PIV video under `data_root/raw/<run_id>/`
2. select inner basin corners once and save `rectification.mat`
3. apply projective rectification and light preprocessing
4. export a TIFF sequence under `data_root/derived/frames/<run_id>/rectified_tif/`
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

The external data root stores:

- raw videos
- water-level CSV files
- rectification files
- rectified TIFF sequences
- canonical PIV `.mat` files
- derived metrics CSV files
- paper figures and tables

This separation keeps the repository lightweight while preserving reproducibility.

## Recommended per-run data structure

Under `data_root/raw/<run_id>/`:

- `piv.mp4`
- `timelapse.mp4`
- `waterlevel.csv`
- `runlog.md`

Under `data_root/derived/rectification/<run_id>/`:

- `rectification.mat`

Under `data_root/derived/frames/<run_id>/rectified_tif/`:

- `img_00001.tif`, `img_00002.tif`, ...
- processing manifest written by the preprocessing script

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

- `docs/piv_preprocessing_protocol.md`
- `metadata/README.md`
- `config/project_config_template.m`
- `scripts/s15_prepare_piv_frames_example.m`

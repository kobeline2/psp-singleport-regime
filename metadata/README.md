# Metadata tables

## runs.csv
Run-level experiment table. One row corresponds to one run.

- `run_id`: Unique run identifier, e.g. `R0001`.
- `planned_order`: Planned execution order. Can be updated after randomization.
- `date`: Experiment date in `YYYY-MM-DD`.
- `operator`: Person who conducted the run.
- `mode`: `inflow` or `outflow`.
- `flow_level`: `low`, `medium`, or `high`.
- `nominal_dh_mm_min`: Nominal water-level change rate in mm/min.
- `nominal_Q_Lps`: Nominal discharge in L/s.
- `repetition`: Replicate number within each mode and flow level.
- `start_depth_m`: Water depth at the start of recording.
- `end_depth_m`: Water depth at the end of recording.
- `raw_subdir`: Subdirectory name under the raw-data root.
- `piv_video_file`: Filename of the main PIV video.
- `timelapse_video_file`: Filename of the time-lapse video.
- `waterlevel_file`: Filename of the water-level CSV.
- `runlog_file`: Filename of the run log.
- `piv_source`: Processing source, e.g. `pivlab`, `external`, `pending`.
- `run_status`: Processing state, e.g. `planned`, `completed`, `excluded`.
- `notes`: Free-text notes.
- `exclude_flag`: `true` or `false`.

## depth_bands.csv
Depth-band definition table used for visualization and band-wise metric aggregation.

One row corresponds to one representative depth band.

### Columns
- `band_id`: Depth-band identifier, e.g. `B1`, `B2`, `B3`, `B4`.
- `h_min_m`: Lower bound of the water-depth band in meters.
- `h_max_m`: Upper bound of the water-depth band in meters.
- `h_over_a_min`: Lower bound of the relative submergence range, where `a` is the port height.
- `h_over_a_max`: Upper bound of the relative submergence range.
- `label`: Short machine-friendly label for the band.
- `description`: Human-readable description of the band.
- `used_for_plot`: Boolean flag indicating whether the band is used for representative vector/streamline plots.
- `used_for_metrics`: Boolean flag indicating whether the band is used for band-wise metric aggregation such as `I_unst(B_k)`.

### Notes
- In this project, the port height is `a = 0.055 m`.
- The current depth bands are defined as:
  - `B1`: `0.03-0.05 m`, shallow condition with `h<a`
  - `B2`: `0.05-0.06 m`, transition band around `h/a ≈ 1`
  - `B3`: `0.06-0.075 m`, moderately submerged condition
  - `B4`: `0.075-0.10 m`, clearly submerged condition
- These bands are used for representative visualization and for depth-band-wise comparison of metrics.
- Continuous analyses as a function of `h/a` are handled separately from this table. This file is only for representative band definitions.

## flow_levels.csv
Flow-level definition table used to map qualitative flow levels to nominal water-level change rates and nominal discharge values.

One row corresponds to one nominal flow level.

### Columns
- `flow_level`: Flow-level identifier, e.g. `low`, `medium`, `high`.
- `nominal_dh_mm_min`: Nominal water-level change rate in mm/min.
- `nominal_Q_Lps`: Nominal discharge in L/s.
- `depth_range_m`: Intended water-depth sweep range for the standard run.
- `nominal_duration_min`: Nominal time required to sweep the standard depth range.
- `label`: Short machine-friendly label.
- `description`: Human-readable description of the flow level.
- `is_default`: Boolean flag indicating whether the row belongs to the default experiment set.

### Notes
- In this project, the standard depth sweep is `0.03-0.10 m`.
- Nominal discharge is derived from the plan area of the basin and the nominal water-level change rate.
- These values are used as design / bookkeeping values. Actual discharge may deviate from the nominal value depending on water depth and the degree of port submergence.
- Actual discharge should therefore be evaluated from the recorded water-level time series for each run and, when necessary, for each representative depth band.

## Relationship between metadata tables
- `runs.csv` defines run-level experimental metadata. One row corresponds to one run.
- `depth_bands.csv` defines representative depth bands used for visualization and band-wise metric aggregation.
- `flow_levels.csv` defines the nominal flow-level settings shared across runs.

In practice:
- `runs.csv` tells us which run was performed.
- `flow_levels.csv` tells us what `low`, `medium`, and `high` mean.
- `depth_bands.csv` tells us how continuous depth variation is grouped for representative analysis.

## Recommended workflow
1. Register all planned runs in `runs.csv`.
2. Keep the standard band definition in `depth_bands.csv`.
3. Keep the standard flow-level definition in `flow_levels.csv`.
4. After each experiment, update `runs.csv` with date, operator, run status, notes, and data location.
5. Use the recorded water-level time series to compute actual discharge and store the derived values outside the metadata tables, e.g. in run summaries or derived CSV files.

## General metadata policy
- Metadata tables are version-controlled in GitHub.
- Raw videos, intermediate `.mat` files, and large derived files are stored outside the repository.
- File names are kept minimal. Experimental conditions are managed primarily through metadata tables.
- Units should be explicit in column names whenever possible, e.g. `_m`, `_Lps`, `_mm_min`.
- Free-text comments should be stored in `notes` columns, while analysis logic should not depend on them.

## General metadata policy
- Metadata tables are version-controlled in GitHub.
- Raw videos, intermediate `.mat` files, and large derived files are stored outside the repository.
- File names are kept minimal. Experimental conditions are managed primarily through metadata tables.
- Units must be explicit in column names whenever possible, e.g. `_m`, `_Lps`, `_mm_min`.
- Free-text comments should be stored in `notes` columns, while analysis logic should not depend on them.

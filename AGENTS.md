# AGENTS.md

## Scope

This repository contains the MATLAB-based research workflow for **psp-singleport-regime**.

The goal is to support a short-to-medium-term research project on surface-flow regimes in a shallow rectangular basin with a reversible single port. Favor **clarity, reproducibility, and simplicity** over framework-heavy abstractions.

## Core principles

1. **Do not overengineer.**
   - This is a research codebase for a small team, not a general-purpose software product.
   - Prefer simple, readable function-based MATLAB code.
   - Avoid adding layers, classes, or configuration systems unless they clearly reduce repeated manual work.

2. **Preserve reproducibility.**
   - Raw data stay outside the repo.
   - Metadata, code, and lightweight documentation live in the repo.
   - Derived outputs should be reproducible from:
     - raw video / water-level data
     - metadata tables
     - MATLAB scripts and functions in this repo

3. **Keep the pipeline tool-agnostic after import.**
   - PIV may come from:
     - PIVLab
     - external commercial software
   - Normalize imported PIV results into the project’s canonical MATLAB struct before downstream metric computation.

4. **Prefer explicitness over cleverness.**
   - Use descriptive variable names.
   - Keep functions short.
   - Put assumptions in comments.
   - Do not hide important behavior in nested helper logic unless it is reused.

## Project layout

### Repository-side
- `config/` : project configuration and fixed constants
- `metadata/` : CSV tables defining runs, depth bands, and flow levels
- `src/` : MATLAB functions
- `scripts/` : driver scripts
- `docs/` : short protocol / workflow notes

### Data-side (gitignored, default under `local/`)
- `raw/` : raw videos, water-level csv, run log
- `work/` : run-wise intermediate files
- `derived/` : aggregated CSV outputs
- `results/` : paper figures, tables, and draft-side exports

## MATLAB coding conventions

- Use **function-based** MATLAB code. Do **not** introduce `classdef`.
- Driver scripts should follow the project naming style:
  - `s10_...`
  - `s20_...`
  - `s30_...`
- Reusable logic belongs in `src/`.
- Scripts should orchestrate work, not contain large blocks of repeated implementation.
- Use `struct` for lightweight grouped parameters.
- Prefer tables for metadata and exported analysis summaries.
- Use `NaN` for missing numeric values.
- Use `string` or table text columns consistently; do not mix arbitrary char/cellstr patterns without need.

## Metadata policy

The canonical metadata files are:

- `metadata/runs.csv`
- `metadata/depth_bands.csv`
- `metadata/flow_levels.csv`

Rules:
- Do not duplicate metadata already stored in CSV files into hard-coded constants unless it is truly fixed project geometry.
- If a script depends on one of these files, read it through a dedicated loader function.
- If you add a new metadata column, also update `metadata/README.md`.

## Geometry and physical conventions

Unless explicitly changed in metadata or constants:
- Basin plan dimensions: `3.0 m x 2.0 m`
- Basin depth: `0.33 m`
- Port width: `0.11 m`
- Port height: `0.055 m`
- Standard analysis depth range: `0.03 m` to `0.10 m`

Coordinate convention:
- `x` : basin longitudinal direction
- `y` : basin transverse direction
- `z` : vertical upward

## PIV workflow conventions

### Preprocessing
- Raw video is rectified and optionally preprocessed before PIV.
- Keep preprocessing simple.
- Avoid stacking too many image operations unless clearly justified by particle visibility.

### Rectification
- Store run-wise rectification metadata in `work/<run_id>/rectification.mat` or equivalent project-approved location.
- The saved rectification object must be sufficient to reproduce the transformation later.
- Do not require preview PNGs by default.

### PIV source handling
- PIVLab and external software are both acceptable.
- Tool-specific outputs should remain in `work/<run_id>/`.
- Downstream analysis should use canonical MATLAB `.mat` outputs, not tool-native project formats.

### Dual-dt logic
- If short/long frame-pair strategies are used, keep the logic explicit and documented.
- Record enough metadata to reconstruct the effective `dt_pair_s`.
- Do not bury the chosen pairing interval in undocumented GUI-only assumptions.

## Metrics policy

Primary metrics are the main results. Secondary metrics are optional and only shown when they provide stable, interpretable insight.

Current primary metrics include:
- `E(t)`
- `phi_lv(t)`
- `I_asym(t)`
- `I_circ(t)`
- `I_unst(B_k)`

Rules:
- Do not casually replace primary metrics after seeing results.
- Threshold tuning is acceptable during pilot-stage analysis, but once fixed it should remain stable for the main batch.
- If adding a new metric, document:
  - definition
  - intended physical meaning
  - whether it is primary or secondary

## Figure / results philosophy

- Do not produce many weak figures.
- Prefer a small number of interpretable figures aligned with the paper outline.
- Main results should support:
  1. inflow regimes
  2. outflow regimes
  3. comparative regime transition and mode asymmetry

## Writing conventions for this repo

When editing manuscript-related files:
- Keep Methods concise and journal-like.
- Avoid thesis-style overdocumentation.
- If a detail is only QA/QC and not central to the claim, keep it short.
- Do not overstate similitude. This project is a **prototype-informed laboratory experiment**, not a strict full similitude model.

## Safe change policy

When making edits:
- Prefer the smallest coherent change.
- Do not rename major files or move directories unless necessary.
- Do not silently rewrite metadata schemas.
- If a structural change is needed, explain it clearly in the diff or commit message.

## What to do when uncertain

If something is unclear:
1. Check `README.md`
2. Check `metadata/README.md`
3. Check `docs/`
4. Prefer simple implementations that match the current project structure
5. Avoid inventing a new abstraction unless the existing one clearly fails

## Maintenance rule

If recurring feedback appears more than once, update this `AGENTS.md` or the nearest project documentation so the correction persists.

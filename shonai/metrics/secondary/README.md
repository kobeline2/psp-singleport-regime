# Secondary metrics for psp-singleport-regime (inflow, MATLAB)

Two exploratory time-series metrics computed from the canonical surface-PIV
struct of the `psp-singleport-regime` project. Definitions are in the header
of each function.

| file | metric |
|---|---|
| `compute_reattachment_length.m` | reattachment length R(t) along the side wall, from the port wall (first reverse→forward sign change of the near-wall velocity; R/ΔB, ΔB = (basin width − port width)/2) |
| `compute_divergence_sign.m` | sign of the surface divergence relative to the rising water level, D′ = D − D_ref, D_ref = −(dh/dt)/h; area fractions f_up / f_down / f_undet |
| `s38_compute_reattachment_divergence.m` | driver for one run; writes `secondary_metrics.csv/mat` |

Both are expressed against time / water depth, not depth bands. Inflow only.

## Dependency (read-only)

These files need the `psp-singleport-regime` repository
(<https://github.com/kobeline2/psp-singleport-regime>) on the MATLAB path
(`init`, `compute_divergence_field`, `read_runs_table`, ...). That repository
belongs to someone else: **pull only, never edit or push**. Set `pspRoot` in the
driver to your local clone. Run `s30` and `s31` of that project first.

## Status

Run on all inflow runs R0001-R0012 (2026-10-27); results and caveats in
`NOTES_inflow_R0001-R0012.md`. The coordinate assumptions (x = 0 at the port
wall, `piv.u` = +x, `piv.v` along +y) were checked on R0009. `s38` also accepts outflow runs (R0013-R0024): R is skipped, only D' / D_ref
are written (2026-10-27). Provisional values
(averaging window, `u_eps`, `D_noise`) are still to be fixed.
`compute_reattachment_length` searches x <= `x_max_m` (default 2.4 m) to skip
the turning flow at the far wall. Figures: `scripts/s39_plot_reattachment_vs_depth.m`,
`scripts/s41_plot_divergence_sign_map.m`.

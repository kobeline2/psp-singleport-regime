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

Not yet run in MATLAB. Provisional values (averaging window, `u_eps`,
`D_noise`) must be checked on pilot runs, and the assumed coordinates
(x = 0 at the port wall, `piv.u` = +x) verified on the first run.

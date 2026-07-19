function C = constants()
%CONSTANTS Project-wide fixed constants.
% This file should only contain values that are genuinely fixed for the
% project and should not be duplicated in metadata CSV files.

C = struct();

% -------------------------------------------------------------------------
% Project identity
% -------------------------------------------------------------------------
C.project_name = 'psp-singleport-regime';

% -------------------------------------------------------------------------
% Basin geometry
% -------------------------------------------------------------------------
C.basin = struct();
C.basin.Lx_m = 3.0;
C.basin.Ly_m = 2.0;
C.basin.H_m  = 0.33;
C.basin.Aplan_m2 = C.basin.Lx_m * C.basin.Ly_m;

% -------------------------------------------------------------------------
% Port geometry
% -------------------------------------------------------------------------
C.port = struct();
C.port.width_m  = 0.11;
C.port.height_m = 0.055;
C.port.bottom_z_m = 0.0;
C.port.area_m2 = C.port.width_m * C.port.height_m;

% -------------------------------------------------------------------------
% Standard run depth limits
% -------------------------------------------------------------------------
C.depth = struct();
C.depth.h_min_m = 0.03;
C.depth.h_max_m = 0.10;

% -------------------------------------------------------------------------
% Physical constants
% -------------------------------------------------------------------------
C.phys = struct();
C.phys.g_m_s2 = 9.81;
C.phys.nu_m2_s = 1.0e-6;   % use updated value later if temperature correction is needed
C.phys.rho_kg_m3 = 1000.0;

% -------------------------------------------------------------------------
% Coordinate / domain conventions
% -------------------------------------------------------------------------
C.coord = struct();
C.coord.x_name = 'x';
C.coord.y_name = 'y';
C.coord.z_name = 'z';
C.coord.z_positive = 'up';

% -------------------------------------------------------------------------
% PIV naming conventions
% -------------------------------------------------------------------------
C.piv = struct();
C.piv.variant_short = 'short';
C.piv.variant_long  = 'long';
C.piv.variant_merged = 'merged';

% These are placeholders and should be fixed after pilot runs.
C.piv.dt_short_s = NaN;
C.piv.dt_long_s  = NaN;

% -------------------------------------------------------------------------
% Metric defaults
% -------------------------------------------------------------------------
C.metrics = struct();

% Threshold factor for low-velocity area:
% u_th = alpha * U_p
% Fixed at 0.2 from the pilot analysis (2026-07): with alpha = 0.2 the
% inflow phi_lv resolves the h/a dependence cleanly (~0.22 shallow ->
% ~0.60 submerged), while the outflow surface stays below u_th almost
% everywhere (phi_lv ~= 1). The outflow saturation is reported as a
% finding (the port forcing does not reach the free surface), not treated
% as a defect of the metric.
C.metrics.alpha_u_th = 0.2;

% Measured PIV noise floor of E = <|u|^2> [m^2/s^2], from the pilot batch:
% outflow-low runs sit at rms displacement ~0.06 px/frame ~ the PIV
% uncertainty, giving E ~ 2e-7. Band means below ~3x this floor should be
% flagged as resolution-limited rather than interpreted quantitatively.
C.metrics.E_noise_floor_m2_s2 = 2.0e-7;

% Quiescent-start criterion
C.metrics.quiescent_rel_threshold = 0.05;
C.metrics.quiescent_hold_min = 5.0;

% -------------------------------------------------------------------------
% Common labels / allowed values
% -------------------------------------------------------------------------
C.labels = struct();
C.labels.modes = {'inflow','outflow'};
C.labels.flow_levels = {'low','medium','high'};
C.labels.run_status = {'planned','completed','excluded','reprocessed'};
C.labels.piv_source = {'pending','pivlab','external','merged'};

end

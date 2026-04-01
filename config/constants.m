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
% Leave as NaN until fixed from pilot analysis.
C.metrics.alpha_u_th = NaN;

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

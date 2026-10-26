clear; clc;
%% s38_compute_reattachment_divergence.m
% Compute the two secondary time-series metrics for one inflow run:
%
%   R(t)       reattachment length along the side wall, measured from the
%              port wall (compute_reattachment_length)
%   D'(t) sign up/down-welling relative to the rising water level
%              (compute_divergence_sign)
%
% Both are expressed against time / water depth (not depth bands). Run s30
% and s31 first: this script needs frame_metrics.mat with time_s and
% depth_m. Output is written next to frame_metrics:
%   local/derived/metrics/<run_id>/secondary_metrics.{csv,mat}
%
% Inflow runs only. For daily/per-run use, copy this file and edit the copy.
%
% Dependency: this folder is NOT self-contained. It uses the functions,
% metadata and data layout of the (read-only) psp-singleport-regime
% repository (init, constants, metrics_defaults, compute_divergence_field,
% read_runs_table, read_waterlevel, ...). Pull that repository and set
% pspRoot below. Never edit or push to it from here.

pspRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(char(pspRoot));
init
addpath(fileparts(mfilename('fullpath')));    % this folder

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
opts = metrics_defaults();
show_figure = true;

% Secondary-metric settings. All are provisional until the pilot analysis;
% fix them once and keep them for all runs.
opts.secondary_avg_window_s = 30;    % moving-average window [s]
opts.reattach_u_eps_m_s     = 1e-3;  % |u| below this carries no sign (~2x PIV noise rms)
opts.divsign_D_noise_1_s    = 5e-3;  % sign-resolution threshold of D' [1/s]
                                     % (~3x propagated PIV noise; replace by a
                                     % quiescent-frame measurement)

% -------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));
assert(string(row.mode) == "inflow", ...
    's38:InflowOnly', 'This metric is defined for inflow runs only (%s is %s).', ...
    char(runID), char(row.mode));

pivMat = fullfile(cfg.WORK_DIR, char(runID), cfg.PIV_SINGLE_MAT);
outDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
frameMetricsMat = fullfile(outDir, opts.frame_metrics_mat_name);
assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
assert(isfile(frameMetricsMat), ...
    'frame_metrics.mat not found for %s. Run s30 and s31 first.', char(runID));

S = load(pivMat, 'piv');
piv = S.piv;
F = load(frameMetricsMat, 'frameMetrics');
fm = F.frameMetrics;
assert(ismember('depth_m', fm.Properties.VariableNames) && any(isfinite(fm.depth_m)), ...
    's38:NoDepth', 'depth_m is missing in frame_metrics. Run s31_map_waterlevel.m first.');

fprintf('[s38] run_id : %s\n', char(runID));
fprintf('[s38] input  : %s\n', pivMat);

% -------------------------------------------------------------------------
% Geometry (basin coordinates: x = 0 at the port wall, port at mid-width)
% -------------------------------------------------------------------------
dB_m = (C.basin.Ly_m - C.port.width_m) / 2;   % lateral expansion per side
yPort_m = C.basin.Ly_m / 2;

% -------------------------------------------------------------------------
% Metrics
% -------------------------------------------------------------------------
[Rt, infoR] = compute_reattachment_length(piv, ...
    'time_s', fm.time_s, ...
    'avg_window_s', opts.secondary_avg_window_s, ...
    'u_eps_m_s', opts.reattach_u_eps_m_s, ...
    'dB_m', dB_m);

Dt = compute_divergence_sign(piv, ...
    'time_s', fm.time_s, ...
    'depth_m', fm.depth_m, ...
    'smooth_sigma', opts.smooth_sigma_div, ...
    'D_noise_1_s', opts.divsign_D_noise_1_s, ...
    'avg_window_s', opts.secondary_avg_window_s, ...
    'port_center_y_m', yPort_m, ...
    'edge_margin_cells', 4, ...   % Gaussian smoothing (sigma 1.5) + gradient bias D within 4 cells of the border
    'log_every', opts.log_every);

fprintf('[s38] wall rows used: y = %s m (ymin side), %s m (ymax side)\n', ...
    mat2str(infoR.y_rows_lo, 3), mat2str(infoR.y_rows_hi, 3));
fprintf('[s38] frames with a reattachment point: %d / %d\n', ...
    nnz(isfinite(Rt.R_m)), height(Rt));

secondary = [Dt, Rt(:, {'R_ymin_m', 'R_ymax_m', 'R_m', 'R_side', 'R_over_dB'})];
if ismember('band_id', fm.Properties.VariableNames)
    secondary.band_id = fm.band_id;   % reference label only; metrics are not band-averaged
end

writetable(secondary, fullfile(outDir, 'secondary_metrics.csv'));
save(fullfile(outDir, 'secondary_metrics.mat'), 'secondary', 'opts', 'infoR', '-v7');
fprintf('[s38] wrote %s\n', fullfile(outDir, 'secondary_metrics.csv'));

% -------------------------------------------------------------------------
% Quick look (exploratory, not a paper figure)
% -------------------------------------------------------------------------
if show_figure
    fig = figure('Name', sprintf('%s secondary metrics', char(runID)), 'Color', 'w');
    tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');

    ax1 = nexttile(tl);
    plot(ax1, secondary.depth_m, secondary.R_over_dB, '.-');
    ylabel(ax1, 'R / \DeltaB'); grid(ax1, 'on');
    title(ax1, sprintf('%s  reattachment length (NaN = none)', char(runID)));

    ax2 = nexttile(tl);
    hold(ax2, 'on');
    plot(ax2, secondary.depth_m, secondary.f_up_win, '-');
    plot(ax2, secondary.depth_m, secondary.f_down_win, '-');
    plot(ax2, secondary.depth_m, secondary.f_undet_win, '-');
    hold(ax2, 'off'); grid(ax2, 'on');
    xlabel(ax2, 'depth h [m]'); ylabel(ax2, 'area fraction');
    legend(ax2, {'upwelling (D''>0)', 'downwelling (D''<0)', 'undetermined'}, ...
        'Location', 'best');
    title(ax2, 'sign of D'' = D - D_{ref}');
end

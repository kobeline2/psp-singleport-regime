clear; clc;
%% s37_plot_band_mean_field.m
% Time-mean (band-averaged) surface velocity field for one run, one panel
% per depth band B1..B4.
%
% This is the paper's core regime-visualization figure: it reveals the
% deflected-jet / twin-cell structure under inflow and the basin-scale
% single-cell circulation under outflow. Time-averaging within each band
% suppresses PIV noise (~1/sqrt(N)), so the weak outflow structure is
% recovered even when instantaneous fields are near the noise floor.
%
% Needs pivlab_single.mat (s20) and frame_metrics with band_id (s30 + s31).
%
% For daily use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
quiver_step = 3;
save_png = true;

% -------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

pivMat = fullfile(cfg.WORK_DIR, char(runID), cfg.PIV_SINGLE_MAT);
metricsMat = fullfile(cfg.DERIVED_METRICS_DIR, char(runID), 'frame_metrics.mat');
assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
assert(isfile(metricsMat), ...
    'frame_metrics.mat not found for %s. Run s30 then s31 first.', char(runID));

S = load(pivMat, 'piv'); piv = S.piv;
M = load(metricsMat, 'frameMetrics'); fm = M.frameMetrics;
assert(ismember('band_id', fm.Properties.VariableNames) && any(fm.band_id ~= ""), ...
    'frame_metrics has no band_id. Run s31_map_waterlevel.m first.');

bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');

% -------------------------------------------------------------------------
% Compute and plot
% -------------------------------------------------------------------------
fields = compute_band_mean_field(piv, fm.band_id, bands);

titleStr = sprintf('%s  %s %s  -  band-mean surface velocity', ...
    char(runID), char(row.mode), char(row.flow_level));
fig = plot_band_mean_fields(fields, ...
    'Lx_m', C.basin.Lx_m, 'Ly_m', C.basin.Ly_m, ...
    'quiver_step', quiver_step, 'title_prefix', titleStr);

if save_png
    if ~exist(cfg.RESULTS_FIG_DIR, 'dir'); mkdir(cfg.RESULTS_FIG_DIR); end
    outPng = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_band_mean_field.png', runID));
    exportgraphics(fig, outPng, 'Resolution', 180);
    fprintf('[s37_plot_band_mean_field] wrote %s\n', outPng);
end

for b = 1:numel(fields)
    fprintf('[s37_plot_band_mean_field] %s: n=%d, max mean speed=%.4g m/s\n', ...
        fields(b).band_id, fields(b).n_frames, max(fields(b).speed(:)));
end

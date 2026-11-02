clear; clc;
%% s41_plot_divergence_sign_map.m
% Up/down-welling map of one inflow run: time-mean D' = D - D_ref on the
% basin plan view, one panel per depth band (metadata/depth_bands.csv).
%
% Needs pivlab_single.mat (s20) and secondary_metrics.mat (written by
% shonai/metrics/secondary/s38_compute_reattachment_divergence.m, which also
% provides D_ref and the water depth per frame).
% For daily/per-run use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
d_noise_1_s = 5e-3;      % sign threshold, same value as s38 (provisional)
smooth_sigma = 1.5;      % same as metrics_defaults.smooth_sigma_div
edge_margin_cells = 4;   % smoothing + gradient bias D within 4 cells of the border
save_png = true;
show_figure = true;

% -------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
pivMat = fullfile(cfg.WORK_DIR, char(runID), cfg.PIV_SINGLE_MAT);
secondaryMat = fullfile(cfg.DERIVED_METRICS_DIR, char(runID), 'secondary_metrics.mat');
assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
assert(isfile(secondaryMat), 'secondary_metrics.mat not found for %s. Run s38 first.', char(runID));

fprintf('[s41] run_id : %s\n', char(runID));
S = load(pivMat, 'piv');
piv = S.piv;
F = load(secondaryMat, 'secondary');
bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
[fig, stats] = plot_divergence_sign_map(piv, F.secondary, bands, ...
    'd_noise_1_s', d_noise_1_s, 'smooth_sigma', smooth_sigma, ...
    'edge_margin_cells', edge_margin_cells, ...
    'port_center_y_m', C.basin.Ly_m / 2, 'port_width_m', C.port.width_m, ...
    'basin_size_m', [C.basin.Lx_m, C.basin.Ly_m]);

for b = 1:numel(stats)
    fprintf('[s41] %s: %d frames | up %.2f, down %.2f, undetermined %.2f\n', ...
        char(stats(b).band_id), stats(b).n_frames, stats(b).f_up, stats(b).f_down, stats(b).f_undet);
end

if save_png
    if ~exist(cfg.RESULTS_FIG_DIR, 'dir'), mkdir(cfg.RESULTS_FIG_DIR); end
    pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_divergence_sign_map_by_band.png', runID));
    exportgraphics(fig, pngPath, 'Resolution', 150);
    fprintf('[s41] wrote %s\n', pngPath);
end
if ~show_figure
    close(fig);
end

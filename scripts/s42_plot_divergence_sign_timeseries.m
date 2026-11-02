clear; clc;
%% s42_plot_divergence_sign_timeseries.m
% Time series of the up/down-welling area fractions of one run (inflow or
% outflow): block-mean D' = D - D_ref, counted against a detection limit
% derived from the measured single-frame noise of D.
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
block_s = 30;            % averaging block [s]
k_sigma = 3;             % detection limit = k_sigma * sigma_noise / sqrt(frames per block)
noise_min_depth_m = 0.05;% frames deeper than this are used to measure sigma_noise
save_png = true;
save_csv = true;
show_figure = true;

% -------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
pivMat = fullfile(cfg.WORK_DIR, char(runID), cfg.PIV_SINGLE_MAT);
outDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
secondaryMat = fullfile(outDir, 'secondary_metrics.mat');
assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
assert(isfile(secondaryMat), 'secondary_metrics.mat not found for %s. Run s38 first.', char(runID));

fprintf('[s42] run_id : %s\n', char(runID));
S = load(pivMat, 'piv');
piv = S.piv;
F = load(secondaryMat, 'secondary');

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
[fig, blocks, info] = plot_divergence_sign_timeseries(piv, F.secondary, ...
    'block_s', block_s, 'k_sigma', k_sigma, 'noise_min_depth_m', noise_min_depth_m, ...
    'port_center_y_m', C.basin.Ly_m / 2);
fprintf('[s42] sigma_noise = %.2e 1/s, dt = %.3f s, %d frames/block, detection limit = %.2e 1/s\n', ...
    info.sigma_noise_1_s, info.dt_s, info.n_per_block, blocks.limit_1_s(1));

if save_csv
    writetable(blocks, fullfile(outDir, 'divergence_sign_blocks.csv'));
end
if save_png
    if ~exist(cfg.RESULTS_FIG_DIR, 'dir'), mkdir(cfg.RESULTS_FIG_DIR); end
    pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_divergence_sign_timeseries.png', runID));
    exportgraphics(fig, pngPath, 'Resolution', 150);
    fprintf('[s42] wrote %s\n', pngPath);
end
if ~show_figure
    close(fig);
end

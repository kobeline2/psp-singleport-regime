clear; clc;
%% s43_plot_divergence_sign_frequency_map.m
% Where does up/down-welling occur most often? Per cell and depth band, the
% fraction of 30 s blocks in which the block-mean D' = D - D_ref is above /
% below the detection limit (measured from the single-frame noise of D).
% Also lists connected regions where the frequency is high (hotspots).
%
% Needs pivlab_single.mat (s20) and secondary_metrics.mat (written by
% shonai/metrics/secondary/s38_compute_reattachment_divergence.m).
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
min_abs_1_s = 5e-3;      % count only |D'| above this (D_ref subtraction leaves an offset of ~|D_ref|)
hotspot_freq = 0.8;      % a hotspot is a connected region with frequency >= this
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

fprintf('[s43] run_id : %s\n', char(runID));
S = load(pivMat, 'piv');
piv = S.piv;
F = load(secondaryMat, 'secondary');
bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');

% -------------------------------------------------------------------------
% Figure and hotspot table
% -------------------------------------------------------------------------
[fig, hotspots, info] = plot_divergence_sign_frequency_map(piv, F.secondary, bands, ...
    'block_s', block_s, 'k_sigma', k_sigma, 'min_abs_1_s', min_abs_1_s, ...
    'hotspot_freq', hotspot_freq, ...
    'port_center_y_m', C.basin.Ly_m / 2, 'port_width_m', C.port.width_m, ...
    'basin_size_m', [C.basin.Lx_m, C.basin.Ly_m]);
fprintf('[s43] sigma_noise = %.2e 1/s, detection limit = %.2e 1/s, blocks per band: %s\n', ...
    info.sigma_noise_1_s, info.limit_1_s, mat2str(info.n_blocks.'));
disp(hotspots);

if save_csv
    writetable(hotspots, fullfile(outDir, 'divergence_sign_hotspots.csv'));
end
if save_png
    if ~exist(cfg.RESULTS_FIG_DIR, 'dir'), mkdir(cfg.RESULTS_FIG_DIR); end
    pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_divergence_sign_frequency_map.png', runID));
    exportgraphics(fig, pngPath, 'Resolution', 150);
    fprintf('[s43] wrote %s\n', pngPath);
end
if ~show_figure
    close(fig);
end

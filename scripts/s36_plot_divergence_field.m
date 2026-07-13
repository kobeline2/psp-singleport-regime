clear; clc;
%% s36_plot_divergence_field.m
% Compute and visualize the surface horizontal divergence field for one run.
%
% Secondary, exploratory metric (NOT a fixed primary metric).
%
%   D(x,y) = du/dx + dv/dy   (proxy for dw/dz; D>0 upwelling, D<0 downwelling)
%
% This script:
%   - loads pivlab_single.mat
%   - computes the per-frame divergence field and its time mean
%   - saves the field to local/derived/fields/<run_id>/divergence.mat
%   - plots and saves the time-mean divergence map
%
% The frame-wise scalar D_rms(t) is produced separately by s30 and shown in
% the s35 overview; this script focuses on the spatial map.

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
opts = metrics_defaults();

% Gaussian pre-smoothing sigma [grid cells] for divergence (essential).
% opts.smooth_sigma_div is set in metrics_defaults; override here if needed.

save_field = true;   % save divergence.mat (per-frame field + time mean)
save_png   = true;
save_fig   = false;
show_figure = true;
clim_percentile = 98;   % symmetric color limit percentile for the map
title_suffix = "";

% Optional gitignored local override script.
settingsFile = fullfile(cfg.SCRIPTS_DIR, 's36_plot_divergence_field_local.m');
if isfile(settingsFile)
    fprintf('[s36_plot_divergence_field] Loading local settings: %s\n', settingsFile);
    run(settingsFile);
end

% -------------------------------------------------------------------------
% Resolve paths
% -------------------------------------------------------------------------
workRunDir = fullfile(cfg.WORK_DIR, char(runID));
pivMat     = fullfile(workRunDir, cfg.PIV_SINGLE_MAT);

fieldsDir  = fullfile(cfg.DERIVED_DIR, 'fields', char(runID));
fieldMat   = fullfile(fieldsDir, 'divergence.mat');

if ~exist(cfg.RESULTS_FIG_DIR, 'dir')
    mkdir(cfg.RESULTS_FIG_DIR);
end
pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_divergence_mean.png', runID));
figPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_divergence_mean.fig', runID));

fprintf('[s36_plot_divergence_field] run_id : %s\n', char(runID));
fprintf('[s36_plot_divergence_field] input  : %s\n', pivMat);
fprintf('[s36_plot_divergence_field] field  : %s\n', fieldMat);
fprintf('[s36_plot_divergence_field] figure : %s\n', pngPath);

assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);

% -------------------------------------------------------------------------
% Load PIV and compute divergence field
% -------------------------------------------------------------------------
S = load(pivMat, 'piv');
assert(isfield(S, 'piv'), 'File does not contain variable "piv": %s', pivMat);
piv = S.piv;

div = compute_divergence_field(piv, ...
    'smooth_sigma', opts.smooth_sigma_div, ...
    'return_field', true, ...
    'log_every', opts.log_every);

fprintf('[s36_plot_divergence_field] frames    : %d\n', numel(div.frame_idx));
fprintf('[s36_plot_divergence_field] smooth    : sigma = %.3g cells\n', div.smooth_sigma);
fprintf('[s36_plot_divergence_field] mean D_rms: %.4g 1/s\n', mean(div.D_rms, 'omitnan'));

% -------------------------------------------------------------------------
% Save field artifact
% -------------------------------------------------------------------------
if save_field
    if ~exist(fieldsDir, 'dir')
        mkdir(fieldsDir);
    end
    save(fieldMat, 'div', '-v7.3');
    fprintf('[s36_plot_divergence_field] wrote %s\n', fieldMat);
end

% -------------------------------------------------------------------------
% Plot time-mean divergence map
% -------------------------------------------------------------------------
titleStr = sprintf('%s | mean surface divergence', runID);
if strlength(string(title_suffix)) > 0
    titleStr = sprintf('%s | %s', titleStr, string(title_suffix));
end

fig = plot_divergence_field(div.D_mean, div.x, div.y, ...
    'title_str', titleStr, ...
    'clim_percentile', clim_percentile);

if save_png
    exportgraphics(fig, pngPath, 'Resolution', 180);
    fprintf('[s36_plot_divergence_field] wrote %s\n', pngPath);
end
if save_fig
    savefig(fig, figPath);
    fprintf('[s36_plot_divergence_field] wrote %s\n', figPath);
end
if ~show_figure
    close(fig);
end

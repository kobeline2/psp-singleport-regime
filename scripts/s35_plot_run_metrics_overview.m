clear; clc;
%% s35_plot_run_metrics_overview.m
% Make a quick-look overview figure for one run from frame_metrics.mat.
%
% This script is intended for exploratory inspection of a single case. It
% is not the paper-figure pipeline.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
smooth_span_frames = 31;
save_png = true;
save_fig = false;
show_figure = true;

% Optional title note appended to the figure title.
title_suffix = "";

% -------------------------------------------------------------------------
% Resolve input / output paths
% -------------------------------------------------------------------------
metricsDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
frameMetricsMat = fullfile(metricsDir, 'frame_metrics.mat');
frameMetricsCsv = fullfile(metricsDir, 'frame_metrics.csv');

if ~exist(cfg.RESULTS_FIG_DIR, 'dir')
    mkdir(cfg.RESULTS_FIG_DIR);
end

pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_frame_metrics_overview.png', runID));
figPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_frame_metrics_overview.fig', runID));

fprintf('[s35_plot_run_metrics_overview] run_id : %s\n', char(runID));
fprintf('[s35_plot_run_metrics_overview] input  : %s\n', frameMetricsMat);
fprintf('[s35_plot_run_metrics_overview] output : %s\n', pngPath);

% -------------------------------------------------------------------------
% Load metrics table
% -------------------------------------------------------------------------
if isfile(frameMetricsMat)
    S = load(frameMetricsMat, 'frameMetrics');
    assert(isfield(S, 'frameMetrics'), ...
        'File does not contain variable "frameMetrics": %s', frameMetricsMat);
    frameMetrics = S.frameMetrics;
elseif isfile(frameMetricsCsv)
    frameMetrics = readtable(frameMetricsCsv, 'TextType', 'string');
else
    error(['Neither frame_metrics.mat nor frame_metrics.csv was found for %s. ' ...
           'Run s30_compute_metrics.m first.'], char(runID));
end

assert(istable(frameMetrics) && height(frameMetrics) >= 1, ...
    'frameMetrics must be a non-empty table.');

% -------------------------------------------------------------------------
% Build and save figure
% -------------------------------------------------------------------------
fig = plot_frame_metrics_overview(frameMetrics, ...
    'smooth_span_frames', smooth_span_frames, ...
    'title_suffix', title_suffix);

if save_png
    exportgraphics(fig, pngPath, 'Resolution', 180);
    fprintf('[s35_plot_run_metrics_overview] wrote %s\n', pngPath);
end

if save_fig
    savefig(fig, figPath);
    fprintf('[s35_plot_run_metrics_overview] wrote %s\n', figPath);
end

if ~show_figure
    close(fig);
end

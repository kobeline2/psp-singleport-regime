clear; clc;
%% s30_compute_metrics.m
% Compute frame-wise and band-wise metrics from canonical PIV MAT files.
%
% This script is intended to replace the older split entry points for
% frame metrics, band aggregation, and CSV export.

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
variant = "merged";   % preferred analysis input once dual-dt merging exists

pivDir = fullfile(cfg.DERIVED_PIV_DIR, char(runID));
pivMat = fullfile(pivDir, sprintf('piv_%s.mat', char(variant)));

fprintf('[s30_compute_metrics] run_id  : %s\n', char(runID));
fprintf('[s30_compute_metrics] variant : %s\n', char(variant));
fprintf('[s30_compute_metrics] input   : %s\n', pivMat);
fprintf('[s30_compute_metrics] outputs : %s\n', cfg.DERIVED_METRICS_DIR);

error(['s30_compute_metrics is a consolidated placeholder. ' ...
       'Next step: implement metric functions in src/ that load canonical ' ...
       'pivrun data, compute frame_metrics and band_metrics, and export ' ...
       'frame_metrics.csv, band_metrics.csv, and run_summary.csv.']);

clear; clc;
%% s30_compute_metrics.m
% Compute basic frame-wise metrics from canonical single-dt PIV MAT files.
%
% Current scope:
%   - loads pivlab_single.mat
%   - computes minimal frame-wise metrics that depend only on the PIV data
%   - leaves depth / band fields as placeholders for a later stage

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
opts = metrics_defaults();

% Provisional threshold for phi_lv(t). Keep this explicit until the pilot
% analysis fixes the project-wide value.
opts.low_speed_threshold_m_s = 0.02;

% Progress log interval for long runs
opts.log_every = 500;

workRunDir = fullfile(cfg.WORK_DIR, char(runID));
pivMat = fullfile(workRunDir, cfg.PIV_SINGLE_MAT);
outDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
frameMetricsCsv = fullfile(outDir, opts.frame_metrics_csv_name);
frameMetricsMat = fullfile(outDir, opts.frame_metrics_mat_name);

fprintf('[s30_compute_metrics] run_id  : %s\n', char(runID));
fprintf('[s30_compute_metrics] variant : single_dt\n');
fprintf('[s30_compute_metrics] input   : %s\n', pivMat);
fprintf('[s30_compute_metrics] out dir  : %s\n', outDir);

assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

S = load(pivMat, 'piv');
assert(isfield(S, 'piv'), 'File does not contain variable "piv": %s', pivMat);
piv = S.piv;

frameMetrics = compute_frame_metrics_basic(piv, ...
    'low_speed_threshold_m_s', opts.low_speed_threshold_m_s, ...
    'log_every', opts.log_every);

writetable(frameMetrics, frameMetricsCsv);
save(frameMetricsMat, 'frameMetrics', 'opts', '-v7');

fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsCsv);
fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsMat);
fprintf('[s30_compute_metrics] computed %d frame rows\n', height(frameMetrics));
disp(frameMetrics(1:min(5, height(frameMetrics)), :));

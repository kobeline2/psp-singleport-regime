clear; clc;
%% s30_compute_metrics.m
% Compute frame-wise metrics from canonical single-dt PIV MAT files.
%
% Current scope:
%   - loads pivlab_single.mat
%   - computes the frame-wise primary metrics that depend only on the PIV
%     data: E, phi_lv, I_asym (compute_frame_metrics_basic) and I_circ
%     (compute_frame_metrics_circ, normalized by the port velocity U_p)
%   - leaves depth / band fields as placeholders filled later by
%     s31_map_waterlevel.m

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
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

% -------------------------------------------------------------------------
% Circulation index I_circ = <(a/U_p) omega>_Omega.
% U_p = Q / (a b) is the port mean velocity. Q is the nominal discharge for
% this run's flow level (a fixed design value per level, so I_circ is
% comparable across repetitions and flow rates); a, b are the port height
% and width from constants.
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

a_m = C.port.height_m;
b_m = C.port.width_m;
U_p = (row.nominal_Q_Lps / 1000) / (a_m * b_m);   % m/s
opts.U_p_m_s = U_p;

circ = compute_frame_metrics_circ(piv, ...
    'U_p_m_s', U_p, ...
    'port_height_m', a_m, ...
    'smooth_sigma', opts.smooth_sigma_circ, ...
    'log_every', opts.log_every);

assert(height(circ) == height(frameMetrics), ...
    's30_compute_metrics:CircRowMismatch', ...
    'I_circ table (%d rows) does not match basic metrics (%d rows).', ...
    height(circ), height(frameMetrics));
frameMetrics.omega_mean = circ.omega_mean;
frameMetrics.I_circ = circ.I_circ;

fprintf('[s30_compute_metrics] U_p = %.4f m/s (nominal Q = %.2f L/s)\n', ...
    U_p, row.nominal_Q_Lps);

writetable(frameMetrics, frameMetricsCsv);
save(frameMetricsMat, 'frameMetrics', 'opts', '-v7');

fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsCsv);
fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsMat);
fprintf('[s30_compute_metrics] computed %d frame rows\n', height(frameMetrics));
disp(frameMetrics(1:min(5, height(frameMetrics)), :));

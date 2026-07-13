clear; clc;
%% s30_compute_metrics.m
% Compute frame-wise metrics from canonical single-dt PIV MAT files.
%
% Current scope:
%   - loads pivlab_single.mat
%   - computes basic frame-wise metrics (E, phi_lv, I_asym)
%   - computes circulation index I_circ via vorticity averaging
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

% Gaussian pre-smoothing sigma for vorticity [grid cells]; 0 = no smoothing.
% opts.smooth_sigma_circ = 0;   % already set in metrics_defaults

% Optional gitignored local override script.
% Copy scripts/s30_compute_metrics_local.m.example to
% scripts/s30_compute_metrics_local.m and set only the values you want to
% change for the current run.
settingsFile = fullfile(cfg.SCRIPTS_DIR, 's30_compute_metrics_local.m');
if isfile(settingsFile)
    fprintf('[s30_compute_metrics] Loading local settings: %s\n', settingsFile);
    run(settingsFile);
end

% -------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------
workRunDir     = fullfile(cfg.WORK_DIR, char(runID));
pivMat         = fullfile(workRunDir, cfg.PIV_SINGLE_MAT);
outDir         = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
frameMetricsCsv = fullfile(outDir, opts.frame_metrics_csv_name);
frameMetricsMat = fullfile(outDir, opts.frame_metrics_mat_name);

fprintf('[s30_compute_metrics] run_id  : %s\n', char(runID));
fprintf('[s30_compute_metrics] variant : single_dt\n');
fprintf('[s30_compute_metrics] input   : %s\n', pivMat);
fprintf('[s30_compute_metrics] out dir : %s\n', outDir);

assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% -------------------------------------------------------------------------
% Load PIV data
% -------------------------------------------------------------------------
S = load(pivMat, 'piv');
assert(isfield(S, 'piv'), 'File does not contain variable "piv": %s', pivMat);
piv = S.piv;

% -------------------------------------------------------------------------
% Resolve U_p for I_circ normalization
% -------------------------------------------------------------------------
% U_p = Q / (a * b), where Q is the nominal discharge for this run.
% Using the nominal Q (not the actual time-varying Q) as a fixed
% normalization constant for the run.
T_runs = read_runs_table(cfg);
runRow = T_runs(T_runs.run_id == runID, :);
assert(height(runRow) == 1, 'Run ID not found in runs.csv: %s', char(runID));
Q_m3s   = runRow.nominal_Q_Lps * 1e-3;
U_p_m_s = Q_m3s / (C.port.height_m * C.port.width_m);

fprintf('[s30_compute_metrics] Q_nom   : %.4f L/s\n', Q_m3s * 1e3);
fprintf('[s30_compute_metrics] U_p     : %.4f m/s\n', U_p_m_s);

% -------------------------------------------------------------------------
% Compute basic metrics (E, phi_lv, I_asym) and circulation (I_circ)
% -------------------------------------------------------------------------
frameMetrics = compute_frame_metrics_basic(piv, ...
    'low_speed_threshold_m_s', opts.low_speed_threshold_m_s, ...
    'log_every', opts.log_every);

circMetrics = compute_frame_metrics_circ(piv, ...
    'U_p_m_s',       U_p_m_s, ...
    'port_height_m', C.port.height_m, ...
    'smooth_sigma',  opts.smooth_sigma_circ, ...
    'log_every',     opts.log_every);

% Surface-divergence structure strength D_rms(t) (secondary metric).
% return_field=false keeps this memory-light: the full field is produced by
% s36, not stored here. Only the frame-wise scalar is appended.
divMetrics = compute_divergence_field(piv, ...
    'smooth_sigma',  opts.smooth_sigma_div, ...
    'return_field',  false, ...
    'log_every',     opts.log_every);

% Append I_circ and divergence columns to the main metrics table.
% All share the same frame order (1:nFrames).
frameMetrics.omega_mean        = circMetrics.omega_mean;
frameMetrics.I_circ            = circMetrics.I_circ;
frameMetrics.U_p_m_s           = circMetrics.U_p_m_s;
frameMetrics.smooth_sigma_circ = circMetrics.smooth_sigma;
frameMetrics.div_rms           = divMetrics.D_rms;
frameMetrics.smooth_sigma_div  = repmat(divMetrics.smooth_sigma, height(frameMetrics), 1);

% -------------------------------------------------------------------------
% Save outputs
% -------------------------------------------------------------------------
writetable(frameMetrics, frameMetricsCsv);
save(frameMetricsMat, 'frameMetrics', 'opts', '-v7');

fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsCsv);
fprintf('[s30_compute_metrics] wrote %s\n', frameMetricsMat);
fprintf('[s30_compute_metrics] computed %d frame rows\n', height(frameMetrics));
disp(frameMetrics(1:min(5, height(frameMetrics)), :));

function M = metrics_defaults()
%METRICS_DEFAULTS Default settings for minimal frame-wise metric computation.
%
% Notes:
%   - low_speed_threshold_m_s is provisional and should be fixed after the
%     pilot analysis is reviewed.
%   - depth / band mapping is intentionally left for a later stage.

M = struct();

% Low-speed threshold used for phi_lv(t)
M.low_speed_threshold_m_s = 0.02;

% Print progress every N frames for long runs
M.log_every = 500;

% Per-run output filenames written under local/derived/metrics/<run_id>/
M.frame_metrics_csv_name = 'frame_metrics.csv';
M.frame_metrics_mat_name = 'frame_metrics.mat';
end

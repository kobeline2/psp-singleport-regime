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

% Gaussian pre-smoothing sigma [grid cells] applied to u and v before
% vorticity differentiation (used in compute_frame_metrics_circ).
% 0 = no smoothing.  Fix this value after pilot analysis and apply
% consistently across all runs.
M.smooth_sigma_circ = 0;

% Gaussian pre-smoothing sigma [grid cells] for the surface-divergence
% field (used in compute_divergence_field and the D_rms scalar in s30).
% Smoothing is essential for divergence, so the default is > 0.
% Fix after pilot analysis and apply consistently across all runs.
M.smooth_sigma_div = 1.5;

% Per-run output filenames written under local/derived/metrics/<run_id>/
M.frame_metrics_csv_name = 'frame_metrics.csv';
M.frame_metrics_mat_name = 'frame_metrics.mat';
end

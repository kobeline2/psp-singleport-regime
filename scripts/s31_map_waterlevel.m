clear; clc;
%% s31_map_waterlevel.m
% Fill the water-level-derived columns of one run's frame_metrics table.
%
% Reads the run's frame_metrics (from s30) and its raw waterlevel.csv,
% aligns the two co-extensive recordings by normalized time, and writes
% back:
%   depth_m       : water depth per PIV frame
%   h_over_a      : depth_m / port height a
%   band_id       : depth band B1..B4 from metadata/depth_bands.csv
%   q_actual_Lps  : actual discharge from A_plan * |dh/dt| (smoothed)
%
% s30 leaves depth_m / h_over_a / band_id as placeholders; this driver is
% the "later stage" that fills them. Run s30 first.
%
% For daily/per-run use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";

% Smoothing window (seconds) for the depth signal before differentiating
% to get actual discharge. The logger is 1 mm-quantized, so this must be
% large enough to average over several quantization steps.
q_smooth_window_s = 20;

% -------------------------------------------------------------------------
% Resolve paths and load inputs
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

metricsDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
frameMetricsMat = fullfile(metricsDir, 'frame_metrics.mat');
frameMetricsCsv = fullfile(metricsDir, 'frame_metrics.csv');
waterlevelPath = char(row.waterlevel_path);

fprintf('[s31_map_waterlevel] run_id     : %s\n', char(runID));
fprintf('[s31_map_waterlevel] metrics    : %s\n', frameMetricsMat);
fprintf('[s31_map_waterlevel] waterlevel : %s\n', waterlevelPath);

assert(isfile(frameMetricsMat) || isfile(frameMetricsCsv), ...
    'frame_metrics not found for %s. Run s30_compute_metrics.m first.', char(runID));
assert(isfile(waterlevelPath), 'waterlevel.csv not found: %s', waterlevelPath);

if isfile(frameMetricsMat)
    S = load(frameMetricsMat, 'frameMetrics', 'opts');
    frameMetrics = S.frameMetrics;
    if isfield(S, 'opts'); opts = S.opts; else; opts = struct(); end
else
    frameMetrics = readtable(frameMetricsCsv, 'TextType', 'string');
    opts = struct();
end

wl = read_waterlevel(waterlevelPath);
bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');

% -------------------------------------------------------------------------
% Map water level onto PIV frames and assign depth bands
% -------------------------------------------------------------------------
a_m = C.port.height_m;

[depth_m, h_over_a, band_id] = assign_depth_bands( ...
    frameMetrics.time_s, wl.depth_m, a_m, bands);

q_actual_Lps = compute_actual_discharge( ...
    frameMetrics.time_s, depth_m, C.basin.Aplan_m2, ...
    'smooth_window_s', q_smooth_window_s);

frameMetrics.depth_m = depth_m;
frameMetrics.h_over_a = h_over_a;
frameMetrics.band_id = band_id;
frameMetrics.q_actual_Lps = q_actual_Lps;

% -------------------------------------------------------------------------
% Save back
% -------------------------------------------------------------------------
opts.waterlevel_source = string(waterlevelPath);
opts.q_smooth_window_s = q_smooth_window_s;
opts.a_m = a_m;

writetable(frameMetrics, frameMetricsCsv);
save(frameMetricsMat, 'frameMetrics', 'opts', '-v7');

fprintf('[s31_map_waterlevel] depth range : %.3f - %.3f m\n', ...
    min(depth_m), max(depth_m));
fprintf('[s31_map_waterlevel] band counts :\n');
for b = 1:height(bands)
    bid = string(bands.band_id(b));
    fprintf('    %s : %d frames\n', bid, nnz(band_id == bid));
end
nUnassigned = nnz(band_id == "");
if nUnassigned > 0
    fprintf('    (unassigned: %d frames outside all bands)\n', nUnassigned);
end
fprintf('[s31_map_waterlevel] median q_actual = %.3f L/s (nominal %.2f)\n', ...
    median(q_actual_Lps, 'omitnan'), row.nominal_Q_Lps);
fprintf('[s31_map_waterlevel] wrote %s\n', frameMetricsCsv);

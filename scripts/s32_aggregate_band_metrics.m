clear; clc;
%% s32_aggregate_band_metrics.m
% Aggregate frame-wise metrics into run x depth-band summaries.
%
% Reads every run's frame_metrics (after s30 + s31) and, for each run and
% each depth band B1..B4, averages the frame-wise metrics over the frames
% that fall in that band. Writes one combined table:
%   local/derived/metrics/band_metrics.csv
%
% One row per run x band (repetitions are kept as separate runs; pool by
% condition later at figure time). Run s30 then s31 first.
%
% For daily use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% Settings
% -------------------------------------------------------------------------
% Metrics averaged per band. Each gets a _mean column; those in
% stdMetrics also get a _std column.
meanMetrics = ["E","phi_lv","I_asym","mean_speed","rms_speed", ...
               "valid_fraction","depth_m","h_over_a","q_actual_Lps"];
stdMetrics  = ["E","phi_lv","I_asym"];

% -------------------------------------------------------------------------
% Resolve runs and bands
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');
outCsv = fullfile(cfg.DERIVED_METRICS_DIR, 'band_metrics.csv');

rows = table();
nRunsUsed = 0;
skipped = strings(0,1);

for i = 1:height(T)
    runID = T.run_id(i);
    metricsMat = fullfile(cfg.DERIVED_METRICS_DIR, char(runID), 'frame_metrics.mat');
    metricsCsv = fullfile(cfg.DERIVED_METRICS_DIR, char(runID), 'frame_metrics.csv');

    if isfile(metricsMat)
        S = load(metricsMat, 'frameMetrics');
        fm = S.frameMetrics;
    elseif isfile(metricsCsv)
        fm = readtable(metricsCsv, 'TextType', 'string');
    else
        continue;   % run not processed yet
    end

    if ~ismember('band_id', fm.Properties.VariableNames) || all(fm.band_id == "")
        skipped(end+1) = runID; %#ok<SAGROW>
        continue;   % s31 not run for this run
    end

    nRunsUsed = nRunsUsed + 1;

    for b = 1:height(bands)
        bid = string(bands.band_id(b));
        inBand = fm.band_id == bid;
        nFrames = nnz(inBand);

        r = table();
        r.run_id = runID;
        r.mode = T.mode(i);
        r.flow_level = T.flow_level(i);
        r.repetition = T.repetition(i);
        r.nominal_Q_Lps = T.nominal_Q_Lps(i);
        r.band_id = bid;
        r.band_label = string(bands.label(b));
        r.h_over_a_mid = 0.5 * (bands.h_over_a_min(b) + bands.h_over_a_max(b));
        r.n_frames = nFrames;

        for m = 1:numel(meanMetrics)
            name = meanMetrics(m);
            colMean = name + "_mean";
            if nFrames > 0 && ismember(name, string(fm.Properties.VariableNames))
                vals = fm.(char(name))(inBand);
                r.(char(colMean)) = mean(vals, 'omitnan');
                if ismember(name, stdMetrics)
                    r.(char(name + "_std")) = std(vals, 0, 'omitnan');
                end
            else
                r.(char(colMean)) = NaN;
                if ismember(name, stdMetrics)
                    r.(char(name + "_std")) = NaN;
                end
            end
        end

        rows = [rows; r]; %#ok<AGROW>
    end
end

assert(height(rows) > 0, ...
    'No runs had band assignments. Run s30 then s31 before s32.');

writetable(rows, outCsv);

fprintf('[s32_aggregate_band_metrics] runs aggregated : %d\n', nRunsUsed);
if ~isempty(skipped)
    fprintf('[s32_aggregate_band_metrics] skipped (no band_id, run s31): %s\n', ...
        strjoin(cellstr(skipped), ', '));
end
fprintf('[s32_aggregate_band_metrics] wrote %s (%d rows)\n', outCsv, height(rows));
disp(rows(1:min(8, height(rows)), :));

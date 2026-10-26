clear; clc;
%% s39_plot_reattachment_vs_depth.m
% Reattachment length R/dB against water depth for several inflow runs, one
% panel per flow level. Runs without a reattachment point are left out.
%
% Needs secondary_metrics.mat of every run in runIDs (written by
% shonai/metrics/secondary/s38_compute_reattachment_divergence.m).
% For daily/per-run use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runIDs = compose("R%04d", 1:12);   % inflow runs to draw
value_column = 'R_over_dB';        % 'R_over_dB' or 'R_m'
min_valid_fraction = 0.30;         % runs below this are treated as "no reattachment"
save_png = true;
show_figure = true;

% -------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
runsTable = read_runs_table(cfg);
tables = cell(numel(runIDs), 1);
flowLevels = strings(numel(runIDs), 1);
for k = 1:numel(runIDs)
    row = runsTable(runsTable.run_id == runIDs(k), :);
    assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runIDs(k)));
    matPath = fullfile(cfg.DERIVED_METRICS_DIR, char(runIDs(k)), 'secondary_metrics.mat');
    assert(isfile(matPath), 'secondary_metrics.mat not found for %s. Run s38 first.', char(runIDs(k)));
    S = load(matPath, 'secondary');
    tables{k} = S.secondary;
    flowLevels(k) = row.flow_level;
end

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
[fig, excludedRunIds] = plot_reattachment_vs_depth(tables, runIDs, flowLevels, ...
    'value_column', value_column, 'min_valid_fraction', min_valid_fraction);
fprintf('[s39] excluded (no reattachment): %s\n', strjoin(excludedRunIds, ', '));

if save_png
    if ~exist(cfg.RESULTS_FIG_DIR, 'dir'), mkdir(cfg.RESULTS_FIG_DIR); end
    pngPath = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_vs_depth_inflow.png', value_column));
    exportgraphics(fig, pngPath, 'Resolution', 150);
    fprintf('[s39] wrote %s\n', pngPath);
end
if ~show_figure
    close(fig);
end

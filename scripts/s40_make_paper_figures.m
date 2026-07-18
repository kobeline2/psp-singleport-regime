clear; clc;
%% s40_make_paper_figures.m
% Generate paper-ready figures from the derived band_metrics summary.
%
% Current output:
%   fig_regime_comparison.png : primary metrics vs relative submergence
%   h/a, inflow vs outflow (pooled over flow levels and repetitions).
%   This single figure addresses the three research questions: mode
%   asymmetry, h/a-controlled transition, and outflow unsteadiness.
%
% Run s30 -> s31 -> s32 first so band_metrics.csv exists.
%
% For daily use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

figureDir = cfg.RESULTS_FIG_DIR;
if ~exist(figureDir, 'dir'); mkdir(figureDir); end

bandMetricsCsv = fullfile(cfg.DERIVED_METRICS_DIR, 'band_metrics.csv');
assert(isfile(bandMetricsCsv), ...
    'band_metrics.csv not found. Run s30 -> s31 -> s32 first.');
BM = readtable(bandMetricsCsv, 'TextType', 'string');

% -------------------------------------------------------------------------
% Panels: {column, label, y-scale}
% -------------------------------------------------------------------------
panels = {
    'E_mean',      'E  (mean sq. speed) [m^2/s^2]',  'log'
    'phi_lv_mean', '\phi_{lv}  (low-speed fraction)', 'linear'
    'I_asym_mean', 'I_{asym}  (left-right asymmetry)', 'linear'
    'I_circ_mean', 'I_{circ}  (circulation index)',   'linear'
    'I_unst',      'I_{unst}  (E unsteadiness, CV)',   'linear'
    'q_actual_Lps_mean', 'Q_{actual} [L/s]',          'linear'
};

modes = ["inflow", "outflow"];
modeColor = containers.Map({'inflow','outflow'}, {[0.85 0.33 0.10], [0.00 0.45 0.74]});
modeMarker = containers.Map({'inflow','outflow'}, {'o', 's'});

fig = figure('Color', 'w', 'Position', [80 80 1200 720]);
tl = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for pIdx = 1:size(panels, 1)
    col = panels{pIdx, 1};
    ylab = panels{pIdx, 2};
    yscale = panels{pIdx, 3};
    ax = nexttile(tl); hold(ax, 'on');

    if ~ismember(col, BM.Properties.VariableNames)
        title(ax, sprintf('%s (missing)', col), 'Interpreter', 'none');
        continue;
    end

    for mi = 1:numel(modes)
        md = modes(mi);
        sub = BM(BM.mode == md, :);
        bands = unique(sub.band_id, 'stable');

        ha = nan(numel(bands),1); mu = nan(numel(bands),1); sd = nan(numel(bands),1);
        for b = 1:numel(bands)
            rb = sub(sub.band_id == bands(b), :);
            ha(b) = mean(rb.h_over_a_mid, 'omitnan');
            mu(b) = mean(rb.(col), 'omitnan');
            sd(b) = std(rb.(col), 0, 'omitnan');
        end
        [ha, ord] = sort(ha); mu = mu(ord); sd = sd(ord);

        errorbar(ax, ha, mu, sd, [modeMarker(char(md)) '-'], ...
            'Color', modeColor(char(md)), 'MarkerFaceColor', modeColor(char(md)), ...
            'LineWidth', 1.4, 'MarkerSize', 6, 'CapSize', 4, 'DisplayName', char(md));
    end

    set(ax, 'YScale', yscale);
    xline(ax, 1.0, ':', 'h/a = 1', 'Color', [0.4 0.4 0.4], ...
        'LabelVerticalAlignment', 'bottom', 'LabelHorizontalAlignment', 'center', ...
        'Interpreter', 'none', 'HandleVisibility', 'off');
    xlabel(ax, 'relative submergence  h/a');
    ylabel(ax, ylab);
    grid(ax, 'on'); box(ax, 'on');
    if pIdx == 1
        legend(ax, 'Location', 'best');
    end
end

title(tl, 'Regime comparison: primary metrics vs relative submergence (mean \pm s.d. over repetitions & flow levels)');

outPng = fullfile(figureDir, 'fig_regime_comparison.png');
exportgraphics(fig, outPng, 'Resolution', 180);
fprintf('[s40_make_paper_figures] wrote %s\n', outPng);

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
% Panels: {column, label, y-scale, apply-SNR-marking}
% E-based scalars (E, I_circ, I_rot, I_unst) get open markers where the
% band-mean E sits below the PIV noise floor criterion (E_resolved false
% for the majority of contributing runs): those points are resolution-
% limited and should be read qualitatively only.
% -------------------------------------------------------------------------
panels = {
    'E_mean',      'E  (mean sq. speed) [m^2/s^2]',    'log',    true
    'phi_lv_mean', '\phi_{lv}  (low-speed fraction)',  'linear', false
    'I_asym_mean', 'I_{asym}  (left-right asymmetry)', 'linear', false
    'I_circ_mean', 'I_{circ}  (signed circulation)',   'linear', true
    'I_rot_mean',  'I_{rot}  (rotation activity)',     'linear', true
    'I_unst',      'I_{unst}  (E unsteadiness, CV)',   'linear', true
    'q_actual_Lps_mean', 'Q_{actual} [L/s]',           'linear', false
};

modes = ["inflow", "outflow"];
modeColor = containers.Map({'inflow','outflow'}, {[0.85 0.33 0.10], [0.00 0.45 0.74]});
modeMarker = containers.Map({'inflow','outflow'}, {'o', 's'});

hasResolved = ismember('E_resolved', BM.Properties.VariableNames);

fig = figure('Color', 'w', 'Position', [60 60 1440 720]);
tl = tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

for pIdx = 1:size(panels, 1)
    col = panels{pIdx, 1};
    ylab = panels{pIdx, 2};
    yscale = panels{pIdx, 3};
    useSnr = panels{pIdx, 4} && hasResolved;
    ax = nexttile(tl); hold(ax, 'on');

    if ~ismember(col, BM.Properties.VariableNames)
        title(ax, sprintf('%s (missing)', col), 'Interpreter', 'none');
        continue;
    end

    for mi = 1:numel(modes)
        md = modes(mi);
        sub = BM(BM.mode == md, :);
        bands = unique(sub.band_id, 'stable');

        nB = numel(bands);
        ha = nan(nB,1); mu = nan(nB,1); sd = nan(nB,1); res = true(nB,1);
        for b = 1:nB
            rb = sub(sub.band_id == bands(b), :);
            ha(b) = mean(rb.h_over_a_mid, 'omitnan');
            mu(b) = mean(rb.(col), 'omitnan');
            sd(b) = std(rb.(col), 0, 'omitnan');
            if useSnr
                res(b) = mean(double(rb.E_resolved), 'omitnan') >= 0.5;
            end
        end
        [ha, ord] = sort(ha); mu = mu(ord); sd = sd(ord); res = res(ord);

        cc = modeColor(char(md));
        mk = modeMarker(char(md));

        % Connecting line + error bars (no markers), then markers split by
        % SNR: filled = resolved, open = resolution-limited.
        errorbar(ax, ha, mu, sd, '-', ...
            'Color', cc, 'LineWidth', 1.4, 'CapSize', 4, 'DisplayName', char(md));
        plot(ax, ha(res), mu(res), mk, 'Color', cc, ...
            'MarkerFaceColor', cc, 'MarkerSize', 6, 'HandleVisibility', 'off');
        plot(ax, ha(~res), mu(~res), mk, 'Color', cc, ...
            'MarkerFaceColor', 'w', 'MarkerSize', 6, 'HandleVisibility', 'off');
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

% Legend note in the unused 8th tile.
axNote = nexttile(tl); axis(axNote, 'off');
text(axNote, 0.02, 0.85, { ...
    'Markers:', ...
    '  filled = band-mean E above the PIV', ...
    '           noise-floor criterion (resolved)', ...
    '  open   = resolution-limited (E-based', ...
    '           scalars qualitative only)', ...
    '', ...
    '\phi_{lv}: u_{th} = 0.2 U_p (relative threshold);', ...
    'outflow saturates at 1 = surface everywhere', ...
    'slower than 0.2 U_p (reported as a finding).'}, ...
    'FontSize', 9, 'VerticalAlignment', 'top');

title(tl, 'Regime comparison: primary metrics vs relative submergence (mean \pm s.d. over repetitions & flow levels)');

outPng = fullfile(figureDir, 'fig_regime_comparison.png');
exportgraphics(fig, outPng, 'Resolution', 180);
fprintf('[s40_make_paper_figures] wrote %s\n', outPng);

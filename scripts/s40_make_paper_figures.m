clear; clc;
%% s40_make_paper_figures.m
% Generate paper-ready figures from the derived metrics.
%
% Current output:
%   fig_regime_comparison.png : primary metrics vs relative submergence
%   h/a, inflow vs outflow (pooled over flow levels and repetitions).
%   This single figure addresses the three research questions: mode
%   asymmetry, h/a-controlled transition, and outflow unsteadiness.
%
%   fig_branch_selection.png : which circulation branch each inflow run
%   settles on, and how firmly. Signed I_circ must be kept per run here --
%   pooling it across repetitions that sit on opposite branches cancels to
%   zero (doc/metrics_primer.md 1b).
%
%   branch_stats.csv : the per-run branch table behind that figure.
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

% These are the experiment paper's figures. band_metrics.csv also carries
% CFD validation runs (piv_source = "cfd") under mode = "inflow", so they
% would silently join the experimental pool if not removed here.
RUNS = read_runs_table(cfg);
expRunIds = string(RUNS.run_id(string(RUNS.piv_source) ~= "cfd"));
nBefore = height(BM);
BM = BM(ismember(BM.run_id, expRunIds), :);
fprintf('[s40_make_paper_figures] experiment-only rows: %d of %d\n', height(BM), nBefore);

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

% =========================================================================
% Figure 2: branch selection by flow rate (inflow)
%
% The inflow jet attaches to one sidewall and locks the basin circulation
% onto one branch. Sign convention: I_circ > 0 is counterclockwise in the
% (x right, y up) analysis frame of the band-mean field figures, i.e. the
% jet attached to the y < y_port sidewall.
% =========================================================================
BS = compute_branch_statistics(cfg);
BS = BS(BS.mode == "inflow" & ismember(BS.run_id, expRunIds), :);

branchCsv = fullfile(cfg.DERIVED_METRICS_DIR, 'branch_stats.csv');
writetable(BS, branchCsv);
fprintf('[s40_make_paper_figures] wrote %s\n', branchCsv);

levels = ["low" "medium" "high"];
% One encoding throughout: colour = branch (sign of I_circ), marker = flow
% level. Colour is never used for the level, so a red low-flow run and a
% blue high-flow run read as opposite branches at a glance.
levelMarker = containers.Map({'low','medium','high'}, {'o', 's', '^'});
posColor = [0.80 0.28 0.16];   % counterclockwise branch
negColor = [0.10 0.35 0.65];   % clockwise branch
iBranchColor = @(s) posColor * (s > 0) + negColor * (s <= 0);

fig2 = figure('Color', 'w', 'Position', [60 60 1400 430]);
tl2 = tiledlayout(fig2, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- (a) signed I_circ against h/a, one line per run ---------------------
axA = nexttile(tl2); hold(axA, 'on');
yline(axA, 0, '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');
inflowBM = BM(BM.mode == "inflow", :);
for li = 1:numel(levels)
    lv = levels(li);
    mk = levelMarker(char(lv));
    runsHere = unique(inflowBM.run_id(inflowBM.flow_level == lv), 'stable');
    for ri = 1:numel(runsHere)
        rb = sortrows(inflowBM(inflowBM.run_id == runsHere(ri), :), 'h_over_a_mid');
        bs = BS.branch_sign(BS.run_id == runsHere(ri));
        cc = iBranchColor(bs);
        plot(axA, rb.h_over_a_mid, rb.I_circ_mean, '-', 'Marker', mk, ...
            'Color', cc, 'MarkerFaceColor', cc, 'MarkerSize', 5, ...
            'LineWidth', 1.3, 'HandleVisibility', 'off');
        if runsHere(ri) == "R0008"
            text(axA, rb.h_over_a_mid(end) + 0.03, rb.I_circ_mean(end), 'R0008', ...
                'FontSize', 9, 'Color', posColor, 'FontWeight', 'bold');
        end
    end
    % Legend proxy: marker shape only, drawn in neutral grey.
    plot(axA, NaN, NaN, mk, 'Color', [0.4 0.4 0.4], ...
        'MarkerFaceColor', [0.4 0.4 0.4], 'MarkerSize', 5, 'DisplayName', char(lv));
end
xline(axA, 1.0, ':', 'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
xlabel(axA, 'relative submergence  h/a');
ylabel(axA, 'I_{circ}  (signed circulation)');
title(axA, '(a) branch of each inflow run');
legend(axA, 'Location', 'southwest');
grid(axA, 'on'); box(axA, 'on');
xlim(axA, [0.6 1.75]);

% --- (b) day x flow level sign matrix ------------------------------------
axB = nexttile(tl2); hold(axB, 'on');
days = unique(BS.date, 'stable');
for k = 1:height(BS)
    ix = find(levels == BS.flow_level(k));
    iy = find(days == BS.date(k));
    cc = iBranchColor(BS.branch_sign(k));
    plot(axB, ix, iy, levelMarker(char(BS.flow_level(k))), 'MarkerSize', 26, ...
        'MarkerFaceColor', cc, 'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
    text(axB, ix, iy, sprintf('%.1f', BS.R_lock(k)), 'Color', 'w', ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end
set(axB, 'XTick', 1:numel(levels), 'XTickLabel', cellstr(levels), ...
    'YTick', 1:numel(days), 'YTickLabel', cellstr(days), ...
    'YDir', 'reverse');
xlim(axB, [0.4 numel(levels)+0.6]); ylim(axB, [0.4 numel(days)+0.6]);
xlabel(axB, 'flow-rate level');
ylabel(axB, 'experiment day');
title(axB, '(b) branch sign per day (labels: R_{lock})');
% Legend proxies for the two branches.
plot(axB, NaN, NaN, 'o', 'MarkerSize', 8, 'MarkerFaceColor', posColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'I_{circ} > 0 (CCW)');
plot(axB, NaN, NaN, 'o', 'MarkerSize', 8, 'MarkerFaceColor', negColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'I_{circ} < 0 (CW)');
legend(axB, 'Location', 'eastoutside');
box(axB, 'on');

% --- (c) lock strength against actual discharge --------------------------
axC = nexttile(tl2); hold(axC, 'on');
for k = 1:height(BS)
    cc = iBranchColor(BS.branch_sign(k));
    plot(axC, BS.Q_transit_Lps(k), BS.R_lock(k), levelMarker(char(BS.flow_level(k))), ...
        'MarkerSize', 8, 'MarkerFaceColor', cc, 'MarkerEdgeColor', 'none', ...
        'HandleVisibility', 'off');
end
for lbl = ["R0007" "R0008" "R0002"]
    r = BS(BS.run_id == lbl, :);
    if isempty(r); continue; end
    text(axC, r.Q_transit_Lps + 0.012, r.R_lock, char(lbl), 'FontSize', 9);
end
xlabel(axC, 'transit-time discharge over B_3+B_4  [L/s]');
ylabel(axC, 'R_{lock} = |mean I_{circ}| / s.d.');
title(axC, '(c) lock strength vs discharge');
grid(axC, 'on'); box(axC, 'on');
xlim(axC, [0.22 0.90]);

title(tl2, 'Flow rate selects the circulation branch (inflow, deep bands B_3+B_4)');

outPng2 = fullfile(figureDir, 'fig_branch_selection.png');
exportgraphics(fig2, outPng2, 'Resolution', 180);
fprintf('[s40_make_paper_figures] wrote %s\n', outPng2);

function fig = plot_frame_metrics_overview(frameMetrics, varargin)
%PLOT_FRAME_METRICS_OVERVIEW Quick-look figure for one run of frame metrics.
%
% Usage:
%   fig = plot_frame_metrics_overview(frameMetrics)
%   fig = plot_frame_metrics_overview(frameMetrics, 'smooth_span_frames', 31)
%
% The goal is fast inspection, not paper-ready styling.
%
% Layout is data-driven: the panels to draw are defined as a list (see
% iDefaultPanelSpec). The tiled-layout grid auto-sizes from the number of
% panels, so adding a metric is one extra entry in the spec list. Panels
% whose source columns are absent from frameMetrics are skipped, so this
% function also works with older metric tables.
%
% Currently included panels (when present):
%   E, phi_lv, I_asym, I_circ, speed level, coverage/flags, run summary

    p = inputParser;
    p.addRequired('frameMetrics', @istable);
    p.addParameter('smooth_span_frames', 31, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('ncols', 2, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('figure_position', [], ...
        @(x) isempty(x) || (isnumeric(x) && numel(x) == 4));
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.addParameter('show_summary', true, @(x) islogical(x) || isnumeric(x));
    p.parse(frameMetrics, varargin{:});
    prm = p.Results;

    assert(ismember('frame_idx', frameMetrics.Properties.VariableNames), ...
        'plot_frame_metrics_overview:MissingFrameIdx', ...
        'frameMetrics must contain a frame_idx column.');

    T = sortrows(frameMetrics, 'frame_idx');
    runID = iFirstString(T, 'run_id', "");
    variant = iFirstString(T, 'variant', "");
    source = iFirstString(T, 'source', "");
    threshold = iFirstNumeric(T, 'low_speed_threshold_m_s', NaN);

    [t, xLabel] = iResolveTimeAxis(T);
    span = max(1, round(prm.smooth_span_frames));
    ncols = max(1, round(prm.ncols));

    % ---------------------------------------------------------------------
    % Build the panel list (data-driven). Adding a metric = one entry here.
    % ---------------------------------------------------------------------
    spec = iDefaultPanelSpec(T, threshold);
    nPanels = numel(spec);
    showSummary = logical(prm.show_summary);
    nTiles = nPanels + double(showSummary);
    nRows = max(1, ceil(nTiles / ncols));

    if isempty(prm.figure_position)
        figPos = [100, 100, 590 * ncols, 120 + 210 * nRows];
    else
        figPos = prm.figure_position;
    end

    % ---------------------------------------------------------------------
    % Figure / layout
    % ---------------------------------------------------------------------
    fig = figure('Color', 'w', 'Position', figPos);
    tl = tiledlayout(fig, nRows, ncols, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, iBuildTitle(runID, source, variant, prm.title_suffix), 'Interpreter', 'none');

    for k = 1:nPanels
        iDrawPanel(nexttile(tl), t, xLabel, T, spec(k), span);
    end

    if showSummary
        axS = nexttile(tl);
        axis(axS, 'off');
        iAddSummaryText(axS, T, runID, source, variant, threshold, t, xLabel);
    end
end

% =========================================================================
% Panel specification
% =========================================================================

function spec = iDefaultPanelSpec(T, threshold)
% Returns a struct array of panels. Each panel that references missing
% columns is dropped automatically by iAddPanel.
    spec = struct('title', {}, 'ylabel', {}, 'series', {}, ...
                  'ylim', {}, 'zeroline', {}, 'showlegend', {});

    spec = iAddPanel(spec, T, 'E(t)', 'Mean squared speed [m^2/s^2]', ...
        iSeries('E', [0.10 0.35 0.75], 'E'), [], false);

    phiLabel = '\phi_{lv}(t)';
    if isfinite(threshold)
        phiLabel = sprintf('\\phi_{lv}(t), u < %.3g m/s', threshold);
    end
    spec = iAddPanel(spec, T, phiLabel, 'Low-speed area fraction [-]', ...
        iSeries('phi_lv', [0.75 0.25 0.15], '\phi_{lv}'), [0 1], false);

    spec = iAddPanel(spec, T, 'I_{asym}(t)', 'Left-right asymmetry [-]', ...
        iSeries('I_asym', [0.55 0.10 0.55], 'I_{asym}'), [0 1], false);

    % I_circ is signed; add a zero reference line and leave ylim free.
    spec = iAddPanel(spec, T, 'I_{circ}(t)', 'Circulation index [-]', ...
        iSeries('I_circ', [0.00 0.50 0.50], 'I_{circ}'), [], true);

    % D_rms >= 0: structure strength of the surface-divergence field.
    spec = iAddPanel(spec, T, 'D_{rms}(t)', 'Surface divergence RMS [1/s]', ...
        iSeries('div_rms', [0.85 0.33 0.10], 'D_{rms}'), [], false);

    spec = iAddPanel(spec, T, 'Speed level', 'Speed [m/s]', ...
        [iSeries('mean_speed', [0.10 0.60 0.30], 'Mean speed'), ...
         iSeries('rms_speed',  [0.20 0.20 0.20], 'RMS speed')], [], false);

    spec = iAddPanel(spec, T, 'Coverage / flags', 'Fraction [-]', ...
        [iSeries('valid_fraction', [0.00 0.45 0.74], 'Valid fraction'), ...
         iSeries('typevector_nonzero_fraction', [0.80 0.40 0.00], 'Typevector nonzero')], ...
        [0 1], false);
end

function s = iSeries(col, color, name)
    s = struct('col', string(col), 'color', color, 'name', string(name));
end

function spec = iAddPanel(spec, T, titleStr, ylab, series, ylimVal, zeroline)
% Keep only series whose columns exist; drop the panel if none remain.
    vars = string(T.Properties.VariableNames);
    keep = arrayfun(@(s) ismember(s.col, vars), series);
    series = series(keep);
    if isempty(series)
        return;
    end
    % Wrap series in a cell so struct() stores the whole struct array in one
    % field instead of expanding it into a struct array of panels.
    spec(end + 1) = struct( ...
        'title', titleStr, ...
        'ylabel', ylab, ...
        'series', {series}, ...
        'ylim', ylimVal, ...
        'zeroline', zeroline, ...
        'showlegend', numel(series) > 1);
end

% =========================================================================
% Drawing
% =========================================================================

function iDrawPanel(ax, t, xLabel, T, panel, span)
    hold(ax, 'on');
    if panel.zeroline
        yline(ax, 0, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
    for j = 1:numel(panel.series)
        s = panel.series(j);
        iPlotRawAndSmooth(ax, t, T.(char(s.col)), span, s.color, s.name);
    end
    xlabel(ax, xLabel);
    ylabel(ax, panel.ylabel);
    title(ax, panel.title, 'Interpreter', 'tex');
    grid(ax, 'on');
    if ~isempty(panel.ylim)
        ylim(ax, panel.ylim);
    end
    if panel.showlegend
        legend(ax, 'Location', 'best');
    end
end

function iPlotRawAndSmooth(ax, t, y, span, color, displayName)
    y = double(y);
    plot(ax, t, y, '-', 'Color', iLightenColor(color, 0.70), 'LineWidth', 0.6, ...
        'HandleVisibility', 'off');

    ySmooth = smoothdata(y, 'movmean', span, 'omitnan');
    plot(ax, t, ySmooth, '-', 'Color', color, 'LineWidth', 1.6, ...
        'DisplayName', displayName);
end

% =========================================================================
% Summary panel
% =========================================================================

function iAddSummaryText(ax, T, runID, source, variant, threshold, t, xLabel)
    nFrames = height(T);
    durationText = iFormatDuration(t, xLabel);

    lines = [ ...
        "Run summary"; ...
        sprintf('run_id: %s', runID); ...
        sprintf('source: %s', source); ...
        sprintf('variant: %s', variant); ...
        sprintf('frames: %d', nFrames); ...
        sprintf('duration: %s', durationText)];
    if isfinite(threshold)
        lines(end + 1) = sprintf('phi_lv threshold: %.4g m/s', threshold);
    end
    lines(end + 1) = " ";

    % Report the mean of any present scalar metric, in a fixed order.
    summaryCols = ["E", "phi_lv", "I_asym", "I_circ", "div_rms", ...
                   "valid_fraction", "mean_speed", "rms_speed"];
    for c = summaryCols
        if ismember(c, string(T.Properties.VariableNames))
            lines(end + 1) = sprintf('mean(%s): %.4g', c, mean(T.(char(c)), 'omitnan')); %#ok<AGROW>
        end
    end

    text(ax, 0.02, 0.98, strjoin(cellstr(lines), '\n'), ...
        'Units', 'normalized', ...
        'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'Helvetica', ...
        'FontSize', 11, ...
        'Interpreter', 'none');
end

% =========================================================================
% Small helpers
% =========================================================================

function titleStr = iBuildTitle(runID, source, variant, suffix)
    parts = strings(0, 1);
    if strlength(runID) > 0,           parts(end + 1) = runID;          end
    if strlength(source) > 0,          parts(end + 1) = source;         end
    if strlength(variant) > 0,         parts(end + 1) = variant;        end
    if strlength(string(suffix)) > 0,  parts(end + 1) = string(suffix); end
    titleStr = strjoin(parts, ' | ');
end

function [t, label] = iResolveTimeAxis(T)
    t = double(T.frame_idx);
    label = 'Frame index';
    if ismember('time_s', T.Properties.VariableNames)
        tCandidate = double(T.time_s);
        if any(isfinite(tCandidate))
            t = tCandidate;
            label = 'Time [s]';
        end
    end

    if max(t, [], 'omitnan') >= 180
        t = t / 60;
        label = 'Time [min]';
    end
end

function value = iFirstString(T, varName, defaultValue)
    value = string(defaultValue);
    if ~ismember(varName, T.Properties.VariableNames) || isempty(T)
        return;
    end

    candidate = string(T.(varName)(1));
    if ~ismissing(candidate)
        value = candidate;
    end
end

function value = iFirstNumeric(T, varName, defaultValue)
    value = defaultValue;
    if ~ismember(varName, T.Properties.VariableNames) || isempty(T)
        return;
    end

    candidate = T.(varName)(1);
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = double(candidate);
    end
end

function txt = iFormatDuration(t, xLabel)
    tMax = max(t, [], 'omitnan');
    if ~isfinite(tMax)
        txt = 'unknown';
        return;
    end

    if strcmp(xLabel, 'Time [min]')
        txt = sprintf('%.2f min', tMax);
    else
        txt = sprintf('%.1f s', tMax);
    end
end

function c = iLightenColor(color, amount)
    amount = max(0, min(1, amount));
    c = color + amount * (1 - color);
end

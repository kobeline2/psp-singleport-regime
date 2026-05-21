function fig = plot_frame_metrics_overview(frameMetrics, varargin)
%PLOT_FRAME_METRICS_OVERVIEW Quick-look figure for one run of frame metrics.
%
% Usage:
%   fig = plot_frame_metrics_overview(frameMetrics)
%   fig = plot_frame_metrics_overview(frameMetrics, 'smooth_span_frames', 31)
%
% The goal is fast inspection, not paper-ready styling. The figure focuses
% on the current minimal metrics computed in s30:
%   E, phi_lv, I_asym, mean_speed, rms_speed, valid_fraction

    p = inputParser;
    p.addRequired('frameMetrics', @istable);
    p.addParameter('smooth_span_frames', 31, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('figure_position', [100 100 1180 760], ...
        @(x) isnumeric(x) && numel(x) == 4);
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.parse(frameMetrics, varargin{:});
    prm = p.Results;

    requiredVars = ["frame_idx", "time_s", "valid_fraction", ...
        "mean_speed", "rms_speed", "E", "phi_lv", "I_asym"];
    missing = requiredVars(~ismember(requiredVars, string(frameMetrics.Properties.VariableNames)));
    assert(isempty(missing), ...
        'plot_frame_metrics_overview:MissingColumns', ...
        'frameMetrics is missing required columns: %s', strjoin(cellstr(missing), ', '));

    T = sortrows(frameMetrics, 'frame_idx');
    runID = iFirstString(T, 'run_id', "");
    variant = iFirstString(T, 'variant', "");
    source = iFirstString(T, 'source', "");
    threshold = iFirstNumeric(T, 'low_speed_threshold_m_s', NaN);

    [t, xLabel] = iResolveTimeAxis(T);
    span = max(1, round(prm.smooth_span_frames));

    fig = figure('Color', 'w', 'Position', prm.figure_position);
    tl = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    titleParts = strings(0, 1);
    if strlength(runID) > 0
        titleParts(end + 1) = runID; %#ok<AGROW>
    end
    if strlength(source) > 0
        titleParts(end + 1) = source; %#ok<AGROW>
    end
    if strlength(variant) > 0
        titleParts(end + 1) = variant; %#ok<AGROW>
    end
    if strlength(string(prm.title_suffix)) > 0
        titleParts(end + 1) = string(prm.title_suffix); %#ok<AGROW>
    end
    title(tl, strjoin(titleParts, ' | '), 'Interpreter', 'none');

    iPlotMetric(nexttile(tl, 1), t, xLabel, T.E, span, ...
        'E(t)', 'Mean squared speed [m^2/s^2]', [0.10 0.35 0.75]);

    phiLabel = '\phi_{lv}(t)';
    if isfinite(threshold)
        phiLabel = sprintf('\\phi_{lv}(t), u < %.3g m/s', threshold);
    end
    iPlotMetric(nexttile(tl, 2), t, xLabel, T.phi_lv, span, ...
        phiLabel, 'Low-speed area fraction [-]', [0.75 0.25 0.15], ...
        'ylim', [0 1]);

    ax3 = nexttile(tl, 3);
    hold(ax3, 'on');
    iPlotRawAndSmooth(ax3, t, T.mean_speed, span, [0.10 0.60 0.30], 'Mean speed');
    iPlotRawAndSmooth(ax3, t, T.rms_speed, span, [0.20 0.20 0.20], 'RMS speed');
    ylabel(ax3, 'Speed [m/s]');
    xlabel(ax3, xLabel);
    title(ax3, 'Speed level');
    grid(ax3, 'on');
    legend(ax3, 'Location', 'best');

    iPlotMetric(nexttile(tl, 4), t, xLabel, T.I_asym, span, ...
        'I_{asym}(t)', 'Left-right asymmetry [-]', [0.55 0.10 0.55], ...
        'ylim', [0 1]);

    ax5 = nexttile(tl, 5);
    hold(ax5, 'on');
    iPlotRawAndSmooth(ax5, t, T.valid_fraction, span, [0.00 0.45 0.74], 'Valid fraction');
    if ismember('typevector_nonzero_fraction', T.Properties.VariableNames)
        iPlotRawAndSmooth(ax5, t, T.typevector_nonzero_fraction, span, [0.80 0.40 0.00], ...
            'Typevector nonzero fraction');
    end
    ylabel(ax5, 'Fraction [-]');
    xlabel(ax5, xLabel);
    title(ax5, 'Coverage / flags');
    ylim(ax5, [0 1]);
    grid(ax5, 'on');
    legend(ax5, 'Location', 'best');

    ax6 = nexttile(tl, 6);
    axis(ax6, 'off');
    iAddSummaryText(ax6, T, runID, source, variant, threshold, t, xLabel);
end

function iPlotMetric(ax, t, xLabel, y, span, titleStr, yLabel, color, varargin)
    hold(ax, 'on');
    iPlotRawAndSmooth(ax, t, y, span, color, 'Raw / smooth');
    xlabel(ax, xLabel);
    ylabel(ax, yLabel);
    title(ax, titleStr, 'Interpreter', 'tex');
    grid(ax, 'on');

    if ~isempty(varargin)
        for k = 1:2:numel(varargin)
            set(ax, varargin{k}, varargin{k + 1});
        end
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

function iAddSummaryText(ax, T, runID, source, variant, threshold, t, xLabel)
    nFrames = height(T);
    durationText = iFormatDuration(t, xLabel);

    lines = strings(0, 1);
    lines(end + 1) = "Run summary"; %#ok<AGROW>
    lines(end + 1) = sprintf('run_id: %s', runID); %#ok<AGROW>
    lines(end + 1) = sprintf('source: %s', source); %#ok<AGROW>
    lines(end + 1) = sprintf('variant: %s', variant); %#ok<AGROW>
    lines(end + 1) = sprintf('frames: %d', nFrames); %#ok<AGROW>
    lines(end + 1) = sprintf('duration: %s', durationText); %#ok<AGROW>
    if isfinite(threshold)
        lines(end + 1) = sprintf('phi_lv threshold: %.4g m/s', threshold); %#ok<AGROW>
    end
    lines(end + 1) = " "; %#ok<AGROW>
    lines(end + 1) = sprintf('mean(E): %.4g', mean(T.E, 'omitnan')); %#ok<AGROW>
    lines(end + 1) = sprintf('mean(phi_lv): %.4g', mean(T.phi_lv, 'omitnan')); %#ok<AGROW>
    lines(end + 1) = sprintf('mean(I_asym): %.4g', mean(T.I_asym, 'omitnan')); %#ok<AGROW>
    lines(end + 1) = sprintf('mean(valid_fraction): %.4g', mean(T.valid_fraction, 'omitnan')); %#ok<AGROW>
    lines(end + 1) = sprintf('mean(mean_speed): %.4g m/s', mean(T.mean_speed, 'omitnan')); %#ok<AGROW>
    lines(end + 1) = sprintf('mean(rms_speed): %.4g m/s', mean(T.rms_speed, 'omitnan')); %#ok<AGROW>

    text(ax, 0.02, 0.98, strjoin(cellstr(lines), '\n'), ...
        'Units', 'normalized', ...
        'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'Helvetica', ...
        'FontSize', 11, ...
        'Interpreter', 'none');
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

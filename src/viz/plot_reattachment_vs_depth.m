function [fig, excludedRunIds] = plot_reattachment_vs_depth(secondaryTables, runIds, flowLevels, varargin)
%PLOT_REATTACHMENT_VS_DEPTH Reattachment length against water depth, per flow level.
%
% Usage:
%   [fig, excluded] = plot_reattachment_vs_depth(tables, runIds, flowLevels)
%   fig = plot_reattachment_vs_depth(..., 'value_column', 'R_m')
%
% Inputs:
%   secondaryTables  cell array, one table per run: the "secondary" table
%                    written by s38 (columns depth_m, R_m, R_over_dB).
%   runIds           string array, same order as secondaryTables.
%   flowLevels       string array ("low" / "medium" / "high"), same order.
%
% One panel per flow level, one color per run. Runs in which a
% reattachment point exists in fewer than 'min_valid_fraction' of the frames
% (symmetric-type flow) are left out and returned in excludedRunIds.
% Frames without a reattachment point (NaN) are not drawn.
%
% Parameters:
%   value_column        'R_over_dB' (default) or 'R_m'.
%   min_valid_fraction  Default 0.30.
%   depth_lim_m         Default [0.03 0.10].
%   y_lim               Default [0 2.6] for R/dB, [] (auto) for R_m.
%   title_suffix        Appended to the figure title.

    p = inputParser;
    p.addRequired('secondaryTables', @iscell);
    p.addRequired('runIds', @(x) isstring(x) || iscellstr(x));
    p.addRequired('flowLevels', @(x) isstring(x) || iscellstr(x));
    p.addParameter('value_column', 'R_over_dB', @(x) ischar(x) || isstring(x));
    p.addParameter('min_valid_fraction', 0.30, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('depth_lim_m', [0.03 0.10], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('y_lim', [], @(x) isnumeric(x) && (isempty(x) || numel(x) == 2));
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.parse(secondaryTables, runIds, flowLevels, varargin{:});
    prm = p.Results;

    runIds = string(runIds(:));
    flowLevels = lower(string(flowLevels(:)));
    valueColumn = char(prm.value_column);
    assert(numel(secondaryTables) == numel(runIds) && numel(runIds) == numel(flowLevels), ...
        'plot_reattachment_vs_depth:SizeMismatch', ...
        'secondaryTables, runIds and flowLevels must have the same length.');

    yLim = prm.y_lim;
    if isempty(yLim) && strcmp(valueColumn, 'R_over_dB')
        yLim = [0 2.6];
    end
    if strcmp(valueColumn, 'R_over_dB')
        yLabel = 'R / \DeltaB';
    else
        yLabel = 'R [m]';
    end

    levels = ["low", "medium", "high"];
    fig = figure('Color', 'w', 'Position', [100 100 1500 480]);
    tl = tiledlayout(fig, 1, numel(levels), 'TileSpacing', 'compact');
    colors = lines(8);
    excludedRunIds = strings(0, 1);

    for iLevel = 1:numel(levels)
        ax = nexttile(tl);
        hold(ax, 'on');
        nDrawn = 0;
        for k = find(flowLevels == levels(iLevel)).'
            T = secondaryTables{k};
            if mean(isfinite(T.R_m)) < prm.min_valid_fraction
                excludedRunIds(end + 1, 1) = runIds(k); %#ok<AGROW>
                continue;
            end
            nDrawn = nDrawn + 1;
            plot(ax, T.depth_m, T.(valueColumn), '.', 'MarkerSize', 3, ...
                'Color', colors(mod(nDrawn - 1, size(colors, 1)) + 1, :), ...
                'DisplayName', char(runIds(k)));
        end
        grid(ax, 'on');
        xlim(ax, prm.depth_lim_m);
        if ~isempty(yLim), ylim(ax, yLim); end
        xlabel(ax, 'depth h [m]');
        if iLevel == 1, ylabel(ax, yLabel); end
        title(ax, sprintf('%s flow', levels(iLevel)));
        if nDrawn > 0, legend(ax, 'Location', 'northeast'); end
    end

    ttl = sprintf('Reattachment length vs depth (runs with reattachment in >= %d%% of frames)', ...
        round(100 * prm.min_valid_fraction));
    if strlength(string(prm.title_suffix)) > 0
        ttl = sprintf('%s  %s', ttl, char(string(prm.title_suffix)));
    end
    title(tl, ttl);
end

function fig = plot_band_mean_fields(fields, varargin)
%PLOT_BAND_MEAN_FIELDS Panel figure of per-band time-mean vector fields.
%
% fig = plot_band_mean_fields(fields, 'Lx_m', 3.0, 'Ly_m', 2.0, ...)
%
% One panel per depth band (from compute_band_mean_field). Each panel shows
% the time-mean speed as a color background with the mean velocity vectors
% quivered on top. Vectors are auto-scaled per panel so that the flow
% direction structure is visible even where the mean speed is weak (e.g.
% outflow), while the color background still conveys the absolute magnitude.
%
% Name-value pairs:
%   'Lx_m','Ly_m'   basin dimensions for the axes (default 3.0, 2.0)
%   'quiver_step'   vector downsample stride (default 3)
%   'title_prefix'  string prepended to the figure super-title
%   'colormap_name' default 'turbo'

    p = inputParser;
    p.addRequired('fields', @isstruct);
    p.addParameter('Lx_m', 3.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('Ly_m', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('quiver_step', 3, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('title_prefix', "", @(x) ischar(x) || isstring(x));
    p.addParameter('colormap_name', 'turbo', @(x) ischar(x) || isstring(x));
    p.parse(fields, varargin{:});
    prm = p.Results;

    nB = numel(fields);
    fig = figure('Color', 'w', 'Position', [60 60 340 * nB 380], 'Visible', 'on');
    tl = tiledlayout(fig, 1, nB, 'TileSpacing', 'compact', 'Padding', 'compact');

    qs = prm.quiver_step;

    for b = 1:nB
        f = fields(b);
        ax = nexttile(tl); hold(ax, 'on');
        axis(ax, 'equal');
        axis(ax, [0 prm.Lx_m 0 prm.Ly_m]);
        set(ax, 'YDir', 'normal'); box(ax, 'on');

        if isempty(f.Ubar) || all(~isfinite(f.speed(:)))
            title(ax, sprintf('%s (no data)', f.band_id), 'Interpreter', 'none');
            continue;
        end

        X = f.x; Y = f.y;
        imagesc(ax, X(1, :), Y(:, 1), f.speed);
        smax = prctile(f.speed(isfinite(f.speed)), 99);
        if ~(smax > 0), smax = 1; end
        caxis(ax, [0 smax]);
        colormap(ax, char(prm.colormap_name));
        cb = colorbar(ax); cb.Label.String = 'mean speed [m/s]';

        jj = 1:qs:size(X, 1);
        ii = 1:qs:size(X, 2);
        Uq = f.Ubar(jj, ii); Vq = f.Vbar(jj, ii);
        % Auto-scale (2nd arg) so weak fields still show direction structure.
        quiver(ax, X(jj, ii), Y(jj, ii), Uq, Vq, 2.0, 'k', 'LineWidth', 0.5);

        xlabel(ax, 'x [m]'); ylabel(ax, 'y [m]');
        title(ax, sprintf('%s  (n=%d)', f.band_id, f.n_frames), 'Interpreter', 'none');
    end

    if strlength(string(prm.title_prefix)) > 0
        title(tl, char(prm.title_prefix), 'Interpreter', 'none');
    end
end

function [fig, stats] = plot_divergence_sign_map(piv, secondary, bands, varargin)
%PLOT_DIVERGENCE_SIGN_MAP Up/down-welling map of one run, one panel per depth band.
%
% Usage:
%   [fig, stats] = plot_divergence_sign_map(piv, secondary, bands)
%   fig = plot_divergence_sign_map(piv, secondary, bands, 'd_noise_1_s', 5e-3)
%
% Inputs:
%   piv        canonical piv struct (numeric u, v, typevector stacks).
%   secondary  table written by s38; provides depth_m and D_ref_1_s per frame
%              (D_ref = -(1/h) dh/dt, see compute_divergence_sign).
%   bands      depth-band table (metadata/depth_bands.csv): band_id, h_min_m,
%              h_max_m.
%
% For each band the anomaly D' = D - D_ref of every frame in the band is
% averaged in time and drawn on the basin plan view:
%   red  : D' > 0, upwelling   (surface divergence above the uniform rise)
%   blue : D' < 0, downwelling
%   A gray outline encloses cells with |D'| < d_noise_1_s: the sign of the
%   time-mean is not resolvable there.
%   Arrows: time-mean surface velocity in the same band.
% Masks (white): PIVLab-interpolated vectors (excluded before smoothing),
% edge_margin_cells along the grid border and a disc around the port mouth,
% as in compute_divergence_sign.
%
% Output stats (struct array, one per band): band_id, n_frames, f_up,
% f_down, f_undet (area fractions over the unmasked cells).
%
% Parameters:
%   d_noise_1_s         Sign threshold [1/s]. Default 5e-3 (provisional).
%   smooth_sigma        Gaussian sigma [cells]. Default 1.5.
%   edge_margin_cells   Default 4.
%   port_mask_radius_m  Default 0.25.
%   port_wall_x_m       Default 0.
%   port_center_y_m     Default NaN (= middle of the piv.y range).
%   port_width_m        Only for the port marker. Default 0.11.
%   basin_size_m        [Lx Ly] axis limits. Default [2.952 1.962].
%   color_limit_1_s     Symmetric color limit. Default 0.03.
%   quiver_step         Arrow every N cells. Default 3.
%   title_suffix        Appended to the figure title.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addRequired('secondary', @istable);
    p.addRequired('bands', @istable);
    p.addParameter('d_noise_1_s', 5e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('smooth_sigma', 1.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('edge_margin_cells', 4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_mask_radius_m', 0.25, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_wall_x_m', 0, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_center_y_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_width_m', 0.11, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('basin_size_m', [2.952 1.962], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('color_limit_1_s', 0.03, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('quiver_step', 3, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.parse(piv, secondary, bands, varargin{:});
    prm = p.Results;

    assert(isnumeric(piv.u) && ndims(piv.u) == 3, ...
        'plot_divergence_sign_map:PivFormat', ...
        'piv.u must be a numeric [Ny x Nx x nFrames] stack (canonical piv).');
    nFrames = size(piv.u, 3);
    assert(height(secondary) == nFrames, 'plot_divergence_sign_map:FrameMismatch', ...
        'secondary has %d rows but piv has %d frames.', height(secondary), nFrames);

    % --- Divergence field of the interpolation-free velocity --------------
    pivUse = piv;
    if isfield(piv, 'typevector') && ~isempty(piv.typevector)
        isInterpolated = piv.typevector == 2;
        pivUse.u(isInterpolated) = NaN;
        pivUse.v(isInterpolated) = NaN;
    end
    div = compute_divergence_field(pivUse, 'smooth_sigma', prm.smooth_sigma, ...
        'return_field', true);
    X = div.x;
    Y = div.y;
    [Ny, Nx] = size(X);

    % --- Static mask -------------------------------------------------------
    keep = true(Ny, Nx);
    m = prm.edge_margin_cells;
    if m > 0
        keep([1:m, Ny - m + 1:Ny], :) = false;
        keep(:, [1:m, Nx - m + 1:Nx]) = false;
    end
    yPort = prm.port_center_y_m;
    if isnan(yPort)
        yPort = (min(Y(:)) + max(Y(:))) / 2;
    end
    keep(hypot(X - prm.port_wall_x_m, Y - yPort) < prm.port_mask_radius_m) = false;

    % --- One panel per band ------------------------------------------------
    nBands = height(bands);
    fig = figure('Color', 'w', 'Position', [100 100 1500 450 * ceil(nBands / 2)]);
    tl = tiledlayout(fig, ceil(nBands / 2), 2, 'TileSpacing', 'compact');
    cmap = iBlueWhiteRed(256);
    stats = repmat(struct('band_id', "", 'n_frames', 0, 'f_up', NaN, ...
        'f_down', NaN, 'f_undet', NaN), nBands, 1);

    for b = 1:nBands
        inBand = secondary.depth_m >= bands.h_min_m(b) & secondary.depth_m < bands.h_max_m(b) ...
            & isfinite(secondary.D_ref_1_s);
        stats(b).band_id = string(bands.band_id(b));
        stats(b).n_frames = nnz(inBand);
        ax = nexttile(tl);
        hold(ax, 'on');
        if ~any(inBand)
            title(ax, sprintf('%s: no frames', char(string(bands.band_id(b)))));
            continue;
        end

        Dprime = mean(div.D(:, :, inBand) - reshape(secondary.D_ref_1_s(inBand), 1, 1, []), ...
            3, 'omitnan');
        Dshow = Dprime;
        Dshow(~keep) = NaN;
        valid = isfinite(Dshow);
        undetermined = valid & abs(Dshow) < prm.d_noise_1_s;

        imagesc(ax, X(1, :), Y(:, 1), Dshow, 'AlphaData', valid);
        set(ax, 'YDir', 'normal');
        colormap(ax, cmap);
        clim(ax, prm.color_limit_1_s * [-1 1]);
        contour(ax, X, Y, double(undetermined), [0.5 0.5], 'Color', [0.45 0.45 0.45]);

        Umean = mean(piv.u(:, :, inBand), 3, 'omitnan');
        Vmean = mean(piv.v(:, :, inBand), 3, 'omitnan');
        s = prm.quiver_step;
        quiver(ax, X(1:s:end, 1:s:end), Y(1:s:end, 1:s:end), ...
            Umean(1:s:end, 1:s:end), Vmean(1:s:end, 1:s:end), 1.5, 'k', 'LineWidth', 0.5);
        rectangle(ax, 'Position', [prm.port_wall_x_m - 0.02, yPort - prm.port_width_m / 2, ...
            0.02, prm.port_width_m], 'FaceColor', 'k');

        axis(ax, 'equal');
        xlim(ax, [0 prm.basin_size_m(1)]);
        ylim(ax, [0 prm.basin_size_m(2)]);
        box(ax, 'on');
        xlabel(ax, 'x [m]');
        ylabel(ax, 'y [m]');
        title(ax, sprintf('%s  h = %.3f-%.3f m  (%d frames)', char(string(bands.band_id(b))), ...
            bands.h_min_m(b), bands.h_max_m(b), nnz(inBand)));

        values = Dshow(valid);
        stats(b).f_up = mean(values > prm.d_noise_1_s);
        stats(b).f_down = mean(values < -prm.d_noise_1_s);
        stats(b).f_undet = mean(abs(values) <= prm.d_noise_1_s);
    end

    cb = colorbar;
    cb.Layout.Tile = 'east';
    cb.Label.String = 'D'' [1/s]  (red: upwelling, blue: downwelling)';

    runId = "";
    if isfield(piv, 'run_id'), runId = string(piv.run_id); end
    ttl = sprintf('%s  time-mean D'' = D - D_{ref} by depth band (gray outline: |D''| < %.0e, sign undetermined)', ...
        char(runId), prm.d_noise_1_s);
    if strlength(string(prm.title_suffix)) > 0
        ttl = sprintf('%s  %s', ttl, char(string(prm.title_suffix)));
    end
    title(tl, ttl);
end

% =========================================================================
function cmap = iBlueWhiteRed(n)
    half = n / 2;
    blue = [linspace(0.13, 1, half)', linspace(0.35, 1, half)', ones(half, 1)];
    red = [ones(half, 1), linspace(1, 0.2, half)', linspace(1, 0.15, half)'];
    cmap = [blue; red];
end

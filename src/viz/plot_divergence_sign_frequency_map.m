function [fig, hotspots, info] = plot_divergence_sign_frequency_map(piv, secondary, bands, varargin)
%PLOT_DIVERGENCE_SIGN_FREQUENCY_MAP Where up/down-welling occurs most often.
%
% Usage:
%   [fig, hotspots, info] = plot_divergence_sign_frequency_map(piv, secondary, bands)
%
% Inputs:
%   piv        canonical piv struct (numeric u, v, typevector stacks).
%   secondary  table written by s38; provides time_s, depth_m, D_ref_1_s.
%   bands      depth-band table (metadata/depth_bands.csv).
%
% The record is cut into blocks of block_s seconds; in every block the
% anomaly D' = D - D_ref is averaged. For every cell and depth band:
%   freq_up   = fraction of the band's blocks with block-mean D' >  +limit
%   freq_down = fraction of the band's blocks with block-mean D' <  -limit
% where the threshold is max(limit, min_abs_1_s). limit = k_sigma *
% sigma_noise / sqrt(frames per block) is the detection limit of
% plot_divergence_sign_timeseries (sigma_noise from estimate_divergence_noise).
% min_abs_1_s (default 5e-3) additionally asks for a sizable magnitude: because
% D_ref is subtracted, D' carries an almost uniform offset of about -D_ref
% (1e-3 to 3e-3), and with the detection limit alone most cells would count as
% 'up' in inflow runs. A value of 1 means the sign was resolved and sizable in
% every block of the band.
%
% Figure: top row up frequency (white to red), bottom row down frequency
% (white to blue), one column per band. Arrows: band-mean surface velocity.
%
% hotspots: connected regions (8-neighbour) of cells with frequency >=
% hotspot_freq, one row per region: band_id, kind ("up"/"down"), x_m, y_m
% (centroid), area_m2, mean_freq, mean_Dp_1_s (time-mean D' over the region).
% Regions smaller than min_cells are dropped; per band and kind only the
% max_hotspots regions with the largest area*|mean D'| are kept. info: sigma_noise_1_s, limit_1_s,
% n_blocks per band.
%
% Parameters:
%   block_s             Default 30.
%   k_sigma             Default 3.
%   noise_1_s           Fixed sigma_noise [1/s]; default NaN = measure.
%   noise_min_depth_m   Default 0.05.
%   min_abs_1_s         Minimum |D'| counted, see above. Default 5e-3.
%   hotspot_freq        Default 0.8.
%   max_hotspots        Default 5 per band and kind.
%   min_cells           Default 4.
%   smooth_sigma        Default 1.5.
%   edge_margin_cells   Default 4.
%   port_mask_radius_m  Default 0.25.
%   port_wall_x_m       Default 0.
%   port_center_y_m     Default NaN (= middle of the piv.y range).
%   port_width_m        Only for the port marker. Default 0.11.
%   basin_size_m        [Lx Ly] axis limits. Default [2.952 1.962].
%   quiver_step         Arrow every N cells. Default 3.
%   title_suffix        Appended to the figure title.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addRequired('secondary', @istable);
    p.addRequired('bands', @istable);
    p.addParameter('block_s', 30, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('k_sigma', 3, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('noise_1_s', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('noise_min_depth_m', 0.05, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('min_abs_1_s', 5e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('max_hotspots', 5, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('hotspot_freq', 0.8, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
    p.addParameter('min_cells', 4, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('smooth_sigma', 1.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('edge_margin_cells', 4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_mask_radius_m', 0.25, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_wall_x_m', 0, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_center_y_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_width_m', 0.11, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('basin_size_m', [2.952 1.962], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('quiver_step', 3, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.parse(piv, secondary, bands, varargin{:});
    prm = p.Results;

    nFrames = size(piv.u, 3);
    assert(height(secondary) == nFrames, 'plot_divergence_sign_frequency_map:FrameMismatch', ...
        'secondary has %d rows but piv has %d frames.', height(secondary), nFrames);
    time_s = secondary.time_s(:);
    depth_m = secondary.depth_m(:);
    D_ref = secondary.D_ref_1_s(:);
    dt = median(diff(time_s), 'omitnan');
    nPer = max(2, round(prm.block_s / dt));
    nBlocks = floor(nFrames / nPer);

    % --- Divergence field of the interpolation-free velocity --------------
    pivUse = piv;
    if isfield(piv, 'typevector') && ~isempty(piv.typevector)
        isInterpolated = piv.typevector == 2;
        pivUse.u(isInterpolated) = NaN;
        pivUse.v(isInterpolated) = NaN;
    end
    div = compute_divergence_field(pivUse, 'smooth_sigma', prm.smooth_sigma, ...
        'return_field', true, 'log_every', 1e9);
    X = div.x;
    Y = div.y;
    [Ny, Nx] = size(X);

    keep = true(Ny, Nx);
    m = prm.edge_margin_cells;
    if m > 0
        keep([1:m, Ny - m + 1:Ny], :) = false;
        keep(:, [1:m, Nx - m + 1:Nx]) = false;
    end
    yPort = prm.port_center_y_m;
    if isnan(yPort), yPort = (min(Y(:)) + max(Y(:))) / 2; end
    keep(hypot(X - prm.port_wall_x_m, Y - yPort) < prm.port_mask_radius_m) = false;

    sigmaNoise = prm.noise_1_s;
    if ~isfinite(sigmaNoise)
        sigmaNoise = estimate_divergence_noise(div.D, keep, depth_m >= prm.noise_min_depth_m);
    end
    limit = prm.k_sigma * sigmaNoise / sqrt(nPer);
    threshold = max(limit, prm.min_abs_1_s);

    % --- Block-mean D' fields and block depth ------------------------------
    Dbar = NaN(Ny, Nx, nBlocks);
    depthBlock = NaN(nBlocks, 1);
    for j = 1:nBlocks
        idx = (j - 1) * nPer + (1:nPer);
        Dbar(:, :, j) = mean(div.D(:, :, idx), 3, 'omitnan') - mean(D_ref(idx), 'omitnan');
        depthBlock(j) = mean(depth_m(idx), 'omitnan');
    end

    % --- Per band: frequency maps, hotspots, figure ------------------------
    nBands = height(bands);
    fig = figure('Color', 'w', 'Position', [100 100 420 * nBands 620]);
    tl = tiledlayout(fig, 2, nBands, 'TileSpacing', 'compact');
    freqUp = NaN(Ny, Nx, nBands);
    freqDown = NaN(Ny, Nx, nBands);
    nBlocksBand = zeros(nBands, 1);
    hotspots = table(strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), 'VariableNames', {'band_id', 'kind', 'x_m', 'y_m', ...
        'area_m2', 'mean_freq', 'mean_Dp_1_s'});
    cellArea = median(diff(X(1, :))) * median(diff(Y(:, 1)));

    for b = 1:nBands
        inBand = depthBlock >= bands.h_min_m(b) & depthBlock < bands.h_max_m(b);
        nBlocksBand(b) = nnz(inBand);
        if nnz(inBand) >= 1
            Dsel = Dbar(:, :, inBand);
            freqUp(:, :, b) = mean(Dsel > threshold, 3);
            freqDown(:, :, b) = mean(Dsel < -threshold, 3);
            meanDp = mean(Dsel, 3, 'omitnan');
        end
        freqUp(:, :, b) = iMask(freqUp(:, :, b), keep);
        freqDown(:, :, b) = iMask(freqDown(:, :, b), keep);

        for kind = ["up", "down"]
            if kind == "up", F = freqUp(:, :, b); else, F = freqDown(:, :, b); end
            ax = nexttile(tl, (kind == "down") * nBands + b);
            hold(ax, 'on');
            if nBlocksBand(b) == 0
                title(ax, sprintf('%s: no blocks', char(string(bands.band_id(b)))));
                continue;
            end
            imagesc(ax, X(1, :), Y(:, 1), F, 'AlphaData', isfinite(F));
            set(ax, 'YDir', 'normal');
            colormap(ax, iWhiteTo(kind));
            clim(ax, [0 1]);
            inBandFrames = depth_m >= bands.h_min_m(b) & depth_m < bands.h_max_m(b);
            s = prm.quiver_step;
            Umean = mean(piv.u(:, :, inBandFrames), 3, 'omitnan');
            Vmean = mean(piv.v(:, :, inBandFrames), 3, 'omitnan');
            quiver(ax, X(1:s:end, 1:s:end), Y(1:s:end, 1:s:end), ...
                Umean(1:s:end, 1:s:end), Vmean(1:s:end, 1:s:end), 1.5, 'k', 'LineWidth', 0.4);
            rectangle(ax, 'Position', [prm.port_wall_x_m - 0.02, yPort - prm.port_width_m / 2, ...
                0.02, prm.port_width_m], 'FaceColor', 'k');
            axis(ax, 'equal');
            xlim(ax, [0 prm.basin_size_m(1)]);
            ylim(ax, [0 prm.basin_size_m(2)]);
            box(ax, 'on');
            if kind == "up"
                title(ax, sprintf('%s  h = %.3f-%.3f m (%d blocks)', ...
                    char(string(bands.band_id(b))), bands.h_min_m(b), bands.h_max_m(b), nBlocksBand(b)));
            end
            if b == 1, ylabel(ax, sprintf('%s: y [m]', char(kind))); end
            if kind == "down", xlabel(ax, 'x [m]'); end

            % hotspots: connected regions of frequently resolved cells
            cc = bwconncomp(F >= prm.hotspot_freq, 8);
            found = hotspots(1:0, :);
            for r = 1:cc.NumObjects
                pix = cc.PixelIdxList{r};
                if numel(pix) < prm.min_cells, continue; end
                found(end + 1, :) = {string(bands.band_id(b)), kind, mean(X(pix)), mean(Y(pix)), ...
                    numel(pix) * cellArea, mean(F(pix)), mean(meanDp(pix), 'omitnan')}; %#ok<AGROW>
            end
            [~, order] = sort(found.area_m2 .* abs(found.mean_Dp_1_s), 'descend');
            found = found(order(1:min(end, prm.max_hotspots)), :);
            hotspots = [hotspots; found]; %#ok<AGROW>
            plot(ax, found.x_m, found.y_m, 'k+', 'MarkerSize', 9, 'LineWidth', 1.2);
        end
    end
    cb = colorbar;
    cb.Layout.Tile = 'east';
    cb.Label.String = sprintf('fraction of %g s blocks with |D''| > %.1e 1/s', prm.block_s, threshold);

    runId = "";
    if isfield(piv, 'run_id'), runId = string(piv.run_id); end
    ttl = sprintf('%s  frequency of up (top) / down (bottom) with |D''| > %.1e 1/s  (detection limit %.1e);  + : largest regions with frequency >= %.1f', ...
        char(runId), threshold, limit, prm.hotspot_freq);
    if strlength(string(prm.title_suffix)) > 0
        ttl = sprintf('%s  %s', ttl, char(string(prm.title_suffix)));
    end
    title(tl, ttl);

    info = struct('sigma_noise_1_s', sigmaNoise, 'limit_1_s', limit, ...
        'n_blocks', nBlocksBand, 'dt_s', dt, 'n_per_block', nPer);
end

% =========================================================================
function A = iMask(A, keep)
    A(~keep) = NaN;
end

function cmap = iWhiteTo(kind)
    t = linspace(0, 1, 256)';
    if kind == "up"
        target = [0.80 0.10 0.10];
    else
        target = [0.10 0.30 0.85];
    end
    cmap = (1 - t) .* [1 1 1] + t .* target;
end

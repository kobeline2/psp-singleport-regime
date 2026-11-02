function [fig, blocks, info] = plot_divergence_sign_timeseries(piv, secondary, varargin)
%PLOT_DIVERGENCE_SIGN_TIMESERIES Up/down-welling area fractions against time.
%
% Usage:
%   [fig, blocks, info] = plot_divergence_sign_timeseries(piv, secondary)
%
% Inputs:
%   piv        canonical piv struct (numeric u, v, typevector stacks).
%   secondary  table written by s38; provides time_s, depth_m, D_ref_1_s.
%
% The record is cut into blocks of block_s seconds. In each block the
% anomaly D' = D - D_ref is averaged over the frames, and the plan-view area
% fractions are counted on that block-mean field:
%   f_up   : block-mean D' >  +limit  (upwelling resolved)
%   f_down : block-mean D' <  -limit  (downwelling resolved)
%   f_below: |block-mean D'| <= limit (smaller than the detection limit;
%            not distinguishable from zero)
% The detection limit is  limit = k_sigma * sigma_noise / sqrt(n_frames), the
% k_sigma-sigma bound of a block mean of white single-frame noise. It replaces
% the fixed single-frame threshold of s38 (D_noise), which is not appropriate
% for averaged fields and, for fast runs, is below the single-frame noise.
%
% sigma_noise (single-frame noise of D' [1/s]) is measured from the data: the
% structure function g(k) = 0.5*var(D(t+k) - D(t)) of the cells is
% extrapolated linearly to lag 0, sigma_noise^2 = 2 g(1) - g(2). It is taken
% from frames with depth >= noise_min_depth_m (steady jet, smooth signal) and
% is assumed constant over the run. Assumptions: noise is white between
% frames, and the signal is smooth over two frame intervals. If neighbouring
% frames share images the noise is under-estimated.
%
% Outputs:
%   blocks  table, one row per block: time_s, depth_m, D_ref_1_s, limit_1_s,
%           Dp_mean_1_s, f_up, f_down, f_below.
%   info    struct: sigma_noise_1_s, dt_s, n_per_block, k_sigma.
%
% Parameters:
%   block_s             Averaging block [s]. Default 30.
%   k_sigma             Default 3.
%   noise_1_s           Fixed sigma_noise [1/s]; default NaN = measure.
%   noise_min_depth_m   Default 0.05.
%   smooth_sigma        Gaussian sigma [cells] of D. Default 1.5.
%   edge_margin_cells   Default 4.
%   port_mask_radius_m  Default 0.25.
%   port_wall_x_m       Default 0.
%   port_center_y_m     Default NaN (= middle of the piv.y range).
%   title_suffix        Appended to the figure title.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addRequired('secondary', @istable);
    p.addParameter('block_s', 30, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('k_sigma', 3, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('noise_1_s', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('noise_min_depth_m', 0.05, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('smooth_sigma', 1.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('edge_margin_cells', 4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_mask_radius_m', 0.25, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_wall_x_m', 0, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_center_y_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('title_suffix', "", @(x) isstring(x) || ischar(x));
    p.parse(piv, secondary, varargin{:});
    prm = p.Results;

    nFrames = size(piv.u, 3);
    assert(height(secondary) == nFrames, 'plot_divergence_sign_timeseries:FrameMismatch', ...
        'secondary has %d rows but piv has %d frames.', height(secondary), nFrames);
    time_s = secondary.time_s(:);
    depth_m = secondary.depth_m(:);
    D_ref = secondary.D_ref_1_s(:);
    dt = median(diff(time_s), 'omitnan');
    nPer = max(2, round(prm.block_s / dt));

    % --- Divergence field of the interpolation-free velocity --------------
    pivUse = piv;
    if isfield(piv, 'typevector') && ~isempty(piv.typevector)
        isInterpolated = piv.typevector == 2;
        pivUse.u(isInterpolated) = NaN;
        pivUse.v(isInterpolated) = NaN;
    end
    div = compute_divergence_field(pivUse, 'smooth_sigma', prm.smooth_sigma, ...
        'return_field', true, 'log_every', 1e9);
    [Ny, Nx] = size(div.x);

    keep = true(Ny, Nx);
    m = prm.edge_margin_cells;
    if m > 0
        keep([1:m, Ny - m + 1:Ny], :) = false;
        keep(:, [1:m, Nx - m + 1:Nx]) = false;
    end
    yPort = prm.port_center_y_m;
    if isnan(yPort), yPort = (min(div.y(:)) + max(div.y(:))) / 2; end
    keep(hypot(div.x - prm.port_wall_x_m, div.y - yPort) < prm.port_mask_radius_m) = false;

    % --- Single-frame noise of D (structure function at lag 0) -------------
    sigmaNoise = prm.noise_1_s;
    if ~isfinite(sigmaNoise)
        sigmaNoise = iEstimateNoise(div.D, keep, depth_m >= prm.noise_min_depth_m);
    end

    % --- Block means and area fractions ------------------------------------
    nBlocks = floor(nFrames / nPer);
    blocks = table('Size', [nBlocks 8], ...
        'VariableTypes', repmat({'double'}, 1, 8), ...
        'VariableNames', {'time_s', 'depth_m', 'D_ref_1_s', 'limit_1_s', ...
        'Dp_mean_1_s', 'f_up', 'f_down', 'f_below'});
    for j = 1:nBlocks
        idx = (j - 1) * nPer + (1:nPer);
        Dbar = mean(div.D(:, :, idx), 3, 'omitnan') - mean(D_ref(idx), 'omitnan');
        values = Dbar(keep & isfinite(Dbar));
        limit = prm.k_sigma * sigmaNoise / sqrt(nPer);
        blocks.time_s(j) = mean(time_s(idx));
        blocks.depth_m(j) = mean(depth_m(idx), 'omitnan');
        blocks.D_ref_1_s(j) = mean(D_ref(idx), 'omitnan');
        blocks.limit_1_s(j) = limit;
        blocks.Dp_mean_1_s(j) = mean(values);
        blocks.f_up(j) = mean(values > limit);
        blocks.f_down(j) = mean(values < -limit);
        blocks.f_below(j) = mean(abs(values) <= limit);
    end
    info = struct('sigma_noise_1_s', sigmaNoise, 'dt_s', dt, ...
        'n_per_block', nPer, 'k_sigma', prm.k_sigma);

    % --- Figure --------------------------------------------------------------
    fig = figure('Color', 'w', 'Position', [100 100 1100 600]);
    tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');

    ax1 = nexttile(tl);
    plot(ax1, blocks.time_s, blocks.depth_m, 'k-', 'LineWidth', 1.2);
    ylabel(ax1, 'depth h [m]'); grid(ax1, 'on');

    ax2 = nexttile(tl);
    hold(ax2, 'on');
    plot(ax2, blocks.time_s, blocks.f_up, '-', 'Color', [0.85 0.2 0.15], 'LineWidth', 1.4);
    plot(ax2, blocks.time_s, blocks.f_down, '-', 'Color', [0.15 0.35 0.85], 'LineWidth', 1.4);
    plot(ax2, blocks.time_s, blocks.f_below, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.4);
    hold(ax2, 'off'); grid(ax2, 'on'); ylim(ax2, [0 1]);
    ylabel(ax2, 'area fraction');
    legend(ax2, {'upwelling', 'downwelling', 'below detection limit'}, ...
        'Location', 'eastoutside');

    ax3 = nexttile(tl);
    hold(ax3, 'on');
    plot(ax3, blocks.time_s, blocks.Dp_mean_1_s, 'k-', 'LineWidth', 1.2);
    plot(ax3, blocks.time_s, blocks.limit_1_s, 'k:', 'LineWidth', 1);
    plot(ax3, blocks.time_s, -blocks.limit_1_s, 'k:', 'LineWidth', 1);
    hold(ax3, 'off'); grid(ax3, 'on');
    ylabel(ax3, 'area-mean D'' [1/s]');
    xlabel(ax3, 'time [s]');
    linkaxes([ax1 ax2 ax3], 'x');

    runId = "";
    if isfield(piv, 'run_id'), runId = string(piv.run_id); end
    ttl = sprintf('%s  D'' = D - D_{ref}, %g s blocks; detection limit %g\\sigma_{noise}/\\surd n = %.1e 1/s (\\sigma_{noise} = %.1e 1/s)', ...
        char(runId), prm.block_s, prm.k_sigma, blocks.limit_1_s(1), sigmaNoise);
    if strlength(string(prm.title_suffix)) > 0
        ttl = sprintf('%s  %s', ttl, char(string(prm.title_suffix)));
    end
    title(tl, ttl);
end

% =========================================================================
function sigma = iEstimateNoise(D, keep, useFrame)
% sigma_noise^2 = 2 g(1) - g(2), g(k) = 0.5*mean((D(t+k)-D(t))^2) per cell,
% median over cells. Frames are taken as contiguous runs of useFrame; at
% most 4000 frames (from the middle of the longest run) to bound memory.
    idx = find(useFrame);
    assert(numel(idx) >= 100, 'plot_divergence_sign_timeseries:NoiseFrames', ...
        'Too few frames deeper than noise_min_depth_m to measure the noise.');
    if numel(idx) > 4000
        mid = round(numel(idx) / 2);
        idx = idx(mid - 1999:mid + 2000);
    end
    [Ny, Nx, ~] = size(D);
    X = reshape(D(:, :, idx), Ny * Nx, []);
    X = X(keep(:), :);
    g1 = 0.5 * mean((X(:, 2:end) - X(:, 1:end - 1)) .^ 2, 2, 'omitnan');
    g2 = 0.5 * mean((X(:, 3:end) - X(:, 1:end - 2)) .^ 2, 2, 'omitnan');
    sigma = sqrt(median(max(2 * g1 - g2, 0), 'omitnan'));
end

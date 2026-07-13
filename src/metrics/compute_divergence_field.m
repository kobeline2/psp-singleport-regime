function div = compute_divergence_field(piv, varargin)
%COMPUTE_DIVERGENCE_FIELD Surface horizontal divergence D = du/dx + dv/dy.
%
% Secondary, exploratory metric (NOT one of the fixed primary metrics).
%
% Purpose:
%   Visualize upwelling / downwelling structure at the free surface as a
%   proxy for the vertical-velocity gradient. From incompressibility,
%       dw/dz = -(du/dx + dv/dy) = -D,
%   and with w = 0 at a flat free surface, fluid just below the surface has
%   w ~ D*|z|. Therefore:
%       D > 0  (horizontal divergence)  -> upwelling   (湧き上がり)
%       D < 0  (horizontal convergence) -> downwelling (沈み込み)
%
% Interpretation limits (state these in any write-up):
%   - This yields dw/dz (relative strength/sign of vertical motion), NOT w.
%   - Absolute vertical velocity needs depth-resolved u, v.
%   - Floating tracers can cluster in convergence zones; treat the field as
%     a qualitative structure map, not a calibrated flux.
%
% Numerics:
%   - Differentiation is noise-sensitive, so u and v are Gaussian-smoothed
%     before differencing (smoothing is essential; default sigma > 0).
%   - Smoothing is NaN-aware (normalized convolution) so invalid vectors do
%     not enlarge into the surrounding valid region.
%   - gradient uses central differences (one-sided at boundaries) on the
%     same grid as the other metrics.
%
% Usage:
%   div = compute_divergence_field(piv, 'smooth_sigma', 1.5)
%   div = compute_divergence_field(piv, 'smooth_sigma', 1.5, 'return_field', false)
%
% Parameters:
%   smooth_sigma  Gaussian sigma [grid cells] applied to u and v before
%                 differentiation. Default = 1.5. Use the same value across
%                 all runs once fixed in pilot analysis.
%   return_field  If true (default), keep the per-frame field D in div.D.
%                 If false, only the time-mean field and frame-wise D_rms
%                 are returned (memory-light path for s30).
%   log_every     Progress log interval in frames. Default = 500.
%
% Output struct div:
%   run_id, source, variant
%   x, y          2-D grids [Ny x Nx] (for plotting)
%   frame_idx     [nFrames x 1]
%   D_rms         [nFrames x 1]  sqrt(<D^2>_Omega), structure strength [1/s]
%   D_mean        [Ny x Nx]      time-mean divergence field [1/s]
%   D             [Ny x Nx x nFrames] or []  per-frame field [1/s]
%   smooth_sigma  the sigma used
%   units         "1/s"

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addParameter('smooth_sigma',  1.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('return_field',  true, @(x) islogical(x) || isnumeric(x));
    p.addParameter('log_every',     500,  @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.parse(piv, varargin{:});
    prm = p.Results;
    returnField = logical(prm.return_field);

    assert(isfield(piv, 'u') && isfield(piv, 'v'), ...
        'compute_divergence_field:MissingVelocity', ...
        'piv must contain fields u and v.');

    [dx, dy] = iGridSpacing(piv);
    nFrames  = iFrameCount(piv.u, 'piv.u');
    sampleU  = iFrameSlice(piv.u, 1, nFrames, 'piv.u');
    [Ny, Nx] = size(sampleU);

    frame_idx = (1:nFrames).';
    D_rms     = NaN(nFrames, 1);
    sumD      = zeros(Ny, Nx);   % running sum of finite D per cell
    cntD      = zeros(Ny, Nx);   % running count of finite D per cell
    if returnField
        Dfield = NaN(Ny, Nx, nFrames);
    else
        Dfield = [];
    end

    t0 = tic;
    for k = 1:nFrames
        U = iFrameSlice(piv.u, k, nFrames, 'piv.u');
        V = iFrameSlice(piv.v, k, nFrames, 'piv.v');

        if prm.smooth_sigma > 0
            U = iSmoothNaN(U, prm.smooth_sigma);
            V = iSmoothNaN(V, prm.smooth_sigma);
        end

        % gradient(F, dx, dy): 1st output = dF/dx (cols), 2nd = dF/dy (rows).
        [dUdx, ~   ] = gradient(U, dx, dy);
        [~,    dVdy] = gradient(V, dx, dy);
        D = dUdx + dVdy;

        valid = isfinite(D);
        if any(valid(:))
            D_rms(k) = sqrt(mean(D(valid).^2));
            sumD(valid) = sumD(valid) + D(valid);
            cntD(valid) = cntD(valid) + 1;
        end
        if returnField
            Dfield(:, :, k) = D;
        end

        if mod(k, prm.log_every) == 0 || k == 1 || k == nFrames
            elapsed = toc(t0);
            rate    = k / max(elapsed, eps);
            remain  = (nFrames - k) / max(rate, eps);
            fprintf('[compute_divergence_field] Frame %d / %d (%.1f%%), elapsed %.1fs, ETA %.1fs\n', ...
                k, nFrames, 100 * k / nFrames, elapsed, remain);
        end
    end

    D_mean = sumD ./ cntD;
    D_mean(cntD == 0) = NaN;

    div = struct();
    div.run_id  = iGetStringField(piv, 'run_id', "");
    div.source  = iGetStringField(piv, 'source', "");
    div.variant = iGetStringField(piv, 'variant', "");
    div.x = iStaticGrid(piv, 'x', Ny, Nx);
    div.y = iStaticGrid(piv, 'y', Ny, Nx);
    div.frame_idx = frame_idx;
    div.D_rms = D_rms;
    div.D_mean = D_mean;
    div.D = Dfield;
    div.smooth_sigma = prm.smooth_sigma;
    div.units = "1/s";
end

% =========================================================================
% Local helpers (self-contained, mirroring compute_frame_metrics_circ).
% If a fourth metric function needs these, extract to src/metrics/private/.
% =========================================================================

function S = iSmoothNaN(F, sigma)
% NaN-aware Gaussian smoothing via normalized convolution (Knutsson).
% Missing cells contribute nothing; cells with too little local support
% (smoothed mask below a threshold) are returned as NaN rather than
% fabricated.
    mask = isfinite(F);
    if all(mask(:))
        S = imgaussfilt(F, sigma);
        return;
    end
    F0 = F;
    F0(~mask) = 0;
    num = imgaussfilt(F0, sigma);
    den = imgaussfilt(double(mask), sigma);
    S = num ./ den;
    S(den < 0.2) = NaN;   % < ~20% effective support -> treat as missing
end

function [dx, dy] = iGridSpacing(piv)
% dx: spacing along columns (x). Must be positive.
% dy: signed spacing along rows (y); negative if y decreases with row index.
    if isfield(piv, 'x') && ~isempty(piv.x)
        X = piv.x;
        if ndims(X) > 2, X = X(:, :, 1); end
        col_diffs = diff(X(1, :));
        assert(all(col_diffs > 0), ...
            'compute_divergence_field:GridXNotMonotonic', ...
            'piv.x must increase monotonically along columns.');
        dx = mean(col_diffs);
    else
        dx = 1;
        warning('compute_divergence_field:NoGridX', ...
            'piv.x not found; using dx = 1. Divergence will be in pixel^{-1} units.');
    end

    if isfield(piv, 'y') && ~isempty(piv.y)
        Y = piv.y;
        if ndims(Y) > 2, Y = Y(:, :, 1); end
        dy = mean(diff(Y(:, 1)));   % signed
    else
        dy = 1;
        warning('compute_divergence_field:NoGridY', ...
            'piv.y not found; using dy = 1. Divergence will be in pixel^{-1} units.');
    end
end

function G = iStaticGrid(piv, fieldName, Ny, Nx)
    if isfield(piv, fieldName) && ~isempty(piv.(fieldName))
        G = piv.(fieldName);
        if ndims(G) > 2, G = G(:, :, 1); end
        G = double(G);
    elseif strcmp(fieldName, 'x')
        G = repmat(1:Nx, Ny, 1);
    else
        G = repmat((1:Ny).', 1, Nx);
    end
end

function nFrames = iFrameCount(data, varName)
    if iscell(data)
        nFrames = numel(data);
    elseif isnumeric(data)
        if ndims(data) <= 2
            nFrames = 1;
        elseif ndims(data) == 3
            nFrames = size(data, 3);
        else
            error('compute_divergence_field:InvalidFieldSize', ...
                '%s must be 2-D, 3-D, or cell.', varName);
        end
    else
        error('compute_divergence_field:InvalidFieldType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
    end
end

function A = iFrameSlice(data, k, nFrames, varName)
    if iscell(data)
        assert(numel(data) == nFrames, ...
            'compute_divergence_field:CellLength', ...
            '%s must have %d cells.', varName, nFrames);
        A = data{k};
    elseif isnumeric(data)
        if ndims(data) <= 2
            A = data;
        else
            A = data(:, :, k);
        end
    else
        error('compute_divergence_field:InvalidFieldType', ...
            '%s must be numeric or cell.', varName);
    end
    assert(isnumeric(A), ...
        'compute_divergence_field:InvalidSlice', ...
        '%s frame %d must be numeric.', varName, k);
    A = double(A);
end

function value = iGetStringField(S, fieldName, defaultValue)
    if isfield(S, fieldName)
        value = string(S.(fieldName));
    else
        value = string(defaultValue);
    end
end

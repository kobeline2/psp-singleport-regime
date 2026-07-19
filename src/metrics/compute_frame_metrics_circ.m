function T = compute_frame_metrics_circ(piv, varargin)
%COMPUTE_FRAME_METRICS_CIRC Compute circulation indices from canonical PIV.
%
% I_circ(t) = (a / U_p) * <omega(x,y,t)>_Omega        (signed net rotation)
% I_rot(t)  = (a / U_p) * <|omega(x,y,t)|>_Omega      (rotation activity)
%
% where:
%   omega(x,y,t) = dv/dx - du/dy   (2-D vorticity in the piv.x/piv.y system)
%   a   = port height [m]
%   U_p = Q / (a * b), port mean velocity [m/s]
%   <.> = spatial mean over finite cells
%
% The two indices are complementary. In a closed basin the signed mean
% <omega> is near zero both when there is no rotation at all (outflow
% sink) and when strong counter-rotating cells cancel (inflow twin
% cells); the unsigned <|omega|> separates these two cases, staying large
% only when rotational motion is actually present.
%
% Sign convention: positive I_circ = net counterclockwise rotation in the
% (piv.x rightward, piv.y increasing with row) coordinate system.
% If piv.y increases downward (image convention), positive I_circ is clockwise
% in physical (y-upward) space. Confirm the piv.y direction for your dataset.
%
% Usage:
%   T = compute_frame_metrics_circ(piv, 'U_p_m_s', 0.123)
%   T = compute_frame_metrics_circ(piv, 'U_p_m_s', Up, ...
%           'port_height_m', 0.055, 'smooth_sigma', 1.5)
%
% Parameters:
%   U_p_m_s       Port mean velocity [m/s]. Must be finite and positive.
%   port_height_m Port height a [m]. Forms the a/U_p normalization scale.
%                 Default = 0.055.
%   smooth_sigma  Gaussian pre-smoothing of u and v before differentiation,
%                 in grid cells. 0 = no smoothing (default).
%                 Fix this value during pilot analysis and apply consistently.
%                 Requires Image Processing Toolbox (imgaussfilt).
%   log_every     Progress log interval in frames. Default = 500.
%
% Output columns:
%   run_id, source, variant, frame_idx,
%   omega_mean, I_circ, omega_abs_mean, I_rot,
%   U_p_m_s, port_height_m, smooth_sigma

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addParameter('U_p_m_s',       NaN,   @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_height_m', 0.055, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('smooth_sigma',  0,     @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('log_every',     500,   @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.parse(piv, varargin{:});
    prm = p.Results;

    assert(isfield(piv, 'u') && isfield(piv, 'v'), ...
        'compute_frame_metrics_circ:MissingVelocity', ...
        'piv must contain fields u and v.');
    assert(isfinite(prm.U_p_m_s) && prm.U_p_m_s > 0, ...
        'compute_frame_metrics_circ:InvalidUp', ...
        'U_p_m_s must be a finite positive scalar. Got: %g', prm.U_p_m_s);

    [dx, dy] = iGridSpacing(piv);
    scale    = prm.port_height_m / prm.U_p_m_s;   % a / U_p  [s]

    nFrames = iFrameCount(piv.u, 'piv.u');
    run_id  = repmat(iGetStringField(piv, 'run_id',  ""), nFrames, 1);
    source  = repmat(iGetStringField(piv, 'source',  ""), nFrames, 1);
    variant = repmat(iGetStringField(piv, 'variant', ""), nFrames, 1);

    frame_idx      = (1:nFrames).';
    omega_mean     = NaN(nFrames, 1);
    I_circ         = NaN(nFrames, 1);
    omega_abs_mean = NaN(nFrames, 1);
    I_rot          = NaN(nFrames, 1);

    t0 = tic;
    for k = 1:nFrames
        U = iFrameSlice(piv.u, k, nFrames, 'piv.u');
        V = iFrameSlice(piv.v, k, nFrames, 'piv.v');

        % Optional Gaussian pre-smoothing before differentiation.
        % NaN-aware (normalized convolution) so invalid vectors do not grow
        % into the surrounding valid region. The omega_mean step below
        % ignores any remaining NaN cells.
        if prm.smooth_sigma > 0
            U = iSmoothNaN(U, prm.smooth_sigma);
            V = iSmoothNaN(V, prm.smooth_sigma);
        end

        % 2-D vorticity via central differences (one-sided at boundaries).
        % gradient(F, hx, hy): first output = dF/dx (along cols, dim 2),
        %                       second output = dF/dy (along rows, dim 1).
        [~,    dUdy] = gradient(U, dx, dy);
        [dVdx, ~   ] = gradient(V, dx, dy);
        omega = dVdx - dUdy;

        valid_omega = isfinite(omega);
        if any(valid_omega(:))
            omega_mean(k)     = mean(omega(valid_omega));
            I_circ(k)         = scale * omega_mean(k);
            omega_abs_mean(k) = mean(abs(omega(valid_omega)));
            I_rot(k)          = scale * omega_abs_mean(k);
        end

        if mod(k, prm.log_every) == 0 || k == 1 || k == nFrames
            elapsed = toc(t0);
            rate    = k / max(elapsed, eps);
            remain  = (nFrames - k) / max(rate, eps);
            fprintf('[compute_frame_metrics_circ] Frame %d / %d (%.1f%%), elapsed %.1fs, ETA %.1fs\n', ...
                k, nFrames, 100 * k / nFrames, elapsed, remain);
        end
    end

    U_p_out    = repmat(prm.U_p_m_s,       nFrames, 1);
    a_out      = repmat(prm.port_height_m,  nFrames, 1);
    sigma_out  = repmat(prm.smooth_sigma,   nFrames, 1);

    T = table(run_id, source, variant, frame_idx, ...
              omega_mean, I_circ, omega_abs_mean, I_rot, ...
              U_p_out, a_out, sigma_out, ...
              'VariableNames', { ...
                  'run_id', 'source', 'variant', 'frame_idx', ...
                  'omega_mean', 'I_circ', 'omega_abs_mean', 'I_rot', ...
                  'U_p_m_s', 'port_height_m', 'smooth_sigma'});
end

% =========================================================================
% Local helpers
% (Parallel to compute_frame_metrics_basic; extract to shared utils if a
% third function needs them.)
% =========================================================================

function S = iSmoothNaN(F, sigma)
% NaN-aware Gaussian smoothing via normalized convolution (Knutsson).
% Missing cells contribute nothing; cells with too little local support
% are returned as NaN rather than fabricated.
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
% Extract grid spacing from piv.x / piv.y.
% dx: spacing along columns (x-direction). Must be positive.
% dy: spacing along rows (y-direction). Signed; may be negative if piv.y
%     decreases with increasing row index.
    if isfield(piv, 'x') && ~isempty(piv.x)
        X = piv.x;
        if ndims(X) > 2, X = X(:,:,1); end
        col_diffs = diff(X(1,:));
        assert(all(col_diffs > 0), ...
            'compute_frame_metrics_circ:GridXNotMonotonic', ...
            'piv.x must increase monotonically along columns.');
        dx = mean(col_diffs);
    else
        dx = 1;
        warning('compute_frame_metrics_circ:NoGridX', ...
            'piv.x not found; using dx = 1. Vorticity will be in pixel^{-1} units.');
    end

    if isfield(piv, 'y') && ~isempty(piv.y)
        Y = piv.y;
        if ndims(Y) > 2, Y = Y(:,:,1); end
        dy = mean(diff(Y(:,1)));   % signed
    else
        dy = 1;
        warning('compute_frame_metrics_circ:NoGridY', ...
            'piv.y not found; using dy = 1. Vorticity will be in pixel^{-1} units.');
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
            error('compute_frame_metrics_circ:InvalidFieldSize', ...
                '%s must be 2-D, 3-D, or cell.', varName);
        end
    else
        error('compute_frame_metrics_circ:InvalidFieldType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
    end
end

function A = iFrameSlice(data, k, nFrames, varName)
    if iscell(data)
        assert(numel(data) == nFrames, ...
            'compute_frame_metrics_circ:CellLength', ...
            '%s must have %d cells.', varName, nFrames);
        A = data{k};
    elseif isnumeric(data)
        if ndims(data) <= 2
            A = data;
        else
            A = data(:,:,k);
        end
    else
        error('compute_frame_metrics_circ:InvalidFieldType', ...
            '%s must be numeric or cell.', varName);
    end
    assert(isnumeric(A), ...
        'compute_frame_metrics_circ:InvalidSlice', ...
        '%s frame %d must be numeric.', varName, k);
end

function value = iGetStringField(S, fieldName, defaultValue)
    if isfield(S, fieldName)
        value = string(S.(fieldName));
    else
        value = string(defaultValue);
    end
end

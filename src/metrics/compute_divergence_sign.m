function T = compute_divergence_sign(piv, varargin)
%COMPUTE_DIVERGENCE_SIGN Up/down-welling relative to the rising water level.
%
% Secondary, exploratory metric (NOT one of the fixed primary metrics).
% Built on compute_divergence_field (surface divergence D = du/dx + dv/dy,
% Gaussian-smoothed). Only the SIGN of the vertical motion is of interest,
% so nothing is non-dimensionalized.
%
% Definition
%   Incompressibility gives dw/dz = -D. With w ~ 0 at the free surface,
%   D > 0 (horizontal divergence) means water is welling up from below;
%   D < 0 (convergence) means it is sinking.
%
%   The water level is not constant: while the basin fills (or drains) the
%   whole column rises (or falls) uniformly, w = (dh/dt)(z/h), which on
%   its own gives a uniform
%       D_ref(t) = -(1/h) dh/dt                           [1/s]
%   (negative while filling). The index is the anomaly with respect to
%   this uniform rise,
%       D'(x,y,t) = D(x,y,t) - D_ref(t),
%   and its sign is read as
%       D' > 0 : upwelling   stronger than the uniform rise,
%       D' < 0 : downwelling / weaker than the uniform rise.
%   (D_ref is ~ -1.7e-3 1/s at 0.5 L/s and h = 50 mm, i.e. small next to
%   typical PIV divergence, but it is subtracted explicitly so that the
%   statement "relative to the water-level change" is exact.)
%
% Scalars returned for every frame (domain Omega' = analysis cells after
% masking, see below):
%   Dp_mean_1_s : <D'> over Omega'                       [1/s]
%   f_up        : fraction of Omega' with D' >  +D_noise
%   f_down      : fraction of Omega' with D' <  -D_noise
%   f_undet     : fraction with |D'| <= D_noise (sign not resolvable)
% f_up + f_down + f_undet = 1. D_noise is the sign-resolution threshold:
% |D'| below it is within PIV noise and its sign is not trusted.
% Each scalar is also given as a moving average over 'avg_window_s'
% (suffix _win), because the per-frame values are noisy while the depth
% changes slowly. Plot them against depth_m.
%
% Masks (cells excluded from Omega'):
%   - edge_margin_cells cells along the grid border (one-sided differences
%     and smoothing edge effects),
%   - a disc of radius port_mask_radius_m around the port mouth
%     (x = port_wall_x_m, y = port_center_y_m), where the jet is strongly
%     three-dimensional,
%   - PIVLab-interpolated vectors (typevector == 2), which are artificially
%     smooth, when exclude_interpolated is true.
%
% Interpretation limits (state these in any write-up):
%   - Gives the sign/relative strength of dw/dz at the surface, not w.
%   - D' ~= 0 on average over depth is guaranteed by w = 0 at the bed, so a
%     non-zero surface D' means vertical structure (secondary circulation).
%   - Smoothing sigma (1.5 cells ~ 47 mm) is comparable to the depth
%     (30-100 mm): structures smaller than ~ the depth are not resolved.
%   - Floating tracers cluster in convergence zones, so PIV is less
%     reliable there (bias towards fewer reliable vectors where D < 0).
%
% Usage:
%   T = compute_divergence_sign(piv, 'time_s', t, 'depth_m', h, ...
%           'port_center_y_m', 0.981)
%
% Parameters:
%   time_s, depth_m  [nFrames x 1] frame times and water depth (required;
%                    depth from frame_metrics after s31).
%   smooth_sigma     Gaussian sigma [cells] for D. Default 1.5.
%   D_noise_1_s      Sign-resolution threshold [1/s]. Default 5e-3,
%                    PROVISIONAL: a propagation estimate (PIV noise
%                    sigma_u ~ 3e-4 m/s, spacing 31.5 mm, sigma = 1.5)
%                    gives ~1.4e-3 1/s for the rms noise of D; the default
%                    is ~3x that. Replace by a value measured on quiescent
%                    frames and keep it fixed for all runs.
%   dhdt_window_s    Smoothing window for dh/dt [s]. Default 20 (the logger
%                    is 1 mm quantized, same reason as compute_actual_discharge).
%   avg_window_s     Moving-average window for the _win columns. Default 30.
%   edge_margin_cells, port_mask_radius_m, port_wall_x_m, port_center_y_m,
%   exclude_interpolated  see Masks. Defaults 2, 0.25, 0, NaN (= middle of
%                    the piv.y range), true.
%   log_every        Progress interval passed to compute_divergence_field.
%
% Output table T (one row per frame):
%   run_id, frame_idx, time_s, depth_m, dhdt_m_s, D_ref_1_s, n_valid,
%   Dp_mean_1_s, f_up, f_down, f_undet, and the *_win versions.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addParameter('time_s', [], @isnumeric);
    p.addParameter('depth_m', [], @isnumeric);
    p.addParameter('smooth_sigma', 1.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('D_noise_1_s', 5e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('dhdt_window_s', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('avg_window_s', 30, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('edge_margin_cells', 2, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_mask_radius_m', 0.25, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('port_wall_x_m', 0, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('port_center_y_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('exclude_interpolated', true, @(x) islogical(x) || isnumeric(x));
    p.addParameter('log_every', 500, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.parse(piv, varargin{:});
    prm = p.Results;

    time_s = prm.time_s(:);
    depth_m = prm.depth_m(:);
    nFrames = numel(depth_m);
    assert(nFrames >= 3 && numel(time_s) == nFrames, ...
        'compute_divergence_sign:TimeDepth', ...
        'time_s and depth_m are required and must have one entry per frame.');

    % --- Uniform-rise reference D_ref = -(1/h) dh/dt ---------------------
    dt = median(diff(time_s), 'omitnan');
    assert(isfinite(dt) && dt > 0, 'compute_divergence_sign:BadTime', ...
        'time_s must be increasing.');
    win = max(3, round(prm.dhdt_window_s / dt));
    depthSmooth = movmean(depth_m, win, 'omitnan', 'Endpoints', 'shrink');
    dhdt = gradient(depthSmooth, time_s);
    D_ref = -dhdt ./ depthSmooth;

    % --- Divergence field of the (interpolation-free) velocity -----------
    pivUse = piv;
    if prm.exclude_interpolated && isfield(piv, 'typevector') && ~isempty(piv.typevector)
        pivUse.u = iMaskInterpolated(piv.u, piv.typevector);
        pivUse.v = iMaskInterpolated(piv.v, piv.typevector);
    end
    div = compute_divergence_field(pivUse, 'smooth_sigma', prm.smooth_sigma, ...
        'return_field', true, 'log_every', prm.log_every);
    assert(size(div.D, 3) == nFrames, 'compute_divergence_sign:FrameMismatch', ...
        'piv has %d frames but depth_m has %d.', size(div.D, 3), nFrames);

    % --- Static analysis mask ---------------------------------------------
    [Ny, Nx] = size(div.x);
    keep = true(Ny, Nx);
    m = prm.edge_margin_cells;
    if m > 0
        keep([1:m, Ny - m + 1:Ny], :) = false;
        keep(:, [1:m, Nx - m + 1:Nx]) = false;
    end
    yc = prm.port_center_y_m;
    if isnan(yc)
        yc = (min(div.y(:)) + max(div.y(:))) / 2;
    end
    nearPort = hypot(div.x - prm.port_wall_x_m, div.y - yc) < prm.port_mask_radius_m;
    keep(nearPort) = false;

    % --- Per-frame statistics ---------------------------------------------
    n_valid = zeros(nFrames, 1);
    Dp_mean = NaN(nFrames, 1);
    f_up = NaN(nFrames, 1);
    f_down = NaN(nFrames, 1);
    f_undet = NaN(nFrames, 1);
    for k = 1:nFrames
        Dp = div.D(:, :, k) - D_ref(k);
        Dp = Dp(keep & isfinite(Dp));
        n = numel(Dp);
        n_valid(k) = n;
        if n == 0 || ~isfinite(D_ref(k)), continue; end
        Dp_mean(k) = mean(Dp);
        f_up(k) = nnz(Dp > prm.D_noise_1_s) / n;
        f_down(k) = nnz(Dp < -prm.D_noise_1_s) / n;
        f_undet(k) = 1 - f_up(k) - f_down(k);
    end

    nWin = 1;
    if prm.avg_window_s > 0
        nWin = max(1, round(prm.avg_window_s / dt));
    end
    iWin = @(v) movmean(v, nWin, 'omitnan', 'Endpoints', 'shrink');

    run_id = repmat(iGetString(piv, 'run_id'), nFrames, 1);
    T = table(run_id, (1:nFrames).', time_s, depth_m, dhdt, D_ref, n_valid, ...
        Dp_mean, f_up, f_down, f_undet, ...
        iWin(Dp_mean), iWin(f_up), iWin(f_down), iWin(f_undet), ...
        'VariableNames', {'run_id', 'frame_idx', 'time_s', 'depth_m', ...
        'dhdt_m_s', 'D_ref_1_s', 'n_valid', 'Dp_mean_1_s', 'f_up', ...
        'f_down', 'f_undet', 'Dp_mean_1_s_win', 'f_up_win', 'f_down_win', ...
        'f_undet_win'});
end

% =========================================================================
function A = iMaskInterpolated(data, typevector)
% Replace PIVLab-interpolated vectors (typevector == 2) by NaN.
    if iscell(data)
        A = data;
        for k = 1:numel(data)
            tv = iSlice(typevector, k);
            a = double(data{k});
            a(tv == 2) = NaN;
            A{k} = a;
        end
    else
        A = double(data);
        tv = typevector;
        if iscell(tv)
            for k = 1:numel(tv)
                a = A(:, :, k);
                a(tv{k} == 2) = NaN;
                A(:, :, k) = a;
            end
        else
            A(tv == 2) = NaN;
        end
    end
end

function a = iSlice(data, k)
    if iscell(data)
        a = data{k};
    elseif ndims(data) >= 3
        a = data(:, :, k);
    else
        a = data;
    end
end

function s = iGetString(S, fieldName)
    if isfield(S, fieldName)
        s = string(S.(fieldName));
    else
        s = "";
    end
end

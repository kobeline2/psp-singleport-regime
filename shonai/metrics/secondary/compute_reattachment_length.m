function [T, info] = compute_reattachment_length(piv, varargin)
%COMPUTE_REATTACHMENT_LENGTH Time series of the reattachment length R(t).
%
% Secondary, exploratory metric (NOT one of the fixed primary metrics).
% Intended for inflow runs only: the jet leaves the port, a recirculation
% gyre forms between the jet and a side wall, and the jet (or its edge)
% touches the side wall at the reattachment point.
%
% Definition
%   R = distance, measured along the side wall from the port wall, to the
%       first reattachment point.
%   Reattachment point = the first point, going downstream from the port
%       wall (x increasing), where the wall-parallel velocity u measured
%       in the cells next to the side wall changes sign from reverse
%       (u < 0, flow back toward the port wall inside the gyre) to
%       forward (u > 0, flow away from the port wall). The zero crossing is
%       located by linear interpolation. This is the usual velocity-based
%       reattachment criterion of the backward-facing-step literature,
%       applied to the surface velocity next to the wall; it is NOT the
%       dye-based R1 of Dufresne et al. (2010), although it measures the
%       same geometric quantity.
%   R/dB is returned too, with dB the lateral expansion width on each side
%       of the port, dB = (basin width - port width)/2 (Dufresne's DeltaB).
%
% Time dependence
%   R is defined for a time-averaged near-wall velocity, because the
%   instantaneous sign change is too noisy. u next to each wall is
%   averaged over a moving window of 'avg_window_s' seconds (centered,
%   shrinking at the ends) and the crossing is searched in every window
%   position, so R(t) follows the slow depth change of the run. With
%   avg_window_s = 0 the instantaneous (per-frame) field is used.
%   Report R against depth_m (from frame_metrics after s31).
%
% Walls and the attached side
%   Both side walls are examined (the grid rows with the smallest and the
%   largest piv.y), so the result does not depend on the orientation of
%   piv.y. For each wall R is NaN when no reverse->forward crossing
%   exists (no reattachment, or both ends of the wall still inside the
%   gyre); both are returned as R_ymin_m and R_ymax_m.
%
%   The wall the jet attaches to is decided FIRST, by a quantity that is
%   independent of R: the lateral position of the jet axis. With
%   side_mode = 'jet_axis' (default) the axis is the y at which the
%   window-averaged u, averaged over x in 'axis_x_range_m', is largest.
%   If the axis is more than 'axis_dead_band_m' above (below) the basin
%   centre line 'y_center_m', the attached wall is ymax (ymin); inside the
%   dead band the flow is treated as symmetric and R_side = "none".
%   R_m is the reattachment length of the attached wall only; R_other_m
%   is the crossing found on the opposite wall, recorded separately and not
%   mixed into R_m. R_side is the attached wall even when no crossing was
%   found on it (R_m = NaN). With side_mode = 'min' the older rule is used:
%   R_m is the shorter of R_ymin_m and R_ymax_m and R_side its wall.
%
% Assumptions (check on the first run you analyze)
%   - piv.x is in basin coordinates with x = 0 at the port wall and
%     increasing into the basin; piv.u is the +x component.
%   - The side walls are at the two ends of the piv.y range. The PIV grid
%     stops ~41-45 mm short of them (C.metrics.omega_*), so with
%     n_wall_rows = 2 the velocity is taken ~55 mm off the wall, not at
%     the wall. This is a surface-PIV proxy; the true wall-attachment
%     point is slightly different. The distance used is returned in info.
%
% Usage:
%   T = compute_reattachment_length(piv, 'dB_m', 0.926)
%   [T, info] = compute_reattachment_length(piv, 'avg_window_s', 30)
%
% Parameters:
%   time_s          [nFrames x 1] frame times. Default from piv.meta.dt_pair_s.
%   avg_window_s    Moving-average window [s]. Default 30. 0 = per frame.
%   n_wall_rows     Number of grid rows next to each wall averaged
%                   together. Default 2.
%   u_eps_m_s       |u| below this is treated as "no sign" (noise).
%                   Default 1e-3 m/s (~2x the measured PIV noise rms,
%                   sqrt(E_noise_floor) = 4.5e-4 m/s). Provisional.
%   min_run_cells   A reverse (or forward) segment must span at least this
%                   many consecutive cells to count. Default 2.
%   exclude_interpolated  If true (default) and piv.typevector exists,
%                   vectors flagged 2 (PIVLab-interpolated) are ignored.
%   dB_m            Expansion width for R/dB. Default NaN (R_over_dB = NaN).
%   side_mode       'jet_axis' (default) or 'min' (older rule, see Walls).
%   axis_x_range_m  [x1 x2] columns used for the jet axis. Default [0.6 1.0].
%   axis_dead_band_m  Axis within this distance of y_center_m = symmetric,
%                   no attached side. Default 0.05 m.
%   y_center_m      Basin centre line in piv.y coordinates. Default NaN =
%                   middle of the piv.y range.
%   x_max_m         Crossings are searched only for x <= x_max_m. Default 2.4 m.
%                   Near the far wall (x = 2.952 m) the surface flow turns
%                   along the side wall and gives a weak reverse -> forward
%                   sign change at x ~ 2.7 m that is NOT a reattachment
%                   (seen in R0009 on the wall opposite to the attached jet).
%                   Inf disables the limit.
%
% Output table T (one row per frame):
%   run_id, frame_idx, time_s, R_ymin_m, R_ymax_m, R_m, R_side, R_over_dB,
%   R_other_m, jet_axis_y_m
% Output struct info: x, y_rows_lo, y_rows_hi, n_window_frames, params.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addParameter('time_s', [], @isnumeric);
    p.addParameter('avg_window_s', 30, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('n_wall_rows', 2, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('u_eps_m_s', 1e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('min_run_cells', 2, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('exclude_interpolated', true, @(x) islogical(x) || isnumeric(x));
    p.addParameter('dB_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('side_mode', 'jet_axis', @(x) any(strcmp(x, {'jet_axis', 'min'})));
    p.addParameter('axis_x_range_m', [0.6 1.0], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('axis_dead_band_m', 0.05, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('y_center_m', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('x_max_m', 2.4, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.parse(piv, varargin{:});
    prm = p.Results;

    assert(isfield(piv, 'u') && isfield(piv, 'x') && isfield(piv, 'y'), ...
        'compute_reattachment_length:MissingFields', ...
        'piv must contain u, x and y.');

    [U, nFrames] = iStackFrames(piv.u, 'piv.u');
    [Ny, Nx, ~] = size(U);
    xGrid = iStaticGrid(piv.x, Ny, Nx, 'piv.x');
    yGrid = iStaticGrid(piv.y, Ny, Nx, 'piv.y');
    xv = xGrid(1, :).';
    assert(all(diff(xv) > 0), 'compute_reattachment_length:GridXNotMonotonic', ...
        'piv.x must increase along columns (x = 0 at the port wall).');

    if prm.exclude_interpolated && isfield(piv, 'typevector') && ~isempty(piv.typevector)
        TV = iStackFrames(piv.typevector, 'piv.typevector');
        U(TV == 2) = NaN;
    end

    time_s = prm.time_s(:);
    if isempty(time_s)
        dtPair = NaN;
        if isfield(piv, 'meta') && isfield(piv.meta, 'dt_pair_s')
            dtPair = piv.meta.dt_pair_s;
        end
        time_s = (0:nFrames - 1).' * dtPair;
    end
    assert(numel(time_s) == nFrames, 'compute_reattachment_length:TimeLength', ...
        'time_s has %d entries but piv has %d frames.', numel(time_s), nFrames);

    % Rows next to the two side walls, independent of the y orientation.
    yv = yGrid(:, 1);
    [~, order] = sort(yv);
    n = min(prm.n_wall_rows, floor(Ny / 2));
    rowsLo = order(1:n);          % wall at the smallest y
    rowsHi = order(end - n + 1:end);   % wall at the largest y

    uLo = squeeze(mean(U(rowsLo, :, :), 1, 'omitnan'));   % [Nx x nFrames]
    uHi = squeeze(mean(U(rowsHi, :, :), 1, 'omitnan'));
    if nFrames == 1
        uLo = uLo(:); uHi = uHi(:);
    end

    nWin = 1;
    dt = median(diff(time_s), 'omitnan');
    if prm.avg_window_s > 0 && isfinite(dt) && dt > 0
        nWin = max(1, round(prm.avg_window_s / dt));
    end
    if nWin > 1
        uLo = movmean(uLo, nWin, 2, 'omitnan', 'Endpoints', 'shrink');
        uHi = movmean(uHi, nWin, 2, 'omitnan', 'Endpoints', 'shrink');
    end

    R_ymin = NaN(nFrames, 1);
    R_ymax = NaN(nFrames, 1);
    inSearch = xv <= prm.x_max_m;   % exclude the far-wall turning region
    assert(nnz(inSearch) >= 2 * prm.min_run_cells, ...
        'compute_reattachment_length:SearchRange', ...
        'x_max_m = %g leaves too few grid columns to search.', prm.x_max_m);
    for k = 1:nFrames
        R_ymin(k) = iFirstReattachment(xv(inSearch), uLo(inSearch, k), prm.u_eps_m_s, prm.min_run_cells);
        R_ymax(k) = iFirstReattachment(xv(inSearch), uHi(inSearch, k), prm.u_eps_m_s, prm.min_run_cells);
    end

    % Jet axis: y of the largest window-averaged u, averaged over the axis columns.
    yCenter = prm.y_center_m;
    if isnan(yCenter), yCenter = (min(yv) + max(yv)) / 2; end
    axisCols = xv >= prm.axis_x_range_m(1) & xv <= prm.axis_x_range_m(2);
    assert(any(axisCols), 'compute_reattachment_length:AxisRange', ...
        'No grid column inside axis_x_range_m.');
    uAxis = squeeze(mean(U(:, axisCols, :), 2, 'omitnan'));   % [Ny x nFrames]
    if nFrames == 1, uAxis = uAxis(:); end
    if nWin > 1
        uAxis = movmean(uAxis, nWin, 2, 'omitnan', 'Endpoints', 'shrink');
    end
    [uMax, iMax] = max(uAxis, [], 1);
    jet_axis_y = yv(iMax);
    jet_axis_y(~isfinite(uMax)) = NaN;
    jet_axis_y = jet_axis_y(:);

    if strcmp(prm.side_mode, 'jet_axis')
        R_side = repmat("none", nFrames, 1);
        R_side(jet_axis_y - yCenter > prm.axis_dead_band_m) = "ymax";
        R_side(jet_axis_y - yCenter < -prm.axis_dead_band_m) = "ymin";
        R_m = NaN(nFrames, 1);
        R_other = NaN(nFrames, 1);
        isMin = R_side == "ymin";
        isMax = R_side == "ymax";
        R_m(isMin) = R_ymin(isMin);
        R_m(isMax) = R_ymax(isMax);
        R_other(isMin) = R_ymax(isMin);
        R_other(isMax) = R_ymin(isMax);
    else
        R_m = min([R_ymin, R_ymax], [], 2, 'omitnan');
        R_m(isnan(R_ymin) & isnan(R_ymax)) = NaN;
        R_side = repmat("none", nFrames, 1);
        R_side(~isnan(R_ymin) & (isnan(R_ymax) | R_ymin <= R_ymax)) = "ymin";
        R_side(~isnan(R_ymax) & (isnan(R_ymin) | R_ymax < R_ymin)) = "ymax";
        R_other = NaN(nFrames, 1);
    end

    run_id = repmat(iGetString(piv, 'run_id'), nFrames, 1);
    T = table(run_id, (1:nFrames).', time_s, R_ymin, R_ymax, R_m, R_side, R_m / prm.dB_m, ...
        R_other, jet_axis_y, ...
        'VariableNames', {'run_id', 'frame_idx', 'time_s', 'R_ymin_m', 'R_ymax_m', ...
        'R_m', 'R_side', 'R_over_dB', 'R_other_m', 'jet_axis_y_m'});

    info = struct();
    info.x = xv;
    info.y_rows_lo = yv(rowsLo);
    info.y_rows_hi = yv(rowsHi);
    info.n_window_frames = nWin;
    info.params = prm;
end

% =========================================================================
function R = iFirstReattachment(x, u, uEps, minRun)
% First reverse -> forward sign change of u along x. Cells with |u| <= uEps
% or NaN carry no sign and break runs; a reverse run followed by a forward
% run (each >= minRun cells) defines the crossing.
    s = zeros(size(u));
    s(u > uEps) = 1;
    s(u < -uEps) = -1;

    runStart = []; runEnd = []; runSign = [];
    n = numel(s);
    k = 1;
    while k <= n
        j = k;
        while j < n && s(j + 1) == s(k)
            j = j + 1;
        end
        if s(k) ~= 0 && (j - k + 1) >= minRun
            runStart(end + 1) = k; %#ok<AGROW>
            runEnd(end + 1) = j; %#ok<AGROW>
            runSign(end + 1) = s(k); %#ok<AGROW>
        end
        k = j + 1;
    end

    R = NaN;
    for r = 1:numel(runSign) - 1
        if runSign(r) == -1 && runSign(r + 1) == 1
            i1 = runEnd(r);
            i2 = runStart(r + 1);
            % Zero of the straight line between the last reverse cell and
            % the first forward cell.
            R = x(i1) - u(i1) * (x(i2) - x(i1)) / (u(i2) - u(i1));
            return;
        end
    end
end

function [A, nFrames] = iStackFrames(data, varName)
    if iscell(data)
        nFrames = numel(data);
        sz = size(data{1});
        A = NaN([sz, nFrames]);
        for k = 1:nFrames
            A(:, :, k) = double(data{k});
        end
    elseif isnumeric(data)
        A = double(data);
        nFrames = size(A, 3);
    else
        error('compute_reattachment_length:InvalidFieldType', ...
            '%s must be numeric or cell.', varName);
    end
end

function G = iStaticGrid(data, Ny, Nx, varName)
    if iscell(data), data = data{1}; end
    G = double(data);
    if ndims(G) > 2, G = G(:, :, 1); end
    assert(isequal(size(G), [Ny, Nx]), 'compute_reattachment_length:GridSize', ...
        '%s must be %d x %d.', varName, Ny, Nx);
end

function s = iGetString(S, fieldName)
    if isfield(S, fieldName)
        s = string(S.(fieldName));
    else
        s = "";
    end
end

function T = compute_frame_metrics_basic(piv, varargin)
%COMPUTE_FRAME_METRICS_BASIC Compute minimal frame-wise metrics from canonical PIV.
%
% Usage:
%   T = compute_frame_metrics_basic(piv)
%   T = compute_frame_metrics_basic(piv, 'low_speed_threshold_m_s', 0.02)
%
% Output columns:
%   run_id, source, variant, frame_idx, time_s,
%   n_total, n_valid, valid_fraction, typevector_nonzero_fraction,
%   mean_speed, rms_speed, E, phi_lv, E_left, E_right, I_asym,
%   low_speed_threshold_m_s,
%   depth_m, h_over_a, band_id
%
% Notes:
%   - This function intentionally computes only frame-wise metrics that can
%     be derived directly from pivlab_single.mat.
%   - depth_m, h_over_a, and band_id are included as placeholders so that a
%     later band-mapping step can extend the same table schema.

    p = inputParser;
    p.addRequired('piv', @isstruct);
    p.addParameter('low_speed_threshold_m_s', 0.02, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('log_every', 500, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.parse(piv, varargin{:});
    prm = p.Results;

    assert(isfield(piv, 'u') && isfield(piv, 'v'), ...
        'compute_frame_metrics_basic:MissingVelocity', ...
        'piv must contain fields u and v.');

    nFrames = iFrameCount(piv.u, 'piv.u');
    sampleU = iFrameSlice(piv.u, 1, nFrames, 'piv.u', false);
    sampleV = iFrameSlice(piv.v, 1, nFrames, 'piv.v', false);
    assert(isequal(size(sampleU), size(sampleV)), ...
        'compute_frame_metrics_basic:SizeMismatch', ...
        'piv.u and piv.v frame sizes must match.');

    nTotal = numel(sampleU);
    run_id = repmat(iGetStringField(piv, 'run_id', ""), nFrames, 1);
    source = repmat(iGetStringField(piv, 'source', ""), nFrames, 1);
    variant = repmat(iGetStringField(piv, 'variant', ""), nFrames, 1);

    frame_idx = (1:nFrames).';
    dt_pair_s = iGetDtPair(piv);
    if isfinite(dt_pair_s) && dt_pair_s > 0
        time_s = (frame_idx - 1) * dt_pair_s;
    else
        time_s = NaN(nFrames, 1);
    end

    n_total = repmat(nTotal, nFrames, 1);
    n_valid = NaN(nFrames, 1);
    valid_fraction = NaN(nFrames, 1);
    typevector_nonzero_fraction = NaN(nFrames, 1);
    mean_speed = NaN(nFrames, 1);
    rms_speed = NaN(nFrames, 1);
    E = NaN(nFrames, 1);
    phi_lv = NaN(nFrames, 1);
    E_left = NaN(nFrames, 1);
    E_right = NaN(nFrames, 1);
    I_asym = NaN(nFrames, 1);
    low_speed_threshold_m_s = repmat(prm.low_speed_threshold_m_s, nFrames, 1);

    % Placeholders for a later depth / band mapping stage.
    depth_m = NaN(nFrames, 1);
    h_over_a = NaN(nFrames, 1);
    band_id = strings(nFrames, 1);

    t0 = tic;
    for k = 1:nFrames
        U = iFrameSlice(piv.u, k, nFrames, 'piv.u', false);
        V = iFrameSlice(piv.v, k, nFrames, 'piv.v', false);

        assert(isequal(size(U), size(sampleU)) && isequal(size(V), size(sampleU)), ...
            'compute_frame_metrics_basic:FrameSizeMismatch', ...
            'Frame %d has a size inconsistent with frame 1.', k);

        valid = isfinite(U) & isfinite(V);
        n_valid(k) = nnz(valid);
        valid_fraction(k) = n_valid(k) / nTotal;

        if isfield(piv, 'typevector') && ~isempty(piv.typevector)
            TV = iFrameSlice(piv.typevector, k, nFrames, 'piv.typevector', true);
            assert(isequal(size(TV), size(sampleU)), ...
                'compute_frame_metrics_basic:TypevectorSizeMismatch', ...
                'piv.typevector frame %d does not match piv.u.', k);
            typevector_nonzero_fraction(k) = nnz(isfinite(TV) & TV ~= 0) / nTotal;
        end

        if n_valid(k) > 0
            speed2 = U(valid).^2 + V(valid).^2;
            speed = sqrt(speed2);

            mean_speed(k) = mean(speed);
            rms_speed(k) = sqrt(mean(speed2));
            E(k) = mean(speed2);

            if isfinite(prm.low_speed_threshold_m_s)
                phi_lv(k) = mean(speed < prm.low_speed_threshold_m_s);
            end

            X = iResolveFrameX(piv, k, nFrames, size(sampleU));
            xFinite = X(isfinite(X));
            if ~isempty(xFinite)
                xMid = 0.5 * (min(xFinite) + max(xFinite));
                leftMask = X < xMid;
                rightMask = X >= xMid;

                leftValid = valid & leftMask;
                rightValid = valid & rightMask;

                if any(leftValid(:))
                    E_left(k) = mean(U(leftValid).^2 + V(leftValid).^2);
                end
                if any(rightValid(:))
                    E_right(k) = mean(U(rightValid).^2 + V(rightValid).^2);
                end

                denom = E_left(k) + E_right(k);
                if isfinite(denom) && denom > 0
                    I_asym(k) = abs(E_left(k) - E_right(k)) / denom;
                end
            end
        end

        if mod(k, prm.log_every) == 0 || k == 1 || k == nFrames
            elapsed = toc(t0);
            rate = k / max(elapsed, eps);
            remain = (nFrames - k) / max(rate, eps);
            fprintf('[compute_frame_metrics_basic] Frame %d / %d (%.1f%%), elapsed %.1fs, ETA %.1fs\n', ...
                k, nFrames, 100 * k / nFrames, elapsed, remain);
        end
    end

    T = table(run_id, source, variant, frame_idx, time_s, ...
        n_total, n_valid, valid_fraction, typevector_nonzero_fraction, ...
        mean_speed, rms_speed, E, phi_lv, E_left, E_right, I_asym, ...
        low_speed_threshold_m_s, depth_m, h_over_a, band_id);
end

function value = iGetStringField(S, fieldName, defaultValue)
    if isfield(S, fieldName)
        value = string(S.(fieldName));
    else
        value = string(defaultValue);
    end
end

function dt = iGetDtPair(piv)
    dt = NaN;
    if isfield(piv, 'meta') && isstruct(piv.meta) && isfield(piv.meta, 'dt_pair_s')
        candidate = piv.meta.dt_pair_s;
        if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
            dt = double(candidate);
        end
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
            error('compute_frame_metrics_basic:InvalidFieldSize', ...
                '%s must be 2-D, 3-D, or cell.', varName);
        end
    else
        error('compute_frame_metrics_basic:InvalidFieldType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
    end
end

function A = iFrameSlice(data, k, nFrames, varName, allowStatic2D)
    if iscell(data)
        assert(numel(data) == nFrames, ...
            'compute_frame_metrics_basic:InvalidCellLength', ...
            '%s must have %d cells.', varName, nFrames);
        A = data{k};
    elseif isnumeric(data)
        if ndims(data) <= 2
            if ~allowStatic2D && nFrames ~= 1
                error('compute_frame_metrics_basic:UnexpectedFrameCount', ...
                    '%s is 2-D but nFrames = %d.', varName, nFrames);
            end
            A = data;
        else
            A = data(:, :, k);
        end
    else
        error('compute_frame_metrics_basic:InvalidFieldType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
    end

    if ~isnumeric(A)
        error('compute_frame_metrics_basic:InvalidSliceType', ...
            '%s frame %d must be numeric.', varName, k);
    end
end

function X = iResolveFrameX(piv, k, nFrames, fieldSize)
    if isfield(piv, 'x') && ~isempty(piv.x)
        X = iFrameSlice(piv.x, k, nFrames, 'piv.x', true);
        assert(isequal(size(X), fieldSize), ...
            'compute_frame_metrics_basic:GridSizeMismatch', ...
            'piv.x frame %d must match piv.u.', k);
        return;
    end

    Nx = fieldSize(2);
    x = 1:Nx;
    X = repmat(x, fieldSize(1), 1);
end

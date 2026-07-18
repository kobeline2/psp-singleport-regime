function fields = compute_band_mean_field(piv, band_id, bands)
%COMPUTE_BAND_MEAN_FIELD Time-mean velocity field within each depth band.
%
% fields = compute_band_mean_field(piv, band_id, bands)
%
% Averages the PIV velocity field over the frames that fall in each depth
% band. Time-averaging suppresses random PIV noise by ~1/sqrt(N), so a weak
% but coherent mean structure (e.g. the outflow single-cell circulation)
% emerges even when the instantaneous fields are near the noise floor.
%
% Inputs:
%   piv     : canonical PIV struct. piv.u, piv.v are [Ny x Nx x nFrames]
%             (numeric) or nFrames-long cell arrays; piv.x, piv.y are the
%             static grids [Ny x Nx].
%   band_id : [nFrames x 1] string, the band label of each frame (from
%             frame_metrics after s31; "" = unassigned).
%   bands   : table from metadata/depth_bands.csv (band_id ordered
%             shallow -> deep).
%
% Output: struct array, one element per band, with fields:
%   band_id  : band label
%   n_frames : number of frames averaged
%   Ubar,Vbar: [Ny x Nx] time-mean velocity components (NaN where no data)
%   speed    : [Ny x Nx] hypot(Ubar,Vbar)
%   x, y     : [Ny x Nx] static grids (copied through for plotting)

    band_id = string(band_id(:));

    [U, nFrames] = iStackFrames(piv.u, 'piv.u');
    [V, nFrames2] = iStackFrames(piv.v, 'piv.v');
    assert(nFrames == nFrames2, ...
        'compute_band_mean_field:FrameMismatch', ...
        'piv.u and piv.v have different frame counts (%d vs %d).', nFrames, nFrames2);
    assert(numel(band_id) == nFrames, ...
        'compute_band_mean_field:BandLengthMismatch', ...
        'band_id has %d entries but piv has %d frames.', numel(band_id), nFrames);

    [Ny, Nx, ~] = size(U);
    x = iStaticGrid(piv, 'x', Ny, Nx);
    y = iStaticGrid(piv, 'y', Ny, Nx);

    nB = height(bands);
    fields = struct('band_id', cell(1, nB), 'n_frames', [], ...
        'Ubar', [], 'Vbar', [], 'speed', [], 'x', [], 'y', []);

    for b = 1:nB
        bid = string(bands.band_id(b));
        idx = find(band_id == bid);

        fields(b).band_id = bid;
        fields(b).n_frames = numel(idx);
        fields(b).x = x;
        fields(b).y = y;

        if isempty(idx)
            fields(b).Ubar = NaN(Ny, Nx);
            fields(b).Vbar = NaN(Ny, Nx);
            fields(b).speed = NaN(Ny, Nx);
            continue;
        end

        Ubar = mean(U(:, :, idx), 3, 'omitnan');
        Vbar = mean(V(:, :, idx), 3, 'omitnan');
        fields(b).Ubar = Ubar;
        fields(b).Vbar = Vbar;
        fields(b).speed = hypot(Ubar, Vbar);
    end
end

% =========================================================================
function [A, nFrames] = iStackFrames(data, varName)
    if isnumeric(data)
        if ndims(data) == 3
            A = double(data);
            nFrames = size(data, 3);
        elseif ismatrix(data)
            A = double(data);
            nFrames = 1;
        else
            error('compute_band_mean_field:BadDims', '%s must be 2-D or 3-D.', varName);
        end
    elseif iscell(data)
        nFrames = numel(data);
        firstIdx = find(~cellfun(@isempty, data(:)), 1, 'first');
        assert(~isempty(firstIdx), 'compute_band_mean_field:EmptyField', ...
            '%s contains only empty cells.', varName);
        [Ny, Nx] = size(data{firstIdx});
        A = NaN(Ny, Nx, nFrames);
        for k = 1:nFrames
            if ~isempty(data{k})
                A(:, :, k) = double(data{k});
            end
        end
    else
        error('compute_band_mean_field:BadType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
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

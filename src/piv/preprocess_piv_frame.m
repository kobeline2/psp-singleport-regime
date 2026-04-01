function J = preprocess_piv_frame(I, opts)
%PREPROCESS_PIV_FRAME Lightweight preprocessing for surface-PIV frames.
%
% J = preprocess_piv_frame(I, opts)
%
% Recommended default order:
%   1) convert to grayscale
%   2) illumination flattening
%   3) percentile clipping + normalization
%   4) optional inversion (to make tracers bright)
%   5) optional CLAHE / median filter

    if nargin < 2
        opts = struct();
    end
    opts = iDefaults(opts);

    if size(I,3) == 3
        I = rgb2gray(I);
    end
    I = im2single(I);

    switch lower(opts.flatfield_mode)
        case 'divide'
            bg = imgaussfilt(I, opts.flat_sigma_px);
            J = I ./ max(bg, eps('single'));
        case 'subtract'
            bg = imgaussfilt(I, opts.flat_sigma_px);
            J = bg - I;
        case 'none'
            J = I;
        otherwise
            error('preprocess_piv_frame:BadMode', ...
                'Unknown flatfield_mode: %s', opts.flatfield_mode);
    end

    clipVals = prctile(J(:), opts.clip_prctile);
    lo = clipVals(1);
    hi = clipVals(2);
    if hi <= lo
        hi = lo + eps('single');
    end
    J = min(max(J, lo), hi);
    J = (J - lo) ./ (hi - lo);

    if opts.invert
        J = 1 - J;
    end

    if opts.do_clahe
        J = adapthisteq(J, ...
            'ClipLimit', opts.clahe_cliplimit, ...
            'NumTiles', opts.clahe_numtiles);
    end

    if opts.do_median
        J = medfilt2(J, [opts.median_ksize opts.median_ksize]);
    end

    switch lower(opts.output_class)
        case 'single'
            % leave as is
        case 'uint8'
            J = im2uint8(J);
        case 'uint16'
            J = im2uint16(J);
        otherwise
            error('preprocess_piv_frame:BadOutputClass', ...
                'Unknown output_class: %s', opts.output_class);
    end
end

function opts = iDefaults(opts)
    if ~isfield(opts, 'flatfield_mode');   opts.flatfield_mode = 'divide'; end
    if ~isfield(opts, 'flat_sigma_px');    opts.flat_sigma_px = 30; end
    if ~isfield(opts, 'clip_prctile');     opts.clip_prctile = [1 99]; end
    if ~isfield(opts, 'invert');           opts.invert = true; end
    if ~isfield(opts, 'do_clahe');         opts.do_clahe = false; end
    if ~isfield(opts, 'clahe_cliplimit');  opts.clahe_cliplimit = 0.01; end
    if ~isfield(opts, 'clahe_numtiles');   opts.clahe_numtiles = [8 8]; end
    if ~isfield(opts, 'do_median');        opts.do_median = false; end
    if ~isfield(opts, 'median_ksize');     opts.median_ksize = 3; end
    if ~isfield(opts, 'output_class');     opts.output_class = 'uint16'; end
end

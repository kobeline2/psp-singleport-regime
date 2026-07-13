function [tracerImg, mask, opts] = extract_red_tracer(I, opts)
%EXTRACT_RED_TRACER Isolate a red dye/thread tracer from an RGB frame.
%
% [tracerImg, mask, opts] = extract_red_tracer(I, opts)
%
% Computes a "redness" map from an RGB frame so that a red tracer (dye or
% thread) stands out against a neutral background, then contrast-stretches
% it and optionally thresholds it into a binary mask.
%
% By default redness is R - (G+B)/2, not the raw R channel, because a
% bright/gray background (or a glare spot) already has a high R value; a
% neutral-color region has R roughly equal to G and B, so subtracting the
% other channels cancels that common brightness and leaves mostly the
% actual red tracer. Set opts.channel_mode = 'r' to use the plain R
% channel instead if preferred.
%
% Thresholding defaults to a locally adaptive threshold (adaptthresh),
% not a single global level. A washed-out / strongly backlit frame still
% has a slow large-scale brightness gradient left over in the redness map
% (glare, vignetting), and a global threshold (e.g. Otsu) ends up splitting
% the frame along that gradient instead of picking out the tracer. Set
% opts.threshold_mode = 'global' to fall back to a single Otsu/manual level.
%
% After thresholding, small specks are dropped (opts.min_area_px), a thin
% strip along the image border is excluded (opts.border_margin_frac, since
% raw uncropped photos often carry lens-shading/vignette artifacts right at
% the edge), and by default only the single largest remaining connected
% component is kept (opts.select_largest), since a single tracer thread is
% expected to form one elongated blob. Set opts.select_largest = false to
% keep every blob above opts.min_area_px instead (e.g. for multiple markers).
%
% Inputs
%   I    : HxWx3 RGB image (any numeric class; converted to single internally)
%   opts : optional struct, see iDefaults() below for fields and defaults
%
% Outputs
%   tracerImg : HxW single image in [0,1], contrast-stretched redness map
%   mask      : HxW logical mask of candidate tracer pixels ([] if
%               opts.do_threshold is false)
%   opts      : opts struct actually used (defaults filled in), for logging
%
% Example
%   I = imread('sample_thread.jpg');
%   [tracerImg, mask] = extract_red_tracer(I);
%   figure; imshowpair(I, tracerImg, 'montage');
%   figure; imshow(mask);

    if nargin < 2
        opts = struct();
    end
    opts = iDefaults(opts);

    if size(I,3) ~= 3
        error('extract_red_tracer:NeedRGB', 'Input image must be RGB (HxWx3).');
    end
    [H, W, ~] = size(I);
    I = im2single(I);
    R = I(:,:,1);
    G = I(:,:,2);
    B = I(:,:,3);

    switch lower(opts.channel_mode)
        case 'r'
            redness = R;
        case 'r_minus_gray'
            redness = R - rgb2gray(I);
        case 'r_minus_gb'
            redness = R - (G + B) / 2;
        otherwise
            error('extract_red_tracer:BadMode', ...
                'Unknown channel_mode: %s', opts.channel_mode);
    end
    redness = max(redness, 0);

    if opts.smooth_sigma_px > 0
        % Real photos carry per-pixel chroma/JPEG noise that gets amplified
        % by the contrast stretch below; a small blur (well under the
        % tracer's own width) removes that speckle without eroding the
        % tracer shape.
        redness = imgaussfilt(redness, opts.smooth_sigma_px);
    end

    clipVals = prctile(redness(:), opts.clip_prctile);
    lo = clipVals(1);
    hi = clipVals(2);
    if hi <= lo
        hi = lo + eps('single');
    end
    tracerImg = min(max(redness, lo), hi);
    tracerImg = (tracerImg - lo) ./ (hi - lo);

    if opts.do_threshold
        switch lower(opts.threshold_mode)
            case 'adaptive'
                T = adaptthresh(tracerImg, opts.adapt_sensitivity, ...
                    'ForegroundPolarity', 'bright');
                mask = imbinarize(tracerImg, T);
            case 'global'
                if isempty(opts.threshold)
                    level = graythresh(tracerImg);
                else
                    level = opts.threshold;
                end
                mask = imbinarize(tracerImg, level);
            otherwise
                error('extract_red_tracer:BadThresholdMode', ...
                    'Unknown threshold_mode: %s', opts.threshold_mode);
        end
        if opts.min_area_px > 0
            mask = bwareaopen(mask, opts.min_area_px);
        end

        marginPx = round(opts.border_margin_frac * max(H, W));
        if marginPx > 0
            borderMask = false(H, W);
            rows = (marginPx+1):(H-marginPx);
            cols = (marginPx+1):(W-marginPx);
            borderMask(rows, cols) = true;
            mask = mask & borderMask;
        end

        if opts.select_largest
            mask = bwareafilt(mask, 1);
        end
    else
        mask = [];
    end
end

function opts = iDefaults(opts)
    if ~isfield(opts, 'channel_mode');        opts.channel_mode = 'r_minus_gb'; end
    if ~isfield(opts, 'smooth_sigma_px');     opts.smooth_sigma_px = 4; end
    if ~isfield(opts, 'clip_prctile');        opts.clip_prctile = [1 99]; end
    if ~isfield(opts, 'do_threshold');        opts.do_threshold = true; end
    if ~isfield(opts, 'threshold_mode');      opts.threshold_mode = 'adaptive'; end
    if ~isfield(opts, 'adapt_sensitivity');   opts.adapt_sensitivity = 0.5; end
    if ~isfield(opts, 'threshold');           opts.threshold = []; end
    if ~isfield(opts, 'min_area_px');         opts.min_area_px = 20; end
    if ~isfield(opts, 'border_margin_frac');  opts.border_margin_frac = 0.01; end
    if ~isfield(opts, 'select_largest');      opts.select_largest = true; end
end

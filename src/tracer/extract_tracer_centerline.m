function [centerlineMask, xy] = extract_tracer_centerline(mask, opts)
%EXTRACT_TRACER_CENTERLINE Skeletonize a tracer mask down to a 1px centerline.
%
% [centerlineMask, xy] = extract_tracer_centerline(mask, opts)
%
% A tracer mask (e.g. from extract_red_tracer) has real width from blur,
% an out-of-focus/underwater image, or the thread's own thickness, but the
% tracer's true position is the ridge running through the middle of that
% blob, not its edge. This closes small gaps in the mask, takes its
% morphological skeleton (bwskel), and then keeps only the single longest
% path through that skeleton.
%
% A raw skeleton of a blob with a ragged boundary is not one clean curve:
% every small bump on the boundary sprouts its own short side-branch
% (visible as a "river delta" pattern), because bwskel's own MinBranchLength
% pruning cannot tell a boundary-noise spur from the real tracer path by
% length alone once the mask is wide. Since the tracer is a single curve
% from one end to the other, its centerline is the longest path across the
% skeleton graph, while boundary-noise spurs are short dead ends off of it;
% keeping only that longest path removes them without needing a length
% threshold tuned to the mask's width.
%
% Inputs
%   mask : HxW logical tracer mask
%   opts : optional struct
%     .close_radius_px    : imclose radius applied before skeletonizing, to
%                           bridge small gaps so the skeleton stays one
%                           connected curve (default 3)
%     .min_branch_len_px  : bwskel MinBranchLength; prunes the shortest
%                           skeleton spurs before the longest-path step
%                           (default 15)
%     .prune_to_main_path : keep only the single longest path through the
%                           skeleton (default true); set false to keep the
%                           raw (possibly branching) bwskel output
%
% Outputs
%   centerlineMask : HxW logical, 1-pixel-wide skeleton of mask
%   xy             : Nx2 [col row] pixel coordinates of the centerline
%                    (unordered; not necessarily sorted along the curve)
%
% Example
%   [tracerImg, mask] = extract_red_tracer(I);
%   centerlineMask = extract_tracer_centerline(mask);
%   overlay = imoverlay(im2uint8(rgb2gray(im2single(I))), mask, [1 0 0]);
%   overlay = imoverlay(overlay, imdilate(centerlineMask, strel('disk',2)), [1 1 0]);
%   figure; imshow(overlay);

    if nargin < 2
        opts = struct();
    end
    if ~isfield(opts, 'close_radius_px');    opts.close_radius_px = 3; end
    if ~isfield(opts, 'min_branch_len_px');  opts.min_branch_len_px = 15; end
    if ~isfield(opts, 'prune_to_main_path'); opts.prune_to_main_path = true; end

    m = mask;
    if opts.close_radius_px > 0
        m = imclose(m, strel('disk', opts.close_radius_px));
    end

    centerlineMask = bwskel(m, 'MinBranchLength', opts.min_branch_len_px);

    if opts.prune_to_main_path && nnz(centerlineMask) > 0
        centerlineMask = iPruneToLongestPath(centerlineMask);
    end

    [row, col] = find(centerlineMask);
    xy = [col, row];
end

function skel = iPruneToLongestPath(skel)
    % Two-pass geodesic-distance sweep (a standard skeleton-pruning trick):
    % from an arbitrary start pixel, the farthest reachable skeleton pixel
    % is one true end of the curve (A); the farthest pixel from A is the
    % other true end (B); the pixels lying exactly on a shortest path
    % between A and B are the main curve.
    idx0 = find(skel, 1, 'first');
    seed0 = false(size(skel));
    seed0(idx0) = true;
    D1 = bwdistgeodesic(skel, seed0);
    D1(isinf(D1)) = -1;
    [~, iA] = max(D1(:));
    seedA = false(size(skel));
    seedA(iA) = true;

    D2 = bwdistgeodesic(skel, seedA);
    D2(isinf(D2)) = -1;
    [~, iB] = max(D2(:));
    seedB = false(size(skel));
    seedB(iB) = true;

    D3 = bwdistgeodesic(skel, seedB);
    total = D2(iB);
    skel = skel & (abs(D2 + D3 - total) <= 1.5);
end

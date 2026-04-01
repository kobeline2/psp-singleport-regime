function manifest = prepare_piv_frames(videoPath, outDir, rectArg, opts)
%PREPARE_PIV_FRAMES Convert raw video to rectified/preprocessed TIFF frames.
%
% manifest = prepare_piv_frames(videoPath, outDir, rectArg, opts)
%
% Inputs:
%   videoPath : raw AVI/MP4 path
%   outDir    : destination directory for TIFF sequence
%   rectArg   : either
%       - path to a .mat file containing variable `rect`, or
%       - rect struct returned by select_rectification_points()
%   opts      : struct with optional fields
%       .start_frame    (default 1)
%       .end_frame      (default Inf)
%       .frame_step     (default 1)
%       .write_manifest (default true)
%       .file_prefix    (default 'img_')
%       .rectify_first  (default true)
%       .preprocess     (struct for preprocess_piv_frame)
%
% Output:
%   manifest : table with sequence index, source frame index, time, filename

    if nargin < 4
        opts = struct();
    end
    opts = iDefaults(opts);

    if ischar(rectArg) || isstring(rectArg)
        S = load(rectArg);
        if ~isfield(S, 'rect')
            error('prepare_piv_frames:MissingRect', ...
                'Rectification file does not contain variable "rect".');
        end
        rect = S.rect;
    elseif isstruct(rectArg)
        rect = rectArg;
    else
        error('prepare_piv_frames:BadRectArg', ...
            'rectArg must be a rect struct or a path to rectification .mat.');
    end

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    v = VideoReader(videoPath);
    nTotal = floor(v.Duration * v.FrameRate);
    startFrame = max(1, opts.start_frame);
    endFrame = min(opts.end_frame, nTotal);
    frameIdx = startFrame:opts.frame_step:endFrame;

    nOut = numel(frameIdx);
    seq_idx = zeros(nOut,1);
    source_frame_idx = zeros(nOut,1);
    time_s = zeros(nOut,1);
    file_name = strings(nOut,1);

    fprintf('[prepare_piv_frames] video: %s\n', videoPath);
    fprintf('[prepare_piv_frames] output: %s\n', outDir);
    fprintf('[prepare_piv_frames] frames: %d\n', nOut);

    for k = 1:nOut
        idx = frameIdx(k);
        I = read(v, idx);

        if opts.rectify_first
            I = imwarp(I, rect.tform, 'OutputView', rect.outputRef);
        end

        J = preprocess_piv_frame(I, opts.preprocess);

        fname = sprintf('%s%05d.tif', opts.file_prefix, k);
        fpath = fullfile(outDir, fname);
        imwrite(J, fpath, 'Compression', 'none');

        seq_idx(k) = k;
        source_frame_idx(k) = idx;
        time_s(k) = (idx - 1) / v.FrameRate;
        file_name(k) = fname;
    end

    manifest = table(seq_idx, source_frame_idx, time_s, file_name);

    if opts.write_manifest
        writetable(manifest, fullfile(outDir, 'frame_manifest.csv'));
    end

    save(fullfile(outDir, 'prepare_piv_frames_meta.mat'), 'videoPath', 'outDir', 'rect', 'opts');
    fprintf('[prepare_piv_frames] done.\n');
end

function opts = iDefaults(opts)
    if ~isfield(opts, 'start_frame');    opts.start_frame = 1; end
    if ~isfield(opts, 'end_frame');      opts.end_frame = Inf; end
    if ~isfield(opts, 'frame_step');     opts.frame_step = 1; end
    if ~isfield(opts, 'write_manifest'); opts.write_manifest = true; end
    if ~isfield(opts, 'file_prefix');    opts.file_prefix = 'img_'; end
    if ~isfield(opts, 'rectify_first');  opts.rectify_first = true; end
    if ~isfield(opts, 'preprocess');     opts.preprocess = struct(); end
end

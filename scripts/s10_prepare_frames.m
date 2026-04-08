clear; clc;
%% s10_prepare_frames.m
% Prepare rectified TIFF frames and optional PIVLab-ready image sequences
% for one run.
%
% This script intentionally combines the old "prepare assets" and
% "prepare frames" entry points into one simple driver.
%
% Daily-use settings should usually be changed in:
%   local/settings/s10_prepare_frames_local.m
% rather than by repeatedly editing this file.

init

%% ------------------------------------------ -------------------------------
% User settings
% -------------------------------------------------------------------------
% Run identifier defined in metadata/runs.csv
runID = "R0009";

% If true, open the interactive rectification tool and update the saved
% corner points. If false, reuse the existing rectification.mat file.
do_select_rectification = true;

% Video frame used when selecting the 4 rectification points.
rectification_frame_idx = 1;

% If true, also create a temporary renumbered TIFF sequence for PIVLab.
make_pivlab_tmp = false;

% Used only for naming the temporary PIVLab folder, for example
% tmp_pivlab_long or tmp_pivlab_short.
pivlab_variant = "5fps";

% Options passed to prepare_piv_frames().
% These settings control how the main rectified TIFF sequence is generated.
opts = struct();

% First raw-video frame to export.
opts.start_frame = 1;

% Last raw-video frame to export. Use Inf to process until the end.
opts.end_frame = Inf;

% Export every nth frame from the raw video.
opts.frame_step = 6;

% Prefix used for output TIFF names such as img_00001.tif.
opts.file_prefix = 'img_';

% If true, write frame_manifest.csv in the rectified_tif folder.
opts.write_manifest = true;

% Image preprocessing options applied before writing each TIFF frame.
opts.preprocess = struct();

% Flat-field correction mode:
%   'divide'   : divide by a blurred background image
%   'subtract' : subtract from a blurred background image
%   'none'     : no flat-field correction
opts.preprocess.flatfield_mode = 'divide';

% Gaussian blur size in pixels used to estimate the background image.
opts.preprocess.flat_sigma_px = 30;

% Clip grayscale values to these percentiles before normalization.
opts.preprocess.clip_prctile = [1 99];

% If true, invert intensity so particles appear bright.
opts.preprocess.invert = true;

% If true, apply CLAHE contrast enhancement.
opts.preprocess.do_clahe = false;

% If true, apply a median filter after normalization.
opts.preprocess.do_median = false;

% Output TIFF data type. Common choice: 'uint16'.
opts.preprocess.output_class = 'uint16';

% Options passed to make_pivlab_sequence().
% These settings control the temporary image folder prepared for PIVLab.
pivlab_opts = struct();

% First rectified TIFF index to use from rectified_tif/.
pivlab_opts.frame_start = 1;

% Last rectified TIFF index to use. Use Inf to include all remaining frames.
pivlab_opts.frame_end = Inf;

% Use every nth rectified TIFF when creating the temporary PIVLab sequence.
pivlab_opts.frame_step = 5;

% Starting number for output names, e.g. img_1000.tif.
pivlab_opts.start_index = 1000;

% Prefix used for the temporary PIVLab filenames.
pivlab_opts.prefix = 'img_';

% Number of digits used in the output numbering.
pivlab_opts.digits = 4;

% If true, overwrite an existing tmp_pivlab_* folder.
pivlab_opts.delete_existing = true;

% 'copy' keeps the original rectified TIFFs. 'move' relocates them.
pivlab_opts.copy_mode = 'copy';

% If true, write pivlab_sequence_manifest.csv in the temporary folder.
pivlab_opts.write_manifest = true;

% Optional gitignored local override script.
% Create local/settings/s10_prepare_frames_local.m and set only the values
% you want to change for the current run. For example:
%   runID = "R0012";
%   do_select_rectification = false;
%   opts.frame_step = 6;
%   pivlab_opts.frame_step = 5;
settingsFile = fullfile(cfg.DATA_ROOT, 'settings', 's10_prepare_frames_local.m');
if isfile(settingsFile)
    fprintf('[s10_prepare_frames] Loading local settings: %s\n', settingsFile);
    run(settingsFile);
end

% -------------------------------------------------------------------------
% Resolve run metadata and paths
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

videoPath = char(row.piv_video_path);
workRunDir = fullfile(cfg.WORK_DIR, char(runID));
frameDir = fullfile(workRunDir, cfg.RECTIFIED_TIF_DIR);
rectFile = fullfile(workRunDir, cfg.RECTIFICATION_FILE);

if ~exist(workRunDir, 'dir')
    mkdir(workRunDir);
end

%% -------------------------------------------------------------------------
% Step 1. Create or update rectification
% -------------------------------------------------------------------------
if do_select_rectification
    rect = select_rectification_points(videoPath, rectFile, ...
        'run_id', runID, ...
        'frame_idx', rectification_frame_idx, ...
        'Lx_m', C.basin.Lx_m, ...
        'Ly_m', C.basin.Ly_m, ...
        'pixel_size_m', 0.002, ...
        'operator', row.operator, ...
        'notes', "inner basin corners");
else
    assert(isfile(rectFile), ...
        'rectification.mat not found for %s. Set do_select_rectification = true first.', ...
        char(runID));
    S = load(rectFile, 'rect');
    rect = S.rect;
end

%% -------------------------------------------------------------------------
% Step 2. Generate rectified TIFF sequence
% -------------------------------------------------------------------------
manifest = prepare_piv_frames(videoPath, frameDir, rect, opts);

disp(manifest(1:min(5, height(manifest)), :));
fprintf('[s10_prepare_frames] Prepared %d TIFF frames for %s\n', height(manifest), char(runID));

%% -------------------------------------------------------------------------
% Step 3. Optionally create a temporary sequential TIFF folder for PIVLab
% -------------------------------------------------------------------------
if make_pivlab_tmp
    pivlabDir = fullfile(workRunDir, sprintf('tmp_pivlab_%s', char(pivlab_variant)));

    pivlabManifest = make_pivlab_sequence(frameDir, pivlabDir, ...
        'frame_start', pivlab_opts.frame_start, ...
        'frame_end', pivlab_opts.frame_end, ...
        'frame_step', pivlab_opts.frame_step, ...
        'start_index', pivlab_opts.start_index, ...
        'prefix', pivlab_opts.prefix, ...
        'digits', pivlab_opts.digits, ...
        'delete_existing', pivlab_opts.delete_existing, ...
        'copy_mode', pivlab_opts.copy_mode, ...
        'write_manifest', pivlab_opts.write_manifest);

    disp(pivlabManifest(1:min(5, height(pivlabManifest)), :));
    fprintf('[s10_prepare_frames] Prepared %d PIVLab files in %s\n', ...
        height(pivlabManifest), pivlabDir);
end

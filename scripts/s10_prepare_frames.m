clear; clc;
%% s10_prepare_frames.m
% Prepare rectified TIFF frames and optional PIVLab-ready image sequences
% for one run.
%
% This script intentionally combines the old "prepare assets" and
% "prepare frames" entry points into one simple driver.

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
do_select_rectification = true;
rectification_frame_idx = 1;
pivlab_variant = "long";

opts = struct();
opts.start_frame = 1;
opts.end_frame = Inf;
opts.frame_step = 1;
opts.file_prefix = 'img_';
opts.write_manifest = true;

opts.preprocess = struct();
opts.preprocess.flatfield_mode = 'divide';
opts.preprocess.flat_sigma_px = 30;
opts.preprocess.clip_prctile = [1 99];
opts.preprocess.invert = true;
opts.preprocess.do_clahe = false;
opts.preprocess.do_median = false;
opts.preprocess.output_class = 'uint16';

pivlab_opts = struct();
pivlab_opts.frame_start = 1;
pivlab_opts.frame_end = Inf;
pivlab_opts.frame_step = 5;
pivlab_opts.start_index = 1000;
pivlab_opts.prefix = 'img_';
pivlab_opts.digits = 4;
pivlab_opts.delete_existing = true;
pivlab_opts.copy_mode = 'copy';
pivlab_opts.write_manifest = true;

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

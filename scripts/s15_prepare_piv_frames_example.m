clear; clc;
%% s15_prepare_piv_frames_example.m
% Example driver for preparing rectified/preprocessed TIFF frames.

init

runID = "R0009";
T = read_runs_table();
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated.');

% -------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------
rawRunDir = fullfile(cfg.RAW_DIR, char(row.raw_subdir));
videoPath = fullfile(rawRunDir, char(row.piv_video_file));

rectDir  = fullfile(cfg.DERIVED_DIR, 'rectification', char(runID));
frameDir = fullfile(cfg.DERIVED_DIR, 'frames', char(runID), 'rectified_tif');
rectFile = fullfile(rectDir, 'rectification.mat');

if ~exist(rectDir, 'dir')
    mkdir(rectDir);
end
if ~exist(frameDir, 'dir')
    mkdir(frameDir);
end

%% ------------------------------------------------------------------------
% Step 1. Create rectification transform once
% -------------------------------------------------------------------------
% Uncomment on first use.
%
rect = select_rectification_points(videoPath, rectFile, ...
    'run_id', runID, ...
    'frame_idx', 1, ...
    'Lx_m', 3.0, ...
    'Ly_m', 2.0, ...
    'pixel_size_m', 0.002, ...
    'operator', "A", ...
    'notes', "inner basin corners");

%% ------------------------------------------------------------------------
% Step 2. Prepare TIFF sequence
% -------------------------------------------------------------------------
assert(isfile(rectFile), 'rectification.mat not found. Run Step 1 first.');

opts = struct();
opts.start_frame = 1;
opts.end_frame   = Inf;
opts.frame_step  = 1;
opts.file_prefix = 'img_';
opts.write_manifest = true;

opts.preprocess = struct();
opts.preprocess.flatfield_mode = 'divide';
opts.preprocess.flat_sigma_px  = 30;
opts.preprocess.clip_prctile   = [1 99];
opts.preprocess.invert         = true;
opts.preprocess.do_clahe       = false;
opts.preprocess.do_median      = false;
opts.preprocess.output_class   = 'uint16';

manifest = prepare_piv_frames(videoPath, frameDir, rectFile, opts);

disp(manifest(1:min(5,height(manifest)), :));
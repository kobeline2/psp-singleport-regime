function cfg = project_config_template()
%PROJECT_CONFIG_TEMPLATE Template for local project configuration.
% Copy this file to project_config_local.m and edit local paths there.

cfg = struct();

% -------------------------------------------------------------------------
% Project identity
% -------------------------------------------------------------------------
cfg.PROJECT_NAME = 'psp-singleport-regime';

% -------------------------------------------------------------------------
% Repository root
% -------------------------------------------------------------------------
cfg.REPO_ROOT = fileparts(fileparts(mfilename('fullpath')));

% -------------------------------------------------------------------------
% Local data root inside the repository.
% This directory is intended to be gitignored by default.
% Override in project_config_local.m only if needed.
% -------------------------------------------------------------------------
cfg.DATA_ROOT = fullfile(cfg.REPO_ROOT, 'local');

% -------------------------------------------------------------------------
% Repository-side folders
% -------------------------------------------------------------------------
cfg.CONFIG_DIR   = fullfile(cfg.REPO_ROOT, 'config');
cfg.METADATA_DIR = fullfile(cfg.REPO_ROOT, 'metadata');
cfg.SRC_DIR      = fullfile(cfg.REPO_ROOT, 'src');
cfg.SCRIPTS_DIR  = fullfile(cfg.REPO_ROOT, 'scripts');
cfg.DOCS_DIR     = fullfile(cfg.REPO_ROOT, 'docs');

% -------------------------------------------------------------------------
% Data-side folders
% -------------------------------------------------------------------------
cfg.RAW_DIR        = fullfile(cfg.DATA_ROOT, 'raw');
cfg.WORK_DIR       = fullfile(cfg.DATA_ROOT, 'work');
cfg.DERIVED_DIR    = fullfile(cfg.DATA_ROOT, 'derived');
cfg.RESULTS_ROOT   = fullfile(cfg.DATA_ROOT, 'results');

cfg.DERIVED_PIV_DIR     = fullfile(cfg.DERIVED_DIR, 'piv');
cfg.DERIVED_METRICS_DIR = fullfile(cfg.DERIVED_DIR, 'metrics');
cfg.DERIVED_QC_DIR      = fullfile(cfg.DERIVED_DIR, 'qc');
cfg.RECTIFIED_TIF_DIR = 'rectified_tif';
cfg.RECTIFICATION_FILE = 'rectification.mat';
cfg.PIVLAB_PROJ_DIR = 'pivlab_proj';
cfg.PIV_EXPORT_DIR = fullfile(cfg.WORK_DIR, 'exports');

cfg.RESULTS_FIG_DIR   = fullfile(cfg.RESULTS_ROOT, 'figures');
cfg.RESULTS_TABLE_DIR = fullfile(cfg.RESULTS_ROOT, 'tables');
cfg.RESULTS_DRAFT_DIR = fullfile(cfg.RESULTS_ROOT, 'drafts');

% -------------------------------------------------------------------------
% Metadata files
% -------------------------------------------------------------------------
cfg.RUNS_CSV        = fullfile(cfg.METADATA_DIR, 'runs.csv');
cfg.DEPTH_BANDS_CSV = fullfile(cfg.METADATA_DIR, 'depth_bands.csv');
cfg.FLOW_LEVELS_CSV = fullfile(cfg.METADATA_DIR, 'flow_levels.csv');

% -------------------------------------------------------------------------
% Standard filenames inside each raw run folder
% -------------------------------------------------------------------------
cfg.DEFAULT_PIV_VIDEO_FILE       = 'piv.mp4';
cfg.DEFAULT_TIMELAPSE_VIDEO_FILE = 'timelapse.mp4';
cfg.DEFAULT_WATERLEVEL_FILE      = 'waterlevel.csv';
cfg.DEFAULT_RUNLOG_FILE          = 'runlog.md';

% -------------------------------------------------------------------------
% Canonical output filenames inside each derived/piv/<run_id>/ folder
% -------------------------------------------------------------------------
cfg.PIV_SHORT_MAT  = 'piv_short.mat';
cfg.PIV_LONG_MAT   = 'piv_long.mat';
cfg.PIV_MERGED_MAT = 'piv_merged.mat';

% -------------------------------------------------------------------------
% Derived CSV outputs
% -------------------------------------------------------------------------
cfg.FRAME_METRICS_CSV = fullfile(cfg.DERIVED_METRICS_DIR, 'frame_metrics.csv');
cfg.BAND_METRICS_CSV  = fullfile(cfg.DERIVED_METRICS_DIR, 'band_metrics.csv');
cfg.RUN_SUMMARY_CSV   = fullfile(cfg.DERIVED_METRICS_DIR, 'run_summary.csv');
end

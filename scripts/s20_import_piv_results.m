clear; clc;
%% s20_import_piv_results.m
% Import PIV results for one run into the project's canonical MATLAB format.
%
% This script is intended to replace the older split entry points for
% short-dt, long-dt, asset import, and merge orchestration. The actual
% importer functions still need to be implemented under src/.

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";
source_name = "pivlab";   % e.g. "pivlab" or "external"
variant = "short";        % e.g. "short", "long", or "merged"

% Example location for an upstream PIV export. Adjust once the importer is
% implemented for the chosen software.
exportPath = fullfile(cfg.PIV_EXPORT_DIR, char(runID), char(source_name), char(variant));
outDir = fullfile(cfg.DERIVED_PIV_DIR, char(runID));

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

fprintf('[s20_import_piv_results] run_id  : %s\n', char(runID));
fprintf('[s20_import_piv_results] source  : %s\n', char(source_name));
fprintf('[s20_import_piv_results] variant : %s\n', char(variant));
fprintf('[s20_import_piv_results] export  : %s\n', exportPath);
fprintf('[s20_import_piv_results] output  : %s\n', outDir);

if source_name == "pivlab"
    pivlabDir = fullfile(cfg.WORK_DIR, char(runID), sprintf('tmp_pivlab_%s', char(variant)));
    projDir = fullfile(cfg.WORK_DIR, char(runID), cfg.PIVLAB_PROJ_DIR);

    fprintf('[s20_import_piv_results] pivlab temp folder : %s\n', pivlabDir);
    fprintf('[s20_import_piv_results] pivlab project dir : %s\n', projDir);
end

error(['s20_import_piv_results is a consolidated placeholder. ' ...
       'Next step: implement a canonical importer in src/ that reads the ' ...
       'upstream PIV export or PIVLab results, maps them to pivrun, and writes piv_short.mat, ' ...
       'piv_long.mat, or piv_merged.mat under derived/piv/<run_id>/.']);

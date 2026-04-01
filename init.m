function init()
%INIT Initialize the psp-singleport-regime project.
%
% Usage:
%   init
%
% Recommended:
%   Run this once after opening MATLAB in the repository root, or call it
%   explicitly from the command window.
%
% This file is project-local and is NOT intended to replace MATLAB's global
% startup.m behavior.

    fprintf('[init] Initializing project: psp-singleport-regime\n');

    % ---------------------------------------------------------------------
    % Locate project root
    % ---------------------------------------------------------------------
    thisFile = mfilename('fullpath');
    projectRoot = fileparts(thisFile);

    % ---------------------------------------------------------------------
    % Add project folders to MATLAB path
    % ---------------------------------------------------------------------
    addpath(projectRoot);
    addpath(fullfile(projectRoot, 'config'));
    addpath(fullfile(projectRoot, 'scripts'));

    srcDir = fullfile(projectRoot, 'src');
    if isfolder(srcDir)
        addpath(genpath(srcDir));
    end

    metadataDir = fullfile(projectRoot, 'metadata');
    if isfolder(metadataDir)
        addpath(metadataDir);
    end

    docsDir = fullfile(projectRoot, 'docs');
    if isfolder(docsDir)
        addpath(docsDir);
    end

    % ---------------------------------------------------------------------
    % Load configuration
    % ---------------------------------------------------------------------
    if exist('project_config_local', 'file') == 2
        cfg = project_config_local();
        fprintf('[init] Using local config: project_config_local.m\n');
    elseif exist('project_config_template', 'file') == 2
        cfg = project_config_template();
        fprintf('[init] Using template config: project_config_template.m\n');
        fprintf('[init] NOTE: Create project_config_local.m for machine-specific paths.\n');
    else
        error('[init] No project config file found.');
    end

    % ---------------------------------------------------------------------
    % Basic metadata checks
    % ---------------------------------------------------------------------
    requiredFiles = {
        fullfile(projectRoot, 'metadata', 'runs.csv')
        fullfile(projectRoot, 'metadata', 'depth_bands.csv')
        fullfile(projectRoot, 'metadata', 'flow_levels.csv')
    };

    for i = 1:numel(requiredFiles)
        if ~isfile(requiredFiles{i})
            warning('[init] Missing metadata file: %s', requiredFiles{i});
        end
    end

    % ---------------------------------------------------------------------
    % Expose config in base workspace for convenience
    % ---------------------------------------------------------------------
    assignin('base', 'cfg', cfg);

    if exist('constants', 'file') == 2
        C = constants();
        assignin('base', 'C', C);
        fprintf('[init] Loaded constants() into base workspace as C.\n');
    else
        warning('[init] constants.m not found.');
    end

    fprintf('[init] Project root: %s\n', projectRoot);
    fprintf('[init] Initialization complete.\n');
end
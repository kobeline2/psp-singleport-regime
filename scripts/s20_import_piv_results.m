clear; clc;
%% s20_import_piv_results.m
% Import one upstream PIV result into the project's canonical MATLAB format.
%
% Current scope:
%   - supports PIVLab MAT exports
%   - reads run timing info from piv_manifest.csv when available
%   - saves canonical output under local/work/<run_id>/

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
% Run identifier defined in metadata/runs.csv
runID = "R0009";

% Currently supported source: "pivlab"
source_name = "pivlab";

% Upstream PIVLab MAT file stored under local/work/<run_id>/.
% Store the raw PIVLab workspace dump as PIVlab_raw.mat.
% The importer reads only:
%   x, y, u_filtered, v_filtered, typevector_filtered,
%   calxy, calu, calv, units
export_file = "PIVlab_raw.mat";

% Optional manual provenance fields.
% If piv_manifest.csv contains matching columns for export_file, those
% values are used automatically unless you override them here.
source_video_fps_hz = NaN;
effective_sequence_fps_hz = NaN;
export_step_frames = NaN;
pair_step_frames = NaN;
dt_pair_s = NaN;
setting_file = "";
session_file = "";
preset_id = "";
VDP = "";
notes = "";

% -------------------------------------------------------------------------
% Resolve run metadata and paths
% -------------------------------------------------------------------------
T = read_runs_table(cfg);
row = T(T.run_id == runID, :);
assert(height(row) == 1, 'Run ID not found or duplicated: %s', char(runID));

workRunDir = fullfile(cfg.WORK_DIR, char(runID));
exportPath = fullfile(workRunDir, char(export_file));
manifestPath = fullfile(workRunDir, 'piv_manifest.csv');
outPath = fullfile(workRunDir, cfg.PIV_SINGLE_MAT);

fprintf('[s20_import_piv_results] run_id   : %s\n', char(runID));
fprintf('[s20_import_piv_results] source   : %s\n', char(source_name));
fprintf('[s20_import_piv_results] variant  : single_dt\n');
fprintf('[s20_import_piv_results] export   : %s\n', exportPath);
fprintf('[s20_import_piv_results] manifest : %s\n', manifestPath);
fprintf('[s20_import_piv_results] output   : %s\n', outPath);

assert(source_name == "pivlab", ...
    's20_import_piv_results currently supports source_name = "pivlab" only.');
assert(isfile(exportPath), 'PIV export MAT not found: %s', exportPath);

% -------------------------------------------------------------------------
% Fill timing / provenance metadata from piv_manifest.csv when available
% -------------------------------------------------------------------------
manifestRow = table();
if isfile(manifestPath)
    manifestRow = iReadMatchingManifestRow(manifestPath, export_file);

    source_video_fps_hz = iPickNumeric(source_video_fps_hz, manifestRow, "source_video_fps_hz");
    effective_sequence_fps_hz = iPickNumeric(effective_sequence_fps_hz, manifestRow, "effective_sequence_fps_hz");
    export_step_frames = iPickNumeric(export_step_frames, manifestRow, "export_step_frames");
    pair_step_frames = iPickNumeric(pair_step_frames, manifestRow, "pair_step_frames");
    dt_pair_s = iPickNumeric(dt_pair_s, manifestRow, "dt_pair_s");
    setting_file = iPickString(setting_file, manifestRow, "setting_file");
    session_file = iPickString(session_file, manifestRow, "session_file");
    notes = iPickString(notes, manifestRow, "notes");
end

% -------------------------------------------------------------------------
% Import and save canonical struct
% -------------------------------------------------------------------------
piv = import_pivlab_result(exportPath, ...
    'run_id', runID, ...
    'variant', "single_dt", ...
    'source_video_fps_hz', source_video_fps_hz, ...
    'effective_sequence_fps_hz', effective_sequence_fps_hz, ...
    'export_step_frames', export_step_frames, ...
    'pair_step_frames', pair_step_frames, ...
    'dt_pair_s', dt_pair_s, ...
    'preset_id', preset_id, ...
    'VDP', VDP, ...
    'notes', notes, ...
    'setting_file', setting_file, ...
    'export_file', export_file, ...
    'session_file', session_file);

save(outPath, 'piv', '-v7.3');

fprintf('[s20_import_piv_results] Saved canonical PIV struct: %s\n', outPath);
fprintf('[s20_import_piv_results] frame_count = %d\n', piv.meta.frame_count);

if isnumeric(piv.x) && ndims(piv.x) == 2
    fprintf('[s20_import_piv_results] grid       = %d x %d (static x/y)\n', ...
        size(piv.x, 1), size(piv.x, 2));
elseif isnumeric(piv.u) && ndims(piv.u) >= 3
    fprintf('[s20_import_piv_results] grid       = %d x %d x %d\n', ...
        size(piv.u, 1), size(piv.u, 2), size(piv.u, 3));
end

function row = iReadMatchingManifestRow(csvPath, exportFile)
    opts = detectImportOptions(csvPath, 'TextType', 'string');
    opts.PreserveVariableNames = true;
    M = readtable(csvPath, opts);

    if height(M) == 0 || ~ismember('export_file', M.Properties.VariableNames)
        row = table();
        return;
    end

    exportFiles = strip(string(M.export_file));
    exportFile = strip(string(exportFile));
    match = exportFiles == exportFile;

    if sum(match) == 1
        row = M(match, :);
    elseif height(M) == 1
        row = M(1, :);
        warning('s20_import_piv_results:ManifestFallback', ...
            ['piv_manifest.csv has one row but export_file did not match "%s". ' ...
             'Using the single manifest row.'], char(exportFile));
    elseif any(match)
        row = M(find(match, 1, 'first'), :); %#ok<FNDSB>
        warning('s20_import_piv_results:ManifestDuplicate', ...
            'Multiple manifest rows matched export_file "%s". Using the first one.', ...
            char(exportFile));
    else
        row = table();
        warning('s20_import_piv_results:ManifestNoMatch', ...
            'No piv_manifest.csv row matched export_file "%s". Using manual settings only.', ...
            char(exportFile));
    end
end

function value = iPickNumeric(currentValue, row, varName)
    value = currentValue;
    if ~isnan(currentValue) || isempty(row) || ~ismember(varName, row.Properties.VariableNames)
        return;
    end

    candidate = row.(varName)(1);
    if isnumeric(candidate) && isscalar(candidate)
        value = double(candidate);
    end
end

function value = iPickString(currentValue, row, varName)
    value = string(currentValue);
    if strlength(value) > 0 || isempty(row) || ~ismember(varName, row.Properties.VariableNames)
        return;
    end

    candidate = string(row.(varName)(1));
    if ~ismissing(candidate)
        value = strip(candidate);
    end
end

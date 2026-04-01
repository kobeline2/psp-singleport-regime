function T = read_runs_table(arg)
%READ_RUNS_TABLE Read and validate metadata/runs.csv.
%
% Usage:
%   T = read_runs_table()
%   T = read_runs_table(cfg)
%   T = read_runs_table(csvPath)
%
% Input:
%   arg : optional
%       - omitted   : use project_config_local() if available, otherwise
%                     project_config_template()
%       - struct    : project config struct with field RUNS_CSV
%       - char/str  : direct path to runs.csv
%
% Output:
%   T : table
%       Validated run metadata table. If cfg is available, convenience path
%       columns are also added.
%
% Notes:
%   - This function keeps metadata in table form and does not attempt to
%     infer analysis results.
%   - File existence of raw assets is not enforced here. That should be
%     checked in a separate import / QC step.

    cfg = struct();
    runsCsv = "";

    if nargin < 1 || isempty(arg)
        cfg = iLoadProjectConfig();
        runsCsv = string(cfg.RUNS_CSV);

    elseif isstruct(arg)
        cfg = arg;
        if ~isfield(cfg, 'RUNS_CSV')
            error('read_runs_table:MissingField', ...
                'Input config struct must contain field RUNS_CSV.');
        end
        runsCsv = string(cfg.RUNS_CSV);

    elseif ischar(arg) || isstring(arg)
        runsCsv = string(arg);

    else
        error('read_runs_table:InvalidInput', ...
            'Input must be empty, a config struct, or a CSV path.');
    end

    if strlength(runsCsv) == 0 || ~isfile(runsCsv)
        error('read_runs_table:FileNotFound', ...
            'runs.csv not found: %s', char(runsCsv));
    end

    % ---------------------------------------------------------------------
    % Read table
    % ---------------------------------------------------------------------
    opts = detectImportOptions(runsCsv, 'TextType', 'string');
    opts.PreserveVariableNames = true;
    T = readtable(runsCsv, opts);

    % ---------------------------------------------------------------------
    % Required columns
    % ---------------------------------------------------------------------
    requiredVars = [
        "run_id"
        "planned_order"
        "date"
        "operator"
        "mode"
        "flow_level"
        "nominal_dh_mm_min"
        "nominal_Q_Lps"
        "repetition"
        "start_depth_m"
        "end_depth_m"
        "raw_subdir"
        "piv_video_file"
        "timelapse_video_file"
        "waterlevel_file"
        "runlog_file"
        "piv_source"
        "run_status"
        "notes"
        "exclude_flag"
    ];

    missingVars = setdiff(requiredVars, string(T.Properties.VariableNames));
    if ~isempty(missingVars)
        error('read_runs_table:MissingColumns', ...
            'runs.csv is missing required columns: %s', ...
            strjoin(cellstr(missingVars), ', '));
    end

    % ---------------------------------------------------------------------
    % Normalize text columns
    % ---------------------------------------------------------------------
    textVars = [
        "run_id"
        "date"
        "operator"
        "mode"
        "flow_level"
        "raw_subdir"
        "piv_video_file"
        "timelapse_video_file"
        "waterlevel_file"
        "runlog_file"
        "piv_source"
        "run_status"
        "notes"
    ];

    for i = 1:numel(textVars)
        vn = textVars(i);
        T.(vn) = iAsStringColumn(T.(vn));
    end

    % Trim and normalize selected columns
    T.run_id     = strip(T.run_id);
    T.mode       = lower(strip(T.mode));
    T.flow_level = lower(strip(T.flow_level));
    T.piv_source = lower(strip(T.piv_source));
    T.run_status = lower(strip(T.run_status));
    T.raw_subdir = strip(T.raw_subdir);

    % ---------------------------------------------------------------------
    % Numeric columns
    % ---------------------------------------------------------------------
    numericVars = [
        "planned_order"
        "nominal_dh_mm_min"
        "nominal_Q_Lps"
        "repetition"
        "start_depth_m"
        "end_depth_m"
    ];

    for i = 1:numel(numericVars)
        vn = numericVars(i);
        T.(vn) = iAsDoubleColumn(T.(vn), vn);
    end

    % ---------------------------------------------------------------------
    % Logical column
    % ---------------------------------------------------------------------
    T.exclude_flag = iAsLogicalColumn(T.exclude_flag, "exclude_flag");

    % ---------------------------------------------------------------------
    % Basic validation
    % ---------------------------------------------------------------------
    if any(ismissing(T.run_id) | strlength(T.run_id) == 0)
        error('read_runs_table:EmptyRunID', ...
            'Column run_id contains empty values.');
    end

    if numel(unique(T.run_id)) ~= height(T)
        error('read_runs_table:DuplicateRunID', ...
            'Column run_id must contain unique values.');
    end

    allowedModes = ["inflow", "outflow"];
    badMode = ~ismember(T.mode, allowedModes);
    if any(badMode)
        error('read_runs_table:InvalidMode', ...
            'Invalid mode values found: %s', ...
            strjoin(unique(cellstr(T.mode(badMode))), ', '));
    end

    allowedFlowLevels = ["low", "medium", "high"];
    badFlow = ~ismember(T.flow_level, allowedFlowLevels);
    if any(badFlow)
        error('read_runs_table:InvalidFlowLevel', ...
            'Invalid flow_level values found: %s', ...
            strjoin(unique(cellstr(T.flow_level(badFlow))), ', '));
    end

    if any(T.nominal_dh_mm_min <= 0 | isnan(T.nominal_dh_mm_min))
        error('read_runs_table:InvalidNominalDh', ...
            'nominal_dh_mm_min must be positive and finite.');
    end

    if any(T.nominal_Q_Lps <= 0 | isnan(T.nominal_Q_Lps))
        error('read_runs_table:InvalidNominalQ', ...
            'nominal_Q_Lps must be positive and finite.');
    end

    if any(T.repetition <= 0 | isnan(T.repetition))
        error('read_runs_table:InvalidRepetition', ...
            'repetition must be positive and finite.');
    end

    badInflow = (T.mode == "inflow") & (T.start_depth_m >= T.end_depth_m);
    if any(badInflow)
        error('read_runs_table:InflowDepthOrder', ...
            'Inflow runs must satisfy start_depth_m < end_depth_m. Bad run(s): %s', ...
            strjoin(cellstr(T.run_id(badInflow)), ', '));
    end

    badOutflow = (T.mode == "outflow") & (T.start_depth_m <= T.end_depth_m);
    if any(badOutflow)
        error('read_runs_table:OutflowDepthOrder', ...
            'Outflow runs must satisfy start_depth_m > end_depth_m. Bad run(s): %s', ...
            strjoin(cellstr(T.run_id(badOutflow)), ', '));
    end

    % ---------------------------------------------------------------------
    % Derived convenience columns
    % ---------------------------------------------------------------------
    T.depth_span_m = abs(T.end_depth_m - T.start_depth_m);
    T.nominal_duration_min = 1000 * T.depth_span_m ./ T.nominal_dh_mm_min;

    % ---------------------------------------------------------------------
    % Add convenience path columns if config is available
    % ---------------------------------------------------------------------
    if ~isempty(fieldnames(cfg)) && isfield(cfg, 'RAW_DIR')
        n = height(T);

        T.raw_dir = strings(n,1);
        T.piv_video_path = strings(n,1);
        T.timelapse_video_path = strings(n,1);
        T.waterlevel_path = strings(n,1);
        T.runlog_path = strings(n,1);

        for i = 1:n
            rawDir = string(fullfile(char(cfg.RAW_DIR), char(T.raw_subdir(i))));
            T.raw_dir(i) = rawDir;
            T.piv_video_path(i) = string(fullfile(char(rawDir), char(T.piv_video_file(i))));
            T.timelapse_video_path(i) = string(fullfile(char(rawDir), char(T.timelapse_video_file(i))));
            T.waterlevel_path(i) = string(fullfile(char(rawDir), char(T.waterlevel_file(i))));
            T.runlog_path(i) = string(fullfile(char(rawDir), char(T.runlog_file(i))));
        end
    end

    % ---------------------------------------------------------------------
    % Sort by planned order if available
    % ---------------------------------------------------------------------
    if all(~isnan(T.planned_order))
        T = sortrows(T, 'planned_order');
    end
end

% =========================================================================
% Local helpers
% =========================================================================
function cfg = iLoadProjectConfig()
    if exist('project_config_local', 'file') == 2
        cfg = project_config_local();
    elseif exist('project_config_template', 'file') == 2
        cfg = project_config_template();
    else
        error('read_runs_table:NoConfig', ...
            'Neither project_config_local.m nor project_config_template.m was found.');
    end
end

function x = iAsStringColumn(x)
    if isstring(x)
        x = strip(x);
        return;
    end

    if iscellstr(x) || ischar(x) || iscell(x) || iscategorical(x)
        x = string(x);
        x = strip(x);
        return;
    end

    if isnumeric(x) || islogical(x)
        x = string(x);
        x = strip(x);
        return;
    end

    error('read_runs_table:UnsupportedTextColumn', ...
        'Unsupported text-like column type: %s', class(x));
end

function x = iAsDoubleColumn(x, varName)
    if isnumeric(x)
        x = double(x);
        return;
    end

    if islogical(x)
        x = double(x);
        return;
    end

    if isstring(x) || iscellstr(x) || ischar(x) || iscell(x) || iscategorical(x)
        x = str2double(string(x));
        return;
    end

    error('read_runs_table:UnsupportedNumericColumn', ...
        'Unsupported numeric column type in %s: %s', char(varName), class(x));
end

function x = iAsLogicalColumn(x, varName)
    if islogical(x)
        x = x(:);
        return;
    end

    s = lower(strip(string(x)));
    x = false(size(s));

    isTrue  = ismember(s, ["true","1","yes","y"]);
    isFalse = ismember(s, ["false","0","no","n",""]);

    if any(~(isTrue | isFalse))
        badVals = unique(s(~(isTrue | isFalse)));
        error('read_runs_table:InvalidLogicalColumn', ...
            'Invalid logical values in %s: %s', ...
            char(varName), strjoin(cellstr(badVals), ', '));
    end

    x(isTrue) = true;
    x(isFalse) = false;
    x = logical(x(:));
end
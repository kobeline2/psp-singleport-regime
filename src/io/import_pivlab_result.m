function piv = import_pivlab_result(exportMatPath, varargin)
%IMPORT_PIVLAB_RESULT Convert a PIVLab MAT export to canonical form.
%
% Usage:
%   piv = import_pivlab_result(exportMatPath, 'run_id', "R0009")
%
% Required variables in exportMatPath:
%   x, y, u_filtered, v_filtered, typevector_filtered,
%   calxy, calu, calv, units
%
% Notes:
%   - exportMatPath is typically a full PIVLab workspace dump such as
%     PIVlab_raw.mat. Extra variables are ignored.
%   - PIVLab commonly stores one cell per frame. This importer converts
%     frame-varying fields to numeric stacks with frame on the 3rd dim.
%   - If x and y are identical for every frame, they are collapsed to 2-D
%     static grids to keep the canonical struct lean.

    p = inputParser;
    p.addRequired('exportMatPath', @(x) ischar(x) || isstring(x));
    p.addParameter('run_id', "", @(x) ischar(x) || isstring(x));
    p.addParameter('variant', "single_dt", @(x) ischar(x) || isstring(x));
    p.addParameter('source_video_fps_hz', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('effective_sequence_fps_hz', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('export_step_frames', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('pair_step_frames', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('dt_pair_s', NaN, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('preset_id', "", @(x) ischar(x) || isstring(x));
    p.addParameter('VDP', "", @(x) ischar(x) || isstring(x));
    p.addParameter('notes', "", @(x) ischar(x) || isstring(x));
    p.addParameter('setting_file', "", @(x) ischar(x) || isstring(x));
    p.addParameter('export_file', "", @(x) ischar(x) || isstring(x));
    p.addParameter('session_file', "", @(x) ischar(x) || isstring(x));
    p.parse(exportMatPath, varargin{:});
    prm = p.Results;

    exportMatPath = string(prm.exportMatPath);
    if ~isfile(exportMatPath)
        error('import_pivlab_result:FileNotFound', ...
            'PIVLab export MAT not found: %s', char(exportMatPath));
    end

    requiredVars = {
        'x'
        'y'
        'u_filtered'
        'v_filtered'
        'typevector_filtered'
        'calxy'
        'calu'
        'calv'
        'units'
    };

    S = load(exportMatPath, requiredVars{:});
    missingVars = requiredVars(~isfield(S, requiredVars));
    if ~isempty(missingVars)
        error('import_pivlab_result:MissingVariables', ...
            'Missing required PIVLab variables in %s: %s', ...
            char(exportMatPath), strjoin(missingVars, ', '));
    end

    piv = struct();
    piv.run_id = string(prm.run_id);
    piv.source = "pivlab";
    piv.variant = string(prm.variant);
    piv.x = iCollapseStaticGrid(S.x, 'x');
    piv.y = iCollapseStaticGrid(S.y, 'y');
    piv.u = iStackFrameField(S.u_filtered, 'u_filtered');
    piv.v = iStackFrameField(S.v_filtered, 'v_filtered');
    piv.typevector = iStackFrameField(S.typevector_filtered, 'typevector_filtered');

    piv.meta = struct();
    piv.meta.source_video_fps_hz = double(prm.source_video_fps_hz);
    piv.meta.effective_sequence_fps_hz = double(prm.effective_sequence_fps_hz);
    piv.meta.export_step_frames = double(prm.export_step_frames);
    piv.meta.pair_step_frames = double(prm.pair_step_frames);
    piv.meta.dt_pair_s = double(prm.dt_pair_s);
    piv.meta.calxy = double(S.calxy);
    piv.meta.calu = double(S.calu);
    piv.meta.calv = double(S.calv);
    piv.meta.units = string(strtrim(string(S.units)));
    piv.meta.preset_id = string(prm.preset_id);
    piv.meta.VDP = string(prm.VDP);
    piv.meta.notes = string(prm.notes);
    piv.meta.setting_file = string(prm.setting_file);
    piv.meta.export_file = string(prm.export_file);
    piv.meta.session_file = string(prm.session_file);
    piv.meta.frame_count = iFrameCount(piv.u);
end

function A = iCollapseStaticGrid(data, varName)
    if isnumeric(data)
        A = double(data);
        return;
    end

    if ~iscell(data)
        error('import_pivlab_result:InvalidGridType', ...
            'Variable %s must be numeric or cell, but was %s.', ...
            varName, class(data));
    end

    values = data(:);
    firstIdx = find(~cellfun(@isempty, values), 1, 'first');
    if isempty(firstIdx)
        error('import_pivlab_result:EmptyGrid', ...
            'Variable %s contains only empty cells.', varName);
    end

    template = iValidateNumericCell(values{firstIdx}, varName);
    isSame = true;
    for k = 1:numel(values)
        if isempty(values{k})
            continue;
        end
        current = iValidateNumericCell(values{k}, varName);
        if ~isequal(size(current), size(template)) || ~isequaln(current, template)
            isSame = false;
            break;
        end
    end

    if isSame
        A = double(template);
    else
        A = iStackFrameField(data, varName);
    end
end

function A = iStackFrameField(data, varName)
    if isnumeric(data)
        A = double(data);
        return;
    end

    if ~iscell(data)
        error('import_pivlab_result:InvalidFieldType', ...
            'Variable %s must be numeric or cell, but was %s.', ...
            varName, class(data));
    end

    values = data(:);
    firstIdx = find(~cellfun(@isempty, values), 1, 'first');
    if isempty(firstIdx)
        error('import_pivlab_result:EmptyField', ...
            'Variable %s contains only empty cells.', varName);
    end

    template = iValidateNumericCell(values{firstIdx}, varName);
    fieldSize = size(template);
    nFrames = numel(values);
    A = NaN([fieldSize, nFrames]);

    for k = 1:nFrames
        if isempty(values{k})
            continue;
        end

        current = iValidateNumericCell(values{k}, varName);
        if ~isequal(size(current), fieldSize)
            error('import_pivlab_result:InconsistentFieldSize', ...
                'Variable %s has inconsistent frame size at index %d.', ...
                varName, k);
        end
        A(:, :, k) = double(current);
    end
end

function value = iValidateNumericCell(value, varName)
    if ~isnumeric(value)
        error('import_pivlab_result:InvalidCellContent', ...
            'Variable %s must contain numeric matrices.', varName);
    end
end

function nFrames = iFrameCount(u)
    if isnumeric(u) && ndims(u) >= 3
        nFrames = size(u, 3);
    else
        nFrames = 1;
    end
end

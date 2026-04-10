clear; clc;
%% s25_preview_piv_movie.m
% Make a lightweight preview movie from canonical single-dt PIV output.

init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
runID = "R0009";

% Output movie settings
frame_step = 5;
quiver_step = 3;
video_fps = 10;
autoscale = 1.5;
fig_pos = [100 100 720 480];

% -------------------------------------------------------------------------
% Load canonical PIV data
% -------------------------------------------------------------------------
workRunDir = fullfile(cfg.WORK_DIR, char(runID));
pivMat = fullfile(workRunDir, cfg.PIV_SINGLE_MAT);
outFile = fullfile(cfg.RESULTS_FIG_DIR, sprintf('%s_preview.mp4', runID));

fprintf('[s25_preview_piv_movie] run_id : %s\n', char(runID));
fprintf('[s25_preview_piv_movie] input  : %s\n', pivMat);
fprintf('[s25_preview_piv_movie] output : %s\n', outFile);

assert(isfile(pivMat), 'Canonical PIV MAT not found: %s', pivMat);

S = load(pivMat, 'piv');
assert(isfield(S, 'piv'), 'File does not contain variable "piv": %s', pivMat);
piv = S.piv;

assert(isfield(piv, 'u') && isfield(piv, 'v'), ...
    'Canonical PIV struct must contain piv.u and piv.v.');

u = iAsCellFrames(piv.u, 'piv.u');
v = iAsCellFrames(piv.v, 'piv.v');

x = [];
y = [];
if isfield(piv, 'x'); x = piv.x; end
if isfield(piv, 'y'); y = piv.y; end

dt_s = [];
if isfield(piv, 'meta') && isfield(piv.meta, 'dt_pair_s')
    if isnumeric(piv.meta.dt_pair_s) && isscalar(piv.meta.dt_pair_s) && isfinite(piv.meta.dt_pair_s) && piv.meta.dt_pair_s > 0
        dt_s = piv.meta.dt_pair_s;
    end
end

% -------------------------------------------------------------------------
% Render preview movie
% -------------------------------------------------------------------------
make_piv_quiver_movie(u, v, outFile, ...
    'x', x, ...
    'y', y, ...
    'Lx_m', C.basin.Lx_m, ...
    'Ly_m', C.basin.Ly_m, ...
    'dt_s', dt_s, ...
    'frame_step', frame_step, ...
    'quiver_step', quiver_step, ...
    'video_fps', video_fps, ...
    'fig_pos', fig_pos, ...
    'autoscale', autoscale, ...
    'title_prefix', sprintf('%s PIV preview', runID));

function frames = iAsCellFrames(data, varName)
    if iscell(data)
        frames = data(:);
        return;
    end

    if ~isnumeric(data)
        error('s25_preview_piv_movie:InvalidFieldType', ...
            '%s must be numeric or cell, but was %s.', varName, class(data));
    end

    if ndims(data) == 2
        frames = {data};
        return;
    end

    if ndims(data) ~= 3
        error('s25_preview_piv_movie:InvalidFieldSize', ...
            '%s must be 2-D, 3-D, or cell.', varName);
    end

    nFrames = size(data, 3);
    frames = cell(nFrames, 1);
    for k = 1:nFrames
        frames{k} = data(:, :, k);
    end
end

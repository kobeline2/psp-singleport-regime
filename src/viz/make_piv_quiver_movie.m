function make_piv_quiver_movie(u, v, outFile, varargin)
%MAKE_PIV_QUIVER_MOVIE Make a lightweight preview movie from PIVLab outputs.
%
% Example:
%   load('pivlab_short.mat', 'u', 'v');
%   make_piv_quiver_movie(u, v, 'preview.mp4', ...
%       'Lx_m', 3.0, 'Ly_m', 2.0, ...
%       'dt_s', 1/6, ...
%       'frame_step', 5, ...
%       'quiver_step', 3);
%
% Inputs
%   u, v    : cell arrays, each cell contains [Ny x Nx] velocity field
%   outFile : output video path, e.g. 'preview.mp4'
%
% Name-value pairs
%   'x'               : x grid, either numeric array [Ny x Nx] or cell array
%   'y'               : y grid, either numeric array [Ny x Nx] or cell array
%   'Lx_m'            : basin length in meters, default = 3.0
%   'Ly_m'            : basin width in meters,  default = 2.0
%   'dt_s'            : time interval between PIV fields, default = []
%   'frame_step'      : use every N-th frame, default = 5
%   'quiver_step'     : vector downsample step, default = 3
%   'video_fps'       : output video frame rate, default = 10
%   'fig_pos'         : figure position [left bottom width height]
%   'speed_clim'      : [cmin cmax], default = auto from 99th percentile
%   'autoscale'       : quiver autoscale factor, default = 1.5
%   'colormap_name'   : default = 'turbo'
%   'title_prefix'    : default = 'PIV preview'
%
% Notes
%   - Assumes u and v are already calibrated in physical velocity units.
%   - If x,y are not given, a uniform grid is generated over [0,Lx] x [0,Ly].

    p = inputParser;
    p.addRequired('u', @(x) iscell(x) && ~isempty(x));
    p.addRequired('v', @(x) iscell(x) && ~isempty(x));
    p.addRequired('outFile', @(x) ischar(x) || isstring(x));

    p.addParameter('x', [], @(x) isnumeric(x) || iscell(x) || isempty(x));
    p.addParameter('y', [], @(x) isnumeric(x) || iscell(x) || isempty(x));
    p.addParameter('Lx_m', 3.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('Ly_m', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('dt_s', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
    p.addParameter('frame_step', 5, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('quiver_step', 3, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('video_fps', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('fig_pos', [100 100 720 480], @(x) isnumeric(x) && numel(x) == 4);
    p.addParameter('speed_clim', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
    p.addParameter('autoscale', 1.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('colormap_name', 'turbo', @(x) ischar(x) || isstring(x));
    p.addParameter('title_prefix', 'PIV preview', @(x) ischar(x) || isstring(x));
    p.parse(u, v, outFile, varargin{:});
    prm = p.Results;

    assert(numel(u) == numel(v), 'u and v must have the same number of frames.');

    nFrames = numel(u);
    U0 = u{1};
    V0 = v{1};
    assert(isequal(size(U0), size(V0)), 'u{1} and v{1} must have the same size.');

    [Ny, Nx] = size(U0);

    % ---------------------------------------------------------------------
    % Grid
    % ---------------------------------------------------------------------
    [X, Y] = iResolveGrid(prm.x, prm.y, Nx, Ny, prm.Lx_m, prm.Ly_m);

    % ---------------------------------------------------------------------
    % Determine color scale
    % ---------------------------------------------------------------------
    if isempty(prm.speed_clim)
        smax = iEstimateSpeed99(u, v);
        clim = [0, smax];
    else
        clim = prm.speed_clim;
    end

    % ---------------------------------------------------------------------
    % Downsample grid for quiver
    % ---------------------------------------------------------------------
    jj = 1:prm.quiver_step:Ny;
    ii = 1:prm.quiver_step:Nx;
    Xq = X(jj, ii);
    Yq = Y(jj, ii);

    % ---------------------------------------------------------------------
    % Figure
    % ---------------------------------------------------------------------
    hFig = figure('Color', 'w', 'Position', prm.fig_pos, 'Visible', 'on');
    ax = axes(hFig);
    axis(ax, 'equal');
    axis(ax, [0 prm.Lx_m 0 prm.Ly_m]);
    set(ax, 'YDir', 'normal');
    box(ax, 'on');

    speed0 = hypot(U0, V0);
    hImg = imagesc(ax, X(1,:), Y(:,1), speed0);
    hold(ax, 'on');
    hQ = quiver(ax, Xq, Yq, U0(jj,ii), V0(jj,ii), prm.autoscale, 'k');
    hold(ax, 'off');

    caxis(ax, clim);
    colormap(ax, prm.colormap_name);
    cb = colorbar(ax);
    cb.Label.String = 'Speed';
    xlabel(ax, 'x [m]');
    ylabel(ax, 'y [m]');

    % ---------------------------------------------------------------------
    % Video writer
    % ---------------------------------------------------------------------
    outFile = char(outFile);
    outDir = fileparts(outFile);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    vw = VideoWriter(outFile, 'MPEG-4');
    vw.FrameRate = prm.video_fps;
    open(vw);

    % ---------------------------------------------------------------------
    % Loop
    % ---------------------------------------------------------------------
    useIdx = 1:prm.frame_step:nFrames;

    for k = 1:numel(useIdx)
        it = useIdx(k);
    
        Ui = u{it};
        Vi = v{it};
    
        if ~isnumeric(Ui) || ~isnumeric(Vi) || ~isequal(size(Ui), [Ny, Nx]) || ~isequal(size(Vi), [Ny, Nx])
            fprintf('[make_piv_quiver_movie] Skipping frame %d due to invalid size\\n', it);
            continue;
        end
    
        Si = hypot(Ui, Vi);
    
        set(hImg, 'CData', Si);
        set(hQ, 'UData', Ui(jj,ii), 'VData', Vi(jj,ii));
    
        if isempty(prm.dt_s)
            ttl = sprintf('%s, frame %d / %d', prm.title_prefix, it, nFrames);
        else
            tsec = (it - 1) * prm.dt_s;
            ttl = sprintf('%s, t = %.2f s', prm.title_prefix, tsec);
        end
        title(ax, ttl, 'Interpreter', 'none');
    
        drawnow;
        writeVideo(vw, getframe(hFig));
    end

    close(vw);
    close(hFig);

    fprintf('[make_piv_quiver_movie] Wrote %s\n', outFile);
end

% =========================================================================
function [X, Y] = iResolveGrid(xIn, yIn, Nx, Ny, Lx_m, Ly_m)
    if isempty(xIn) || isempty(yIn)
        x = linspace(0, Lx_m, Nx);
        y = linspace(0, Ly_m, Ny);
        [X, Y] = meshgrid(x, y);
        return;
    end

    if iscell(xIn), xIn = xIn{1}; end
    if iscell(yIn), yIn = yIn{1}; end

    X = xIn;
    Y = yIn;

    assert(isnumeric(X) && isnumeric(Y), 'x and y must be numeric or cell arrays.');
    assert(isequal(size(X), [Ny, Nx]) && isequal(size(Y), [Ny, Nx]), ...
        'x and y must match the size of u{1}.');
end

function s99 = iEstimateSpeed99(u, v)
    vals = [];
    n = numel(u);
    sampleIdx = unique(round(linspace(1, n, min(n, 20))));
    for i = sampleIdx
        s = hypot(u{i}, v{i});
        vals = [vals; s(:)]; %#ok<AGROW>
    end
    vals = vals(isfinite(vals));
    if isempty(vals)
        s99 = 1;
    else
        s99 = prctile(vals, 99);
        if s99 <= 0
            s99 = max(vals);
        end
        if s99 <= 0
            s99 = 1;
        end
    end
end
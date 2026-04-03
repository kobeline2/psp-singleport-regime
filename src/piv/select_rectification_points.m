function rect = select_rectification_points(videoPath, outFile, varargin)
%SELECT_RECTIFICATION_POINTS Select 4 corner points and save rectification data.
%
% Usage:
%   rect = select_rectification_points(videoPath, outFile)
%   rect = select_rectification_points(videoPath, outFile, 'frame_idx', 10)
%
% Inputs
%   videoPath : path to raw PIV video
%   outFile   : full path to output rectification MAT file, e.g.
%               .../derived/rectification/R0009/rectification.mat
%
% Name-value pairs
%   'run_id'        : run identifier, default = parent folder name of videoPath
%   'frame_idx'     : frame index used for point selection, default = 1
%   'Lx_m'          : basin length in meters, default = 3.0
%   'Ly_m'          : basin width in meters,  default = 2.0
%   'pixel_size_m'  : target pixel size in meters, default = 0.002
%   'operator'      : operator name/id, default = ""
%   'notes'         : notes string, default = ""
%   'do_confirm'    : ask for confirmation after clicking, default = true
%
% Output
%   rect : struct saved to outFile
%
% Click order
%   1. top-left
%   2. top-right
%   3. bottom-right
%   4. bottom-left

    p = inputParser;
    p.addRequired('videoPath', @(x) ischar(x) || isstring(x));
    p.addRequired('outFile',   @(x) ischar(x) || isstring(x));

    p.addParameter('run_id', "", @(x) ischar(x) || isstring(x));
    p.addParameter('frame_idx', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('Lx_m', 3.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('Ly_m', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('pixel_size_m', 0.002, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('operator', "", @(x) ischar(x) || isstring(x));
    p.addParameter('notes', "", @(x) ischar(x) || isstring(x));
    p.addParameter('do_confirm', true, @(x) islogical(x) && isscalar(x));

    p.parse(videoPath, outFile, varargin{:});
    prm = p.Results;

    videoPath = string(videoPath);
    outFile   = string(outFile);

    if ~isfile(videoPath)
        error('select_rectification_points:FileNotFound', ...
            'Video file not found: %s', char(videoPath));
    end

    % ---------------------------------------------------------------------
    % Infer run_id if not explicitly given
    % ---------------------------------------------------------------------
    run_id = string(prm.run_id);
    if strlength(run_id) == 0
        parentDir = fileparts(videoPath);
        [~, inferredRunID] = fileparts(parentDir);
        run_id = string(inferredRunID);
    end

    % ---------------------------------------------------------------------
    % Read target frame
    % ---------------------------------------------------------------------
    vr = VideoReader(videoPath);
    frame_idx = round(prm.frame_idx);

    if frame_idx > vr.NumFrames
        error('select_rectification_points:FrameOutOfRange', ...
            'frame_idx=%d exceeds number of frames (%d).', ...
            frame_idx, vr.NumFrames);
    end

    I = read(vr, frame_idx);

    % ---------------------------------------------------------------------
    % Click points interactively
    % ---------------------------------------------------------------------
    labels = ["top-left", "top-right", "bottom-right", "bottom-left"];

    isAccepted = false;
    src_pts_px = nan(4,2);

    while ~isAccepted
        hFig = figure('Name', 'Select rectification points', ...
                      'NumberTitle', 'off', ...
                      'Color', 'w');
        imshow(I, []);
        hold on;

        title(sprintf(['Select inner basin corners in order:\n' ...
                       '1) top-left, 2) top-right, 3) bottom-right, 4) bottom-left']), ...
              'Interpreter', 'none');

        [x, y] = ginput(4);
        src_pts_px = [x, y];

        plot(src_pts_px(:,1), src_pts_px(:,2), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
        for k = 1:4
            text(src_pts_px(k,1)+10, src_pts_px(k,2), sprintf('%d: %s', k, labels(k)), ...
                'Color', 'y', 'FontSize', 10, 'FontWeight', 'bold');
        end
        hold off;
        drawnow;

        if prm.do_confirm
            reply = input('Accept selected points? [y/n]: ', 's');
            if strcmpi(strtrim(reply), 'y')
                isAccepted = true;
            else
                close(hFig);
            end
        else
            isAccepted = true;
        end
    end

    % ---------------------------------------------------------------------
    % Define rectified image size
    % ---------------------------------------------------------------------
    Nx = round(prm.Lx_m / prm.pixel_size_m) + 1;
    Ny = round(prm.Ly_m / prm.pixel_size_m) + 1;

    dst_pts_px = [
        1,  1;
        Nx, 1;
        Nx, Ny;
        1,  Ny
    ];

    % ---------------------------------------------------------------------
    % Compute projective transform
    % ---------------------------------------------------------------------
    tform = fitgeotrans(src_pts_px, dst_pts_px, 'projective');

    % ---------------------------------------------------------------------
    % Build output struct
    % ---------------------------------------------------------------------
    rect = struct();
    rect.version = "v1";
    rect.run_id = run_id;
    rect.video_file = videoPath;
    rect.frame_idx = frame_idx;
    rect.created_at = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
    rect.operator = string(prm.operator);
    rect.notes = string(prm.notes);

    rect.corner_order = ["top-left"; "top-right"; "bottom-right"; "bottom-left"];
    rect.src_pts_px = src_pts_px;
    rect.dst_pts_px = dst_pts_px;

    rect.basin = struct();
    rect.basin.Lx_m = prm.Lx_m;
    rect.basin.Ly_m = prm.Ly_m;

    rect.pixel_size_m = prm.pixel_size_m;
    rect.Nx = Nx;
    rect.Ny = Ny;

    rect.tform = tform;
    rect.outputRef = imref2d([Ny, Nx]);

    % ---------------------------------------------------------------------
    % Save MAT file
    % ---------------------------------------------------------------------
    outDir = fileparts(outFile);
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    save(outFile, 'rect');

    fprintf('[select_rectification_points] Saved: %s\n', char(outFile));
    fprintf('[select_rectification_points] run_id = %s, frame_idx = %d\n', char(run_id), frame_idx);
end

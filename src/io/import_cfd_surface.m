function piv = import_cfd_surface(sampleDir, varargin)
%IMPORT_CFD_SURFACE Convert OpenFOAM free-surface samples to canonical form.
%
% Usage:
%   piv = import_cfd_surface(sampleDir, 'run_id', "C0001")
%
% sampleDir is an OpenFOAM "surfaces" functionObject output directory
% (e.g. .../postProcessing/surfSample) that contains one numeric-named
% subdirectory per sample time:
%   <sampleDir>/<time>/U_freeSurface.raw   (columns: x y z Ux Uy Uz)
%
% The scattered surface points of each frame are interpolated onto a fixed
% regular x-y grid so that the result matches the canonical PIV struct
% produced by import_pivlab_result (static x/y grids, u/v/typevector
% stacked on dim 3, velocities in m/s). Cells outside the sampled surface
% (dry regions, outside the hull) get typevector = 0 and u = v = NaN.
%
% Notes:
%   - CFD velocities are instantaneous fields; meta.dt_pair_s carries the
%     sampling cadence because downstream code builds the frame time axis
%     from it (single_dt convention). meta.frame_times_s keeps the exact
%     sample times for reference.
%   - The vertical velocity component of the samples is discarded; the
%     comparison target is the horizontal surface-PIV field.

    p = inputParser;
    p.addRequired('sampleDir', @(x) ischar(x) || isstring(x));
    p.addParameter('run_id', "", @(x) ischar(x) || isstring(x));
    p.addParameter('variant', "single_dt", @(x) ischar(x) || isstring(x));
    p.addParameter('grid_dx_m', 0.02, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('x_lim_m', [0 3.0], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('y_lim_m', [0 2.0], @(x) isnumeric(x) && numel(x) == 2);
    p.addParameter('file_glob', "U_*.raw", @(x) ischar(x) || isstring(x));
    p.addParameter('surface_z_tol_m', 0.015, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('t_min_s', -Inf, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('t_max_s', Inf, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('case_path', "", @(x) ischar(x) || isstring(x));
    p.addParameter('notes', "", @(x) ischar(x) || isstring(x));
    p.parse(sampleDir, varargin{:});
    prm = p.Results;

    sampleDir = string(prm.sampleDir);
    if ~isfolder(sampleDir)
        error('import_cfd_surface:DirNotFound', ...
            'Sample directory not found: %s', char(sampleDir));
    end

    % ---------------------------------------------------------------------
    % Collect numeric-named time directories within [t_min_s, t_max_s]
    % ---------------------------------------------------------------------
    d = dir(sampleDir);
    names = string({d([d.isdir]).name});
    times = double(names);                       % non-numeric names -> NaN
    keep = ~isnan(times) & times >= prm.t_min_s & times <= prm.t_max_s;
    names = names(keep);
    times = times(keep);
    [times, order] = sort(times);
    names = names(order);

    nFrames = numel(times);
    if nFrames == 0
        error('import_cfd_surface:NoFrames', ...
            'No numeric time directories found under %s', char(sampleDir));
    end

    % ---------------------------------------------------------------------
    % Fixed regular grid (cell centres), meshgrid convention [ny x nx]
    % ---------------------------------------------------------------------
    dx = double(prm.grid_dx_m);
    xg = (prm.x_lim_m(1) + dx/2) : dx : prm.x_lim_m(2);
    yg = (prm.y_lim_m(1) + dx/2) : dx : prm.y_lim_m(2);
    [X, Y] = meshgrid(xg, yg);

    u = NaN([size(X), nFrames]);
    v = NaN([size(X), nFrames]);
    typevector = zeros([size(X), nFrames]);

    nSparse = 0;
    for k = 1:nFrames
        raw = iReadRawSurface(fullfile(sampleDir, names(k)), prm.file_glob);

        % The alpha=0.5 isosurface also wraps entrained bubbles and droplets
        % below/above the free surface (B03 showed 3-4x point-count spikes
        % during the channel air purge). Keep only points close to the median
        % surface height so the PIV comparison sees the top surface only.
        if size(raw, 1) >= 10
            zMed = median(raw(:, 3));
            raw = raw(abs(raw(:, 3) - zMed) <= prm.surface_z_tol_m, :);
        end

        if size(raw, 1) < 10
            nSparse = nSparse + 1;
            continue;                            % frame stays all-invalid
        end

        % Columns: x y z Ux Uy Uz. Project onto x-y and drop Uz.
        Fu = scatteredInterpolant(raw(:,1), raw(:,2), raw(:,4), 'linear', 'none');
        Fv = scatteredInterpolant(raw(:,1), raw(:,2), raw(:,5), 'linear', 'none');
        uk = Fu(X, Y);
        vk = Fv(X, Y);

        valid = isfinite(uk) & isfinite(vk);
        uk(~valid) = NaN;
        vk(~valid) = NaN;

        u(:, :, k) = uk;
        v(:, :, k) = vk;
        typevector(:, :, k) = double(valid);
    end

    if nSparse > 0
        warning('import_cfd_surface:SparseFrames', ...
            '%d of %d frames had fewer than 10 surface points and were left invalid.', ...
            nSparse, nFrames);
    end

    % ---------------------------------------------------------------------
    % Canonical struct (mirrors import_pivlab_result)
    % ---------------------------------------------------------------------
    piv = struct();
    piv.run_id = string(prm.run_id);
    piv.source = "cfd";
    piv.variant = string(prm.variant);
    piv.x = X;
    piv.y = Y;
    piv.u = u;
    piv.v = v;
    piv.typevector = typevector;

    piv.meta = struct();
    piv.meta.source_video_fps_hz = NaN;
    if nFrames > 1
        piv.meta.effective_sequence_fps_hz = 1 / median(diff(times));
    else
        piv.meta.effective_sequence_fps_hz = NaN;
    end
    piv.meta.export_step_frames = NaN;
    piv.meta.pair_step_frames = NaN;
    % In the canonical struct dt_pair_s doubles as the frame interval
    % (compute_frame_metrics_basic builds time_s from it), so for CFD it
    % carries the sampling cadence even though the fields are instantaneous.
    if nFrames > 1
        dts = diff(times);
        piv.meta.dt_pair_s = median(dts);
        if max(abs(dts - median(dts))) > 0.01 * median(dts)
            warning('import_cfd_surface:UnevenSampling', ...
                'Sample intervals vary by more than 1%%; time_s uses the median (%.3f s).', ...
                median(dts));
        end
    else
        piv.meta.dt_pair_s = NaN;
    end
    piv.meta.calxy = 1;
    piv.meta.calu = 1;
    piv.meta.calv = 1;
    piv.meta.units = "[m] respectively [m/s]";   % grid in m, velocity in m/s
    piv.meta.preset_id = "";
    piv.meta.VDP = "";
    piv.meta.notes = string(prm.notes);
    piv.meta.setting_file = "";
    piv.meta.export_file = "";
    piv.meta.session_file = "";
    piv.meta.frame_count = nFrames;

    % CFD-specific provenance (extra fields; downstream ignores unknowns)
    piv.meta.frame_times_s = times(:).';
    piv.meta.grid_dx_m = dx;
    piv.meta.case_path = string(prm.case_path);
    piv.meta.sample_dir = sampleDir;
end

function raw = iReadRawSurface(timeDir, fileGlob)
    hits = dir(fullfile(timeDir, char(fileGlob)));
    if isempty(hits)
        error('import_cfd_surface:RawFileNotFound', ...
            'No file matching %s in %s', char(fileGlob), char(timeDir));
    end
    if numel(hits) > 1
        warning('import_cfd_surface:MultipleRawFiles', ...
            'Multiple files match %s in %s. Using %s.', ...
            char(fileGlob), char(timeDir), hits(1).name);
    end

    fpath = fullfile(hits(1).folder, hits(1).name);
    raw = readmatrix(fpath, 'FileType', 'text', 'CommentStyle', '#');

    if isempty(raw) || size(raw, 2) < 6
        error('import_cfd_surface:BadRawFormat', ...
            'Expected >= 6 columns (x y z Ux Uy Uz) in %s', fpath);
    end
end

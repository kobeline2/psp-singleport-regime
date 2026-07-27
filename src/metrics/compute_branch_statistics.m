function T = compute_branch_statistics(cfg, varargin)
%COMPUTE_BRANCH_STATISTICS Per-run circulation branch and how firmly it locks.
%
% In a system that spontaneously breaks left-right symmetry, the sign of the
% net circulation is a per-run outcome (which branch the run fell onto), not
% a quantity to average over repetitions. Averaging signed I_circ across
% repetitions that sit on opposite branches cancels to ~0 and destroys the
% result (see doc/metrics_primer.md 1b). This function instead reduces each
% run's I_circ(t) to the branch it settled on and how firmly it stayed there.
%
% Statistics are taken over the quasi-steady deep bands (default B3+B4,
% h/a > 1.09), where the jet is fully submerged and I_unst has dropped by an
% order of magnitude. The shallow bands are excluded on purpose: there the
% surface-exposed jet wanders, which weakens the lock for reasons unrelated
% to branch selection.
%
% Usage:
%   T = compute_branch_statistics(cfg)
%   T = compute_branch_statistics(cfg, 'bands', ["B3" "B4"])
%   T = compute_branch_statistics(cfg, 'runs', ["R0005" "R0008"])
%
% Parameters:
%   bands : string array of band_id to pool. Default ["B3" "B4"].
%   runs  : string array of run_id to process. Default = all runs in
%           runs.csv with exclude_flag false and a frame_metrics file.
%
% Output columns:
%   run_id, mode, flow_level, date, repetition
%   n_frames          frames pooled over the selected bands
%   I_circ_mean       signed mean of I_circ over those frames
%   I_circ_std        standard deviation over those frames
%   R_lock            |I_circ_mean| / I_circ_std  (lock strength)
%   sign_persistence  fraction of frames sharing the sign of I_circ_mean
%   branch_sign       +1 / -1 (sign of I_circ_mean), NaN if undefined
%   Q_transit_Lps     transit-time discharge over the same bands,
%                     Q = dV_band / T_band
%
% Note on Q_transit_Lps: with the default deep bands the swept volume is
% simply A_plan * dh, because both bands lie above the guide-channel ceiling
% h = a. Below h = a the channel adds plan area and the volume would carry
% that (still unconfirmed) geometry -- see scripts/s33_compare_cfd_experiment.m.
% The transit-time estimate is preferred over the q_actual column, which is
% rate-limited by the 1 mm quantization of the water-level logger.

    p = inputParser;
    p.addRequired('cfg', @isstruct);
    p.addParameter('bands', ["B3" "B4"], @(x) isstring(x) || ischar(x) || iscellstr(x));
    p.addParameter('runs', string.empty, @(x) isstring(x) || ischar(x) || iscellstr(x));
    p.parse(cfg, varargin{:});
    prm = p.Results;

    bandIds = string(prm.bands);
    C = constants();

    % Swept volume per band, split at the guide-channel ceiling h = a.
    bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');
    a_m = C.port.height_m;
    b_m = C.port.width_m;
    dV_m3 = 0;
    for bi = 1:height(bands)
        if ~ismember(bands.band_id(bi), bandIds); continue; end
        hlo = bands.h_min_m(bi); hhi = bands.h_max_m(bi);
        below = max(0, min(hhi, a_m) - min(hlo, a_m));
        above = max(0, max(hhi, a_m) - max(hlo, a_m));
        dV_m3 = dV_m3 + (C.basin.Aplan_m2 + 0.6 * b_m) * below + C.basin.Aplan_m2 * above;
    end

    R = read_runs_table(cfg);
    if ismember('exclude_flag', R.Properties.VariableNames)
        R = R(~iTrueFlag(R.exclude_flag), :);
    end
    if ~isempty(prm.runs)
        R = R(ismember(R.run_id, string(prm.runs)), :);
    end

    run_id = strings(0,1); mode = strings(0,1); flow_level = strings(0,1);
    date = strings(0,1); repetition = []; n_frames = [];
    I_circ_mean = []; I_circ_std = []; R_lock = [];
    sign_persistence = []; branch_sign = []; Q_transit_Lps = [];

    for k = 1:height(R)
        rid = string(R.run_id(k));
        FM = iReadFrameMetrics(cfg, rid);
        if isempty(FM); continue; end
        if ~all(ismember({'I_circ','band_id','time_s'}, FM.Properties.VariableNames))
            warning('compute_branch_statistics:MissingColumns', ...
                'Skipping %s: frame_metrics lacks I_circ / band_id / time_s.', rid);
            continue;
        end

        inBand = ismember(string(FM.band_id), bandIds);
        ic = FM.I_circ(inBand);
        tt = FM.time_s(inBand);
        ic = ic(isfinite(ic));
        if numel(ic) < 2; continue; end

        mu = mean(ic);
        sd = std(ic);
        sg = sign(mu);
        if sg == 0; sg = NaN; end

        % Transit time actually spent in the pooled bands.
        tt = tt(isfinite(tt));
        T_s = max(tt) - min(tt);

        run_id(end+1,1)     = rid;                                    %#ok<AGROW>
        mode(end+1,1)       = string(R.mode(k));                      %#ok<AGROW>
        flow_level(end+1,1) = string(R.flow_level(k));                %#ok<AGROW>
        date(end+1,1)       = string(R.date(k));                      %#ok<AGROW>
        repetition(end+1,1) = R.repetition(k);                        %#ok<AGROW>
        n_frames(end+1,1)   = numel(ic);                              %#ok<AGROW>
        I_circ_mean(end+1,1) = mu;                                    %#ok<AGROW>
        I_circ_std(end+1,1)  = sd;                                    %#ok<AGROW>
        R_lock(end+1,1)      = abs(mu) / sd;                          %#ok<AGROW>
        sign_persistence(end+1,1) = mean(sign(ic) == sg);             %#ok<AGROW>
        branch_sign(end+1,1) = sg;                                    %#ok<AGROW>
        Q_transit_Lps(end+1,1) = 1000 * dV_m3 / max(T_s, eps);        %#ok<AGROW>
    end

    T = table(run_id, mode, flow_level, date, repetition, n_frames, ...
        I_circ_mean, I_circ_std, R_lock, sign_persistence, branch_sign, ...
        Q_transit_Lps);
end

function FM = iReadFrameMetrics(cfg, runID)
    FM = [];
    metricsDir = fullfile(cfg.DERIVED_METRICS_DIR, char(runID));
    matPath = fullfile(metricsDir, 'frame_metrics.mat');
    csvPath = fullfile(metricsDir, 'frame_metrics.csv');
    if isfile(matPath)
        S = load(matPath, 'frameMetrics');
        if isfield(S, 'frameMetrics'); FM = S.frameMetrics; end
    elseif isfile(csvPath)
        FM = readtable(csvPath, 'TextType', 'string');
    end
end

function tf = iTrueFlag(col)
    if islogical(col)
        tf = col;
    else
        tf = ismember(lower(string(col)), ["true" "1" "yes"]);
    end
end

clear; clc;
%% s33_compare_cfd_experiment.m
% Fair CFD-vs-experiment comparison, per depth band.
%
% For one CFD run (piv_source = "cfd") and the experimental runs that share
% its mode + flow_level, this driver builds a like-for-like comparison:
%   - E is normalized by the ACTUAL port velocity U_p_act = Q_act/(a b),
%     where Q_act is the transit-time discharge Q = dV_band / T_band. The lab
%     pump ramps within a run (measured 2026-07-23), so nominal-Q E/U_p^2
%     mixes the pump ramp into the physics; the actual-Q form is the honest
%     scaling test. Normalization-free indices (I_asym, I_rot, I_unst) are
%     compared directly.
%   - The experimental runs are pooled to a [min, max] band across repetitions
%     (n typically 3), and the CFD value is flagged inside / outside that range.
%
% Prerequisite: band_metrics.csv from s32 (all runs through s30 + s31 + s32).
% To compare CFD fairly on the same footprint, import the CFD surface onto the
% Omega grid first (import_cfd_surface with C.metrics.omega_* ; see
% doc/metrics_primer.md) so E/phi/I_rot use the experiment's domain+resolution.
%
% For daily use, copy this file into tmp/ and edit the copy.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot);
init

% -------------------------------------------------------------------------
% User settings
% -------------------------------------------------------------------------
cfdRunID = "C0001";
% Metrics to tabulate. 'E' is shown as E/U_p_act^2; the rest are as-is.
metricsToShow = ["E","I_asym","I_unst","I_rot","phi_lv"];

% -------------------------------------------------------------------------
% Load band metrics and resolve the comparison set
% -------------------------------------------------------------------------
bandCsv = fullfile(cfg.DERIVED_METRICS_DIR, 'band_metrics.csv');
assert(isfile(bandCsv), 'band_metrics.csv not found. Run s32 first: %s', bandCsv);
BM = readtable(bandCsv, 'TextType', 'string');

T = read_runs_table(cfg);
cfdRow = T(T.run_id == cfdRunID, :);
assert(height(cfdRow) == 1, 'CFD run not found: %s', char(cfdRunID));
mode = cfdRow.mode; flow = cfdRow.flow_level;

% Experimental partners: same mode + flow level, source not cfd.
expRuns = unique(BM.run_id(BM.mode == mode & BM.flow_level == flow & ~startsWith(BM.run_id, "C")));
assert(~isempty(expRuns), 'No experimental runs match %s / %s.', char(mode), char(flow));

fprintf('[s33] CFD %s  vs  experiment {%s}  (%s / %s)\n', ...
    char(cfdRunID), strjoin(cellstr(expRuns), ', '), char(mode), char(flow));

a_m = C.port.height_m; b_m = C.port.width_m;
bands = readtable(cfg.DEPTH_BANDS_CSV, 'TextType', 'string');

% Geometric volume swept in each band [m^3], accounting for the plan-area
% step at the channel ceiling (h = a): below a the guide channel adds area,
% above a only the tank counts. Used with per-band transit time to get the
% robust actual discharge Q = dV_band / T_band (transit-time method; more
% reliable than the |dh/dt| q_actual column at low flow -- see audit).
A_below = C.basin.Aplan_m2 + 0.6 * b_m;   % tank + guide channel plan area
A_above = C.basin.Aplan_m2;               % tank only
dV_band = containers.Map('KeyType','char','ValueType','double');
for bi = 1:height(bands)
    hlo = bands.h_min_m(bi); hhi = bands.h_max_m(bi);
    below = max(0, min(hhi, a_m) - min(hlo, a_m));
    above = max(0, max(hhi, a_m) - max(hlo, a_m));
    dV_band(char(bands.band_id(bi))) = A_below*below + A_above*above;
end

% Per-run, per-band transit time from frame_metrics (actual time span in band).
Q_act = iActualDischarge(cfg, [expRuns; cfdRunID], dV_band);

% -------------------------------------------------------------------------
% Per band: actual-Q normalize E, pool experiment, compare
% -------------------------------------------------------------------------
bandIDs = ["B1","B2","B3","B4"];
fprintf('\n%-4s %-8s %22s %10s %8s\n', 'band', 'metric', 'experiment [min,max]', char(cfdRunID), 'verdict');
fprintf('%s\n', repmat('-', 1, 56));

for bi = 1:numel(bandIDs)
    b = bandIDs(bi);
    for mi = 1:numel(metricsToShow)
        mname = metricsToShow(mi);
        expVals = arrayfun(@(r) iBandMetric(BM, r, b, mname, a_m, b_m, Q_act), expRuns);
        expVals = expVals(~isnan(expVals));
        cfdVal = iBandMetric(BM, cfdRunID, b, mname, a_m, b_m, Q_act);
        if isempty(expVals) || isnan(cfdVal); continue; end
        lo = min(expVals); hi = max(expVals);
        if cfdVal >= lo && cfdVal <= hi
            verdict = 'in-range';
        elseif cfdVal < lo
            verdict = sprintf('%.2fx low', cfdVal/lo);
        else
            verdict = sprintf('%.2fx high', cfdVal/hi);
        end
        label = mname; if mname == "E"; label = "E/Up_act^2"; end
        fprintf('%-4s %-11s [%8.4f,%8.4f] %10.4f  %s\n', ...
            iBandLabel(b, bi), label, lo, hi, cfdVal, verdict);
    end
end
fprintf('\nNote: E is actual-Q normalized. I_* are normalization-free.\n');
fprintf('Fair comparison assumes the CFD surface was sampled on Omega (see s33 header).\n');

% =========================================================================
% Local helpers
% =========================================================================
function v = iBandMetric(BM, runID, band, mname, a_m, b_m, Q_act)
%IBANDMETRIC One band value, with E converted to E/U_p_act^2.
    row = BM(BM.run_id == runID & BM.band_id == band, :);
    if height(row) ~= 1; v = NaN; return; end
    switch mname
        case "E"
            % Transit-time actual port velocity (see Q_act precompute).
            key = char(runID + "|" + band);
            if isKey(Q_act, key) && Q_act(key) > 0
                Q = Q_act(key);
            else
                Q = row.nominal_Q_Lps / 1000;   % fallback
            end
            Up = Q / (a_m * b_m);
            v = row.E_mean / Up^2;
        case "I_asym"; v = row.I_asym_mean;
        case "I_rot";  v = row.I_rot_mean;
        case "I_unst"; v = row.I_unst;
        case "phi_lv"; v = row.phi_lv_mean;
        otherwise;     v = NaN;
    end
end

function Q = iActualDischarge(cfg, runIDs, dV_band)
%IACTUALDISCHARGE Transit-time discharge Q = dV_band / T_band [m^3/s].
% T_band = time span of frames assigned to the band in frame_metrics.
    Q = containers.Map('KeyType','char','ValueType','double');
    for i = 1:numel(runIDs)
        rid = runIDs(i);
        fmCsv = fullfile(cfg.DERIVED_METRICS_DIR, char(rid), 'frame_metrics.csv');
        if ~isfile(fmCsv); continue; end
        fm = readtable(fmCsv, 'TextType', 'string');
        if ~ismember('band_id', fm.Properties.VariableNames); continue; end
        for b = ["B1","B2","B3","B4"]
            sel = fm.band_id == b & isfinite(fm.time_s);
            if nnz(sel) < 2; continue; end
            Tband = max(fm.time_s(sel)) - min(fm.time_s(sel));
            if Tband > 0 && isKey(dV_band, char(b))
                Q(char(rid + "|" + b)) = dV_band(char(b)) / Tband;
            end
        end
    end
end

function s = iBandLabel(b, bi)
    if bi == 1; s = char(b); else; s = ''; end
end

clear; clc;
%% s33_compare_cfd_experiment.m
% Fair CFD-vs-experiment comparison, per depth band.
%
% For one CFD run (piv_source = "cfd") and the experimental runs that share
% its mode + flow_level, this driver builds a like-for-like comparison:
%   - E is normalized by the port velocity U_p = Q/(a b), with ONE constant Q
%     per run. The discharge is steady within a run, verified 2026-10-26 by
%     three independent routes (lower-tank level, PIV jet speed, and the level
%     gauge's own noise statistics) -- see doc/qdip_jet_check.md section 0.
%       CFD        -> the inflow BC value (nominal_Q_Lps is exact by construction)
%       experiment -> the run mean, from the level record over the whole run
%     The per-band transit-time Q = dV_band/T_band used here until 2026-11-14
%     is NOT usable: it comes from the upper-tank gauge, whose reading is off by
%     up to ~10 mm near h/a ~ 1, and that artefact is what produced the
%     retracted "pump ramp" (cfd/campaign.md section 6). Note the experiment
%     runs at ~0.75-0.89 of nominal, so normalizing it by nominal Q would
%     overstate U_p^2 by 25-80%.
%     Normalization-free indices (I_asym, I_rot, I_unst) are compared directly.
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
% Metrics to tabulate. 'E' -> E/U_p^2 (constant per-run Q). 'I_circ' -> |net circulation|
% (magnitude, to sidestep the y-orientation sign convention). 'I_circ_cov'
% -> within-band coefficient of variation of I_circ(t) = std/|mean|, a direct
% measure of whether the basin-scale gyre PULSES (the laminar-overactivity
% signature). The rest are as-is.
% 'I_circ_org' = |I_circ|/I_rot: circulation organization. 1 = all rotation
% has one sense (a single coherent gyre); ~0 = counter-rotating cells cancel
% (symmetric flow that fails to organize into one gyre).
metricsToShow = ["E","I_asym","I_circ","I_circ_org","I_circ_cov","I_unst","I_rot","phi_lv"];

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
% One constant discharge per run (see header). The experiment's plan area is
% the measured basin 2.952 x 1.962 m (5.7918 m^2); the CFD's is the nominal
% 3.0 x 2.0 m the blockMesh was built on. Using one area for both biased the
% experiment's Q by +3.6% and E/Up^2 by -6.8%, so keep them separate (the CFD
% area is only needed if its Q ever has to be re-derived from the depth).
A_exp = C.basin.Aplan_m2;                 % measured basin

% Experiment: run mean from the level record.
Q_run = iRunMeanDischarge(cfg, expRuns, A_exp, a_m, b_m);
% CFD: the inflow BC value is exact, so do not re-estimate it from the depth.
for b = ["B1","B2","B3","B4"]
    Q_run(char(cfdRunID + "|" + b)) = cfdRow.nominal_Q_Lps / 1000;
end

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
        expVals = arrayfun(@(r) iBandMetric(BM, r, b, mname, a_m, b_m, Q_run), expRuns);
        expVals = expVals(~isnan(expVals));
        cfdVal = iBandMetric(BM, cfdRunID, b, mname, a_m, b_m, Q_run);
        if isempty(expVals) || isnan(cfdVal); continue; end
        lo = min(expVals); hi = max(expVals);
        if cfdVal >= lo && cfdVal <= hi
            verdict = 'in-range';
        elseif cfdVal < lo
            verdict = sprintf('%.2fx low', cfdVal/lo);
        else
            verdict = sprintf('%.2fx high', cfdVal/hi);
        end
        label = mname; if mname == "E"; label = "E/Up^2"; end
        fprintf('%-4s %-11s [%8.4f,%8.4f] %10.4f  %s\n', ...
            iBandLabel(b, mi), label, lo, hi, cfdVal, verdict);
    end
end
fprintf('\nNote: E uses one constant Q per run (CFD: BC value; experiment:\n');
fprintf('      run mean, ~0.75-0.89 of nominal). I_* are normalization-free.\n');
fprintf('Fair comparison assumes the CFD surface was sampled on Omega (see s33 header).\n');

% =========================================================================
% Local helpers
% =========================================================================
function v = iBandMetric(BM, runID, band, mname, a_m, b_m, Q_run)
%IBANDMETRIC One band value, with E converted to E/U_p^2 (constant Q per run).
    row = BM(BM.run_id == runID & BM.band_id == band, :);
    if height(row) ~= 1; v = NaN; return; end
    switch mname
        case "E"
            % Constant per-run port velocity (see Q_run precompute).
            key = char(runID + "|" + band);
            if isKey(Q_run, key) && Q_run(key) > 0
                Q = Q_run(key);
            else
                Q = row.nominal_Q_Lps / 1000;   % fallback
            end
            Up = Q / (a_m * b_m);
            v = row.E_mean / Up^2;
        case "I_asym"; v = row.I_asym_mean;
        case "I_rot";  v = row.I_rot_mean;
        case "I_unst"; v = row.I_unst;
        case "phi_lv"; v = row.phi_lv_mean;
        case "I_circ"; v = abs(row.I_circ_mean);          % net gyre strength
        case "I_circ_org"                                  % organization into one gyre
            if row.I_rot_mean > 0
                v = abs(row.I_circ_mean) / row.I_rot_mean;
            else
                v = NaN;
            end
        case "I_circ_cov"                                  % gyre pulsing
            if abs(row.I_circ_mean) > 0
                v = row.I_circ_std / abs(row.I_circ_mean);
            else
                v = NaN;
            end
        otherwise;     v = NaN;
    end
end

function Q = iRunMeanDischarge(cfg, runIDs, A_plan, a_m, b_m)
%IRUNMEANDISCHARGE One constant discharge per run [m^3/s], from the level record.
% Q = (volume swept between the depths at the first and last frame) / elapsed time.
% The discharge is steady within a run (doc/qdip_jet_check.md section 0), so the
% gauge record is NOT broken down per band: the gauge reads up to ~10 mm off
% near h/a ~ 1, which is local to the middle of the run and cancels over it.
% The same Q is written under every band key, so the caller looks it up the
% same way as before, as "<run>|<band>".
    Q = containers.Map('KeyType','char','ValueType','double');
    for i = 1:numel(runIDs)
        rid = runIDs(i);
        fmCsv = fullfile(cfg.DERIVED_METRICS_DIR, char(rid), 'frame_metrics.csv');
        if ~isfile(fmCsv); continue; end
        fm = readtable(fmCsv, 'TextType', 'string');
        if ~all(ismember({'time_s','depth_m'}, fm.Properties.VariableNames)); continue; end
        ok = isfinite(fm.time_s) & isfinite(fm.depth_m);
        if nnz(ok) < 2; continue; end
        t = fm.time_s(ok); h = fm.depth_m(ok);
        [~, iFirst] = min(t); [~, iLast] = max(t);
        Trun = t(iLast) - t(iFirst);
        hlo = min(h(iFirst), h(iLast)); hhi = max(h(iFirst), h(iLast));
        if Trun <= 0 || hhi <= hlo; continue; end
        % The plan area steps at the channel ceiling h = a: below a the guide
        % channel adds area (0.6 x b is the CFD culvert footprint; the real feed
        % geometry is unconfirmed, so the experiment carries that assumption).
        below = max(0, min(hhi, a_m) - min(hlo, a_m));
        above = max(0, max(hhi, a_m) - max(hlo, a_m));
        Vrun = (A_plan + 0.6*b_m)*below + A_plan*above;
        for b = ["B1","B2","B3","B4"]
            Q(char(rid + "|" + b)) = Vrun / Trun;
        end
    end
end

function s = iBandLabel(b, rowInBand)
%IBANDLABEL Print the band id on its first row only, blank on the rest.
    if rowInBand == 1; s = char(b); else; s = ''; end
end

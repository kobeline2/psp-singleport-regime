"""Block-respecting exact tests for the branch-selection result (paper 1).

The 12 inflow runs form a randomized complete block design: 4 days x 3 flow
levels. A test that pools the 12 runs assumes they are exchangeable across
days; these two permute only within a day, so a day effect cannot produce the
result.

  (1) Page's trend test on the run-mean I_circ, ranked within each day
  (2) stratified exact permutation test on the branch signs

Both are computed on the gauge depth and on the time-proportional depth (the
primary axis since 2026-11-22). Usage: python3 scripts/checks/branch_block_tests.py
"""
import itertools, pathlib
import numpy as np, pandas as pd

ROOT = pathlib.Path(__file__).resolve().parents[2]
MET = ROOT / 'local/derived/metrics'
runs = pd.read_csv(ROOT / 'metadata/runs.csv')
runs = runs[(runs.run_id != 'C0001') & (runs['mode'] == 'inflow')]
LEVELS = ['low', 'medium', 'high']

def run_stats(rid, axis):
    fm = pd.read_csv(MET / rid / 'frame_metrics.csv').dropna(subset=['I_circ', 'time_s', 'depth_m'])
    if axis == 'gauge':
        deep = fm[fm.band_id.isin(['B3', 'B4'])]
    else:  # time-proportional depth: straight line between first and last gauge reading
        t0, t1 = fm.time_s.iloc[0], fm.time_s.iloc[-1]
        h0, h1 = fm.depth_m.iloc[0], fm.depth_m.iloc[-1]
        h = h0 + (h1 - h0) * (fm.time_s - t0) / (t1 - t0)
        deep = fm[h >= 0.060]
    ic = deep.I_circ
    return ic.mean(), ic.std(ddof=1), (np.sign(ic) == np.sign(ic.mean())).mean()

for axis in ('gauge', 'time'):
    tab = {}
    for _, r in runs.iterrows():
        m, s, p = run_stats(r.run_id, axis)
        tab[(r.date, r.flow_level)] = (r.run_id, m, abs(m) / s, p)
    days = sorted({d for d, _ in tab})
    print(f'===== depth axis: {axis} =====')
    for d in days:
        print('  ', d, '  '.join(f'{lv}: {tab[(d, lv)][0]} {tab[(d, lv)][1]:+.5f} (R {tab[(d, lv)][2]:.2f})' for lv in LEVELS))

    # (1) Page's trend test on the run-mean I_circ, ranked within each day.
    # Alternative: I_circ decreases from low to high. Statistic L = sum_j w_j * R_j with
    # weights (3, 2, 1) for (low, medium, high) and R_j the rank sum of level j
    # (rank 3 = largest I_circ). Exact null: all 3! orderings equally likely within a day.
    w = np.array([3, 2, 1])
    def L_of(rank_rows):
        return sum(int((w * np.array(rr)).sum()) for rr in rank_rows)
    obs_ranks = []
    for d in days:
        vals = np.array([tab[(d, lv)][1] for lv in LEVELS])
        obs_ranks.append(tuple(vals.argsort().argsort() + 1))
    L_obs = L_of(obs_ranks)
    perms = list(itertools.permutations([1, 2, 3]))
    cnt = tot = 0
    for combo in itertools.product(perms, repeat=len(days)):
        tot += 1
        if L_of(combo) >= L_obs:
            cnt += 1
    print(f'  Page trend test on I_circ within-day ranks: L = {L_obs} (max {L_of([(3,2,1)]*4)}), exact one-sided p = {cnt}/{tot} = {cnt/tot:.5f}')

    # (2) Stratified exact permutation test on the SIGNS (trend over levels, within-day
    # relabelling of the three runs). Statistic: sum of level scores (0,1,2) of positive runs.
    def score(signs):  # signs: tuple of 3 booleans (low, medium, high)
        return sum(i for i, s in enumerate(signs) if s)
    obs = 0; dists = []
    for d in days:
        signs = tuple(tab[(d, lv)][1] > 0 for lv in LEVELS)
        obs += score(signs)
        dists.append([score(p) for p in set(itertools.permutations(signs))])
    cnt = tot = 0
    for combo in itertools.product(*dists):
        tot += 1
        if sum(combo) <= obs:
            cnt += 1
    print(f'  stratified sign trend test: statistic = {obs}, exact one-sided p = {cnt}/{tot} = {cnt/tot:.5f}')

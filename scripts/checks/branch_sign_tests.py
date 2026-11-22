"""Checks behind the branch-selection result of paper 1 (run from anywhere).

Usage: python3 scripts/checks/branch_sign_tests.py
Needs local/derived/metrics/<run>/frame_metrics.csv for the 12 inflow runs.

1. A second, independent branch indicator for ALL 12 inflow runs from data
   already on this machine: which half of the basin carries more energy
   (sign of E_left - E_right) -- versus the I_circ branch sign.
2. Dimensionless control parameter per level (run-average discharge).
3. Exact test of the sign pattern.
"""
import pandas as pd, numpy as np, pathlib
from math import comb

ROOT = pathlib.Path(__file__).resolve().parents[2]
MET = ROOT / 'local/derived/metrics'
runs = pd.read_csv(ROOT / 'metadata/runs.csv')
runs = runs[(runs.run_id != 'C0001') & (runs['mode'] == 'inflow')]

print('=== 1. second branch indicator: energy side vs circulation sign (B3+B4) ===')
agree = 0
for _, r in runs.iterrows():
    fm = pd.read_csv(MET / r.run_id / 'frame_metrics.csv')
    d = fm[fm.band_id.isin(['B3', 'B4'])].dropna(subset=['E_left', 'E_right', 'I_circ'])
    s_asym = (d.E_left - d.E_right) / (d.E_left + d.E_right)      # + = more energy at small y
    s_circ = np.sign(d.I_circ.mean())
    s_side = np.sign(s_asym.mean())
    frac = (np.sign(s_asym) == s_side).mean()
    ok = s_side == s_circ
    agree += ok
    print(f'  {r.run_id} {r.flow_level:7s} circ {"+" if s_circ>0 else "-"}  '
          f'side {"+" if s_side>0 else "-"} (mean {s_asym.mean():+.3f}, persistence {frac:.2f})'
          f'{"" if ok else "   <-- DISAGREE"}')
print(f'  => agree in {agree}/12 runs')

print('\n=== 2. control parameter (run-average Q, nu = 1.0e-6 m^2/s) ===')
a, b, nu, g = 0.055, 0.11, 1.0e-6, 9.81
for lv, Q in (('low', 0.219e-3), ('medium', 0.392e-3), ('high', 0.623e-3)):
    Up = Q / (a * b)
    print(f'  {lv:7s} Q {Q*1e3:.3f} L/s  U_p {Up:.4f} m/s  Re_p = U_p a/nu = {Up*a/nu:5.0f}'
          f'  Fr_p(h=a) = {Up/np.sqrt(g*a):.3f}')

print('\n=== 3. exact tests of the sign pattern ===')
# 2x2 low vs high: [[4 +, 0 -], [0 +, 4 -]]. Fisher exact, one- and two-sided.
p1 = 1 / comb(8, 4)
print(f'  low vs high, Fisher exact: one-sided {p1:.4f}, two-sided {2*p1:.4f}')
# Within-day pairing: low and high opposite on all 4 days, in the same orientation.
# Under H0 (sign independent of level, 50/50), P(low+,high-) per day = 1/4.
print(f'  within-day, same orientation on all 4 days: {(1/4)**4:.4f} '
      f'(either orientation: {2*(1/4)**4:.4f})')
# Cochran-Armitage-like: count + across low/med/high = 4/1/0 of 4 each. Exact
# permutation test of a monotone trend: P(sum of ranks of + runs <= observed).
import itertools
levels = [0]*4 + [1]*4 + [2]*4
obs = sum(l for l, s in zip(levels, [1,1,1,1, 0,0,0,1, 0,0,0,0]) if s)
cnt = tot = 0
for comb_idx in itertools.combinations(range(12), 5):
    tot += 1
    if sum(levels[i] for i in comb_idx) <= obs:
        cnt += 1
print(f'  monotone trend over 3 levels (5 positive runs, exact permutation): p = {cnt/tot:.4f}')

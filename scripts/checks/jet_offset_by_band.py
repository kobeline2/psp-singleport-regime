"""Jet lateral offset at x = 1.0 m, by depth band (paper 1, branch selection).

Usage: python3 scripts/checks/jet_offset_by_band.py   (needs h5py)
Needs local/work/<run>/pivlab_single.mat; on the LT these exist only for
R0001 and R0005-R0008. Original question: is R0007 symmetric in the deep
bands, or only early in the run?

Same jet-offset method as tmp/gyre_diagnosis/fig2_evidence.py (forward-momentum
centroid of 20 s block-mean u at x = 1.0 m, offset from the port axis y = 0.981 m),
then mapped onto the depth bands through frame_metrics time_s -> band_id.
"""
import numpy as np, h5py, pandas as pd, pathlib
REPO = pathlib.Path(__file__).resolve().parents[2]

def jet_series(rid, xv=1.0, blk_s=20.0):
    piv = h5py.File(REPO / f'local/work/{rid}/pivlab_single.mat', 'r')['piv']
    x = piv['x'][()][:, 0]; y = piv['y'][()][0, :]
    fps = float(np.squeeze(piv['meta/effective_sequence_fps_hz'][()]))
    n = piv['u'].shape[0]; blk = int(round(blk_s * fps)); nb = n // blk
    i = int(np.argmin(abs(x - xv)))
    t, o = [], []
    for ib in range(nb):
        u = np.nanmean(piv['u'][ib*blk:(ib+1)*blk, i, :], axis=0)
        w = np.clip(np.nan_to_num(u), 0, None) ** 2
        t.append((ib + 0.5) * blk / fps)
        o.append(float((w * (y - 0.981)).sum() / max(w.sum(), 1e-12)))
    return np.array(t), np.array(o)

for rid in ('R0001', 'R0005', 'R0006', 'R0007', 'R0008'):
    t, o = jet_series(rid)
    fm = pd.read_csv(REPO / f'local/derived/metrics/{rid}/frame_metrics.csv')
    t0 = fm.time_s.min()
    band = np.interp(t, fm.time_s - t0, np.arange(len(fm)))
    bid = fm.band_id.values[np.clip(band.astype(int), 0, len(fm) - 1)]
    print(f'{rid}  run length {t[-1]:.0f} s')
    for b in ('B1', 'B2', 'B3', 'B4'):
        m = bid == b
        if m.any():
            print(f'   {b}: t {t[m].min():5.0f}-{t[m].max():5.0f} s   offset mean {o[m].mean():+.3f} m'
                  f'   range [{o[m].min():+.2f}, {o[m].max():+.2f}]')
    straight = np.abs(o) <= 0.07
    # longest run of consecutive straight blocks
    best = cur = 0
    for s in straight:
        cur = cur + 1 if s else 0
        best = max(best, cur)
    print(f'   longest stretch within +-0.07 m: {best*20} s; first time |offset| > 0.2 m: '
          f'{t[np.argmax(np.abs(o) > 0.2)] if (np.abs(o) > 0.2).any() else "never"} s')

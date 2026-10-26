# -*- coding: utf-8 -*-
"""
load_wl.py -- readers for the two basin water-level loggers (upper and lower basin).

upper basin : UTF-16 text, tab separated, columns  No. / Date / mm:ss.s / depth [mm]  (0.3 s, 1 mm steps).
              The time column has no hour; the hour is taken from the lower logger (see load_run).
lower basin : Keyence NR-500 CSV (CP932). Data rows after '#EndHeader':
              'YYYY/MM/DD HH:MM:SS,<microseconds>,<level>' (0.1 s). The level comes from a 4-20 mA sensor
              scaled in the logger; the scaling is stored in the header (計測値1/2, 表示値1/2).

All times are returned as seconds since midnight of the recording day.
"""
import datetime as dt
import re

import numpy as np


def read_upper(path, hour):
    """Upper-basin logger -> (t_s, h_mm). `hour` is the hour of day (the file has none)."""
    raw = open(path, "rb").read().decode("utf-16").replace("\r\n", "\n").replace("\r", "\n")
    t, h = [], []
    prev, off = None, 0.0
    for line in raw.split("\n")[1:]:
        cells = line.split("\t")
        if len(cells) < 4 or not cells[3].strip():
            continue
        try:
            mm, ss = cells[2].split(":")
            sec = int(mm) * 60 + float(ss)
            val = float(cells[3])
        except ValueError:
            continue
        if prev is not None and sec + off < prev - 1000:
            off += 3600.0                      # the minutes field wrapped past the hour
        prev = sec + off
        t.append(hour * 3600.0 + sec + off)
        h.append(val)
    return np.array(t), np.array(h)


def read_lower(path):
    """Lower-basin logger (NR-500, CP932) -> (t_s, h_mm)."""
    raw = open(path, "rb").read().decode("cp932", errors="replace").replace("\r\n", "\n")
    lines = raw.split("\n")
    start = next(i for i, ln in enumerate(lines) if ln.startswith("#EndHeader")) + 1
    pat = re.compile(r"^(\d{4})/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d),(\d+),([-\d.]+)")
    t, h = [], []
    for ln in lines[start:]:
        m = pat.match(ln)
        if not m:
            continue
        t.append(int(m[4]) * 3600 + int(m[5]) * 60 + int(m[6]) + int(m[7]) / 1e6)
        h.append(float(m[8]))
    return np.array(t), np.array(h)


def read_lower_scaling(path):
    """(計測値1, 計測値2, 表示値1, 表示値2) from the NR-500 header, for comparing runs."""
    raw = open(path, "rb").read().decode("cp932", errors="replace").replace("\r\n", "\n").split("\n")
    vals = {}
    for ln in raw[:80]:
        for key in ("計測値1", "計測値2", "表示値1", "表示値2"):
            if ln.startswith(key + ","):
                vals[key] = float(ln.split(",")[-1])
    return tuple(vals.get(k, float("nan")) for k in ("計測値1", "計測値2", "表示値1", "表示値2"))


def load_run(upper_inflow, upper_outflow, lower_inflow, lower_outflow):
    """Load one measurement set -> {('upper'|'lower', 'inflow'|'outflow'): (t_s, h_mm)}.

    The upper record must start inside the lower record of the same mode; the hour of the upper
    logger is the lower start hour or the next one."""
    files = {("upper", "inflow"): upper_inflow, ("upper", "outflow"): upper_outflow,
             ("lower", "inflow"): lower_inflow, ("lower", "outflow"): lower_outflow}
    out = {}
    for mode in ("inflow", "outflow"):
        tl, hl = read_lower(files[("lower", mode)])
        out[("lower", mode)] = (tl, hl)
        base = int(tl[0] // 3600)
        placed = None
        for hour in (base, base + 1):
            tu, hu = read_upper(files[("upper", mode)], hour)
            if tl[0] - 5 <= tu[0] <= tl[-1] + 5:
                placed = (tu, hu)
                break
        if placed is None:
            raise ValueError(f"cannot place the upper record of {mode} inside the lower record")
        out[("upper", mode)] = placed
    return out


def clock(s):
    """Seconds since midnight -> 'H:MM:SS.s'."""
    return str(dt.timedelta(seconds=float(s)))[:10]

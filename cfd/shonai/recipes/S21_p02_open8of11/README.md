# レシピ S21_p02_open8of11 — 流入面の 8/11 だけから注水

P02_upper_half_inlet (6 列を塞ぎ 5/11 から注水, 流入 2.2 倍) と S19/S20 (傾けるだけ) の中間. 流入面の y 11 列のうち
y <= 0.9705 の 3 列 (12 面) を壁 `inletLowerWall` にし, 8 列 (32 面) から Q = 0.5 L/s を注水 (流入 1.375 倍).
`topoSetDict` の box の y 上限だけが P02 と違う. 確認: `log.pre_run` に `now size 12` と `Read 12 faces`.

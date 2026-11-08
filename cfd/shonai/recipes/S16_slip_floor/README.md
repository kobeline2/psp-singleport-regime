# S16_slip_floor — 床 (z = 0) の境界を noSlip から slip に

診断用 (物理設定ではない). 底面摩擦の軸を片側の極端条件で見る. 側壁・ポート壁・天井は noSlip のまま.
P02_upper_half_inlet と同じ型: topoSet で面を選び createPatch で `floor` パッチに分け,
0.orig/U に slip, p_rgh に fixedFluxPressure, alpha.water に zeroGradient を足す.
確認: `log.pre_run` に `now size 30389` と `30389 faces`.

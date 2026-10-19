# レシピ P02_upper_half_inlet — 流入面の上半分だけから注水

元ケース `psp_tests/P02_perturb_geom` (2026-07-25). 台帳は `cfd/cases.csv` の P02.

**何をするか**: 流入面 (導水路の上流端 x = -0.6, z < 0.02. 基準メッシュで y 11 列 x z 4 層 = 44 面) のうち,
y <= 1.00 の 6 列 (24 面) を壁 `inletLowerWall` にする. 注水は残りの 5 列 (y 1.005-1.055) だけになり,
流量は同じなので流入速度は約 2.2 倍. はっきりした片側注入.

| ファイル | 中身 |
|---|---|
| `system/topoSetDict`, `system/createPatchDict` | 面を選んで壁パッチにする |
| `system/pre_run.sh` | 上の 2 つを実行する (`run_case.sh` が自動で呼ぶ) |
| `0.orig/U`, `p_rgh`, `alpha.water` | テンプレート + `inletLowerWall` の項目 (noSlip / fixedFluxPressure / zeroGradient) |

**結果**: CFD で唯一, 単一の大循環ができた (反時計回り = 実験 R0008 と同じ向き). ただし渦はコンパクトで
盆地を満たさず, 壁にも付着しない. 浅水で効いた偏りは深水帯 (485-950 s) では残らない.
脈動は小さい (変動 10%, B03 は 48%). 完走 8.6 h. 動画は `psp_tests/_reference/cfd_P02_surface.mp4`.

**確認**: `log.pre_run` に `now size 24` と `Read 24 faces` (基準メッシュ). 細分メッシュでは面数が変わる.

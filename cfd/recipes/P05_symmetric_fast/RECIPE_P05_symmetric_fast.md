# レシピ P05_symmetric_fast — 左右対称のまま流入速度 2 倍

元ケース `psp_tests/P05_fastsym` (2026-07-27). 台帳は `cfd/cases.csv` の P05.

**何をするか**: 流入面 44 面のうち上 2 層 (z 0.01-0.02) の 22 面を壁 `inletUpperWall` にし,
下 2 層 (z < 0.01) の 22 面だけから注水する. y は全幅を残すので厳密に左右対称. 面積がちょうど半分になり,
流量は同じなので流入速度は 0.227 から 0.455 m/s. 注入の高さの中心は 0.010 から 0.005 m に下がる.
P02 の「定常になった」のが非対称のせいか速度のせいかを切り分けるためのケース.

| ファイル | 中身 |
|---|---|
| `system/topoSetDict`, `system/createPatchDict` | 面を選んで壁パッチにする |
| `system/pre_run.sh` | 上の 2 つを実行する (`run_case.sh` が自動で呼ぶ) |
| `0.orig/U`, `p_rgh`, `alpha.water` | テンプレート + `inletUpperWall` の項目 (noSlip / fixedFluxPressure / zeroGradient) |

**結果**: 対称の二渦のまま. 変動は B03 の 48% から 60% に増えた (速度 2 倍は脈動を止めない).
よって P02 で脈動が止まったのは非対称注入そのものの効果. 流速が上がるので時間刻みが縮み,
ステップ数は B03 の 1.46 倍, 完走 7.6 h.

**確認**: `log.pre_run` に `now size 22` と `Read 22 faces` (基準メッシュ). 細分メッシュでは面数が変わる.

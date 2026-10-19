# レシピ P04_port_block — ポート開口の端 1 列を壁にする

元ケース `psp_tests/P04_port_asym` (2026-07-26). 台帳は `cfd/cases.csv` の P04.

**何をするか**: 導水路と水槽の境のポート面 (x = 0, 開口 y 0.945-1.055, z 0-0.055) のうち,
y の最上端 1 cm (y 1.045-1.055, 全高) を厚さゼロの壁 (baffle) にする. 開口幅が 11 cm から 10 cm に減り,
左右非対称になる. 整流される距離がゼロの場所に置く「種」.

| ファイル | 中身 |
|---|---|
| `system/topoSetDict`, `system/createBafflesDict` | 面を選んで faceZone にし, 両面の壁にする |
| `system/pre_run.sh` | 上の 2 つを実行する (`run_case.sh` が自動で呼ぶ) |
| `0.orig/U`, `p_rgh`, `alpha.water` | テンプレート + `portTopWall_master` / `portTopWall_slave` の項目 |

ポート面は内部面なので `createPatch` では壁にできない (P04 の最初の試行は
`is not an external face of the mesh` で止まった). 内部面を壁にするときは `createBaffles` を使う.

**結果**: 全指標で失敗. 渦度マップは教科書的な上下対称の二渦で, ジェットは中心線を直進する.
偏り -0.010 (無摂動の B03 は +0.076). ポート面積 1/11 の閉塞は何も生まなかった. 完走 5.3 h.

**確認**: `log.pre_run` に `now size 11` と `Converted 11 faces` (基準メッシュ). 細分メッシュでは面数が変わる.

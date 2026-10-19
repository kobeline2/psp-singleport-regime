# recipes — 摂動・RANS ケースの組み方

小柴のキャンペーンで使った「テンプレートからの変更」のうち, 1 行では済まないものを
ファイル一式として置いてある. 中身は WS の参照ケース (`psp_tests/<ケース>`) の原本の写し.

## 使い方

```sh
bash cfd/tools/new_case.sh S03_p02_highflow          # テンプレートからケースを作る
cp -r cfd/recipes/P02_upper_half_inlet/. <ケース>/   # レシピを上書きコピー (README.md もコピーされるが無害)
#                                                       ここで自分の変更を 1 つ足す (例: flowRate)
bash cfd/tools/run_case.sh <ケース>
```

`system/pre_run.sh` があると, `run_case.sh` がメッシュ作成の直後 (初期水位の設定の前) に実行する.
流入面やポートの面を切り分ける手術 (topoSet → createPatch / createBaffles) はここに書く.

レシピの `0.orig/` などは**ファイルごと上書き**する. テンプレート側をその後に変えた場合は,
上書き後に `diff -r cfd/template/0.orig <ケース>/0.orig` で意図しない差が無いか見ること.

## 一覧

| レシピ | 元ケース | 中身 | 1 行で |
|---|---|---|---|
| `P02_upper_half_inlet/` | P02 | topoSet + createPatch, 新パッチの境界条件 | 流入面の下半分 (y < 1) を壁にし, 上半分だけから注水. 唯一単一渦になった |
| `P04_port_block/` | P04 | topoSet + createBaffles | ポート開口の 11 セルのうち端の 1 セルを壁に (整流距離ゼロの種) |
| `P05_symmetric_fast/` | P05 | topoSet + createPatch, 新パッチの境界条件 | 流入面の上 2 層を壁にし, 下 2 層 (z < 0.01) だけから注水. 対称のまま流速 2 倍 |
| `P06_rans/` | P06 | 乱流辞書, k / epsilon / nut, fvSolution / fvSchemes | RNG k-epsilon (低 Re 型壁関数) |

## 1 行で済む変更 (レシピなし)

| 変更 | ファイル | 例 |
|---|---|---|
| 運動量の移流スキーム | `system/fvSchemes` の `div(rhoPhi,U)` | `Gauss upwind;` (P07) / `Gauss linear;` (P08) |
| 流量 | `0.orig/U` の `flowRate` と `system/controlDict` の `endTime` | `0.00075` と `700` (D02) |
| 表面張力 | `constant/transportProperties` の `sigma` | `0` (N2, 未実施) |
| 時間スキーム | `system/fvSchemes` の `ddtSchemes` | `CrankNicolson 0.9;` (N3, 未実施) |
| WALE LES | `constant/turbulenceProperties` + `0.orig/nut` | B06 (効果は測定限界以下だった) |

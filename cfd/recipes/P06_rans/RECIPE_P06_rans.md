# レシピ P06_rans — RANS (RNG k-epsilon)

元ケース `psp_tests/P06_rans` (2026-07-27). 台帳は `cfd/cases.csv` の P06.

**何をするか**: 乱流モデルを laminar から RAS の RNG k-epsilon に変える. 壁は低 Re 型
(`kLowReWallFunction` / `epsilonWallFunction` / `nutLowReWallFunction`, y+ は 2-10 程度).
流入は k = 2e-4, epsilon = 2e-4 (乱流強度 5%). メッシュ手術は無いので `pre_run.sh` も無い.

| ファイル | 中身 |
|---|---|
| `constant/turbulenceProperties` | `simulationType RAS;` と `RASModel RNGkEpsilon;` |
| `0.orig/k`, `epsilon`, `nut` | 新しい場. 値の見積りはファイルのコメント |
| `system/fvSchemes` | テンプレート + `div(phi,k)`, `div(phi,epsilon)` の 2 行 |
| `system/fvSolution` | テンプレート + k / epsilon のソルバー (名前の正規表現に `.*` が必須) |

**結果**: 脈動は半減した (変動 48% から 22%). しかし上下対称の二渦は崩れず, むしろ laminar より
きれいな対称になった (偏り -0.036). 渦粘性は非定常性を抑えるが, 壁付着は生まない. 完走 6.6 h (B03 は 5.2 h).

**確認**: `bash cfd/tools/case_status.sh <ケース>` に `Selecting RAS turbulence model type RNGkEpsilon`
が出ること. 出なければ laminar のまま走っている.

**他のレシピと重ねるとき** (例: P02 + P06): ファイルは衝突しないので両方コピーしてよい. ただし
P02 などが作る壁パッチ (`inletLowerWall` 等) の項目を `0.orig/k`, `epsilon`, `nut` にも足すこと
(`walls` と同じ型でよい). 足さないと interFoam が起動時に `Cannot find patchField entry` で止まる.

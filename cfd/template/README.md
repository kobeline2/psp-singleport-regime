# Inflow (minimal) — 単一ポート注水の VOF 計算

`Downloads/Inflow` から、**計算を回すのに実際に必要なファイルだけ**を取り出したもの。
設定内容はパイロット計算(実時間 1000 s、壁時計 27.75 h)と機能的に同一で、
高速化のためのチューニングはまだ何も入れていない。

- ソルバー: `interFoam`(非圧縮 2 相 VOF)
- OpenFOAM: **ESI 版 v2412**(openfoam.com)。openfoam.org 版とは辞書名が違うので注意
- 形状: 水槽 3.0 x 2.0 m、メッシュ高さ 0.15 m + 導水路 x = -0.6〜0 m(幅 0.11 m、天端 0.055 m)
- メッシュ: 三角柱 1,112,520 セル(水平 15 mm / ポート付近 10 mm、鉛直 16 層 = **1 層 9.17 mm**)
- 流入: 0.5 L/s(`metadata/flow_levels.csv` の medium 相当)

## ファイル構成

```
Inflow_min/
├── Allrun                  実行手順そのもの(./Allrun で一気に流れる)
├── Allclean                計算結果を消して配布状態に戻す
│
├── 0.orig/                 初期条件 + 境界条件の「原本」
│   ├── U                     速度 [m/s]
│   ├── p_rgh                 修正圧力 p - rho*(g.x) [Pa]
│   └── alpha.water           水の体積分率 [-]
│
├── constant/               計算中ずっと変わらないもの
│   ├── g                     重力ベクトル
│   ├── transportProperties   水・空気の nu, rho と表面張力 sigma
│   ├── turbulenceProperties  乱流モデル(現在 laminar)
│   └── polyMesh/             メッシュ本体(points/faces/owner/neighbour/boundary)
│
├── system/                 数値計算の設定
│   ├── controlDict           時間制御・出力・実行中の後処理
│   ├── fvSchemes             各項の離散化スキーム
│   ├── fvSolution            線形ソルバーと PIMPLE ループ
│   ├── setFieldsDict         初期水位の与え方
│   └── decomposeParDict      MPI 並列分割
│
└── mesh/                   メッシュを作り直すとき用(通常は触らない)
    ├── tank.geo              gmsh のスクリプト
    └── fixBoundaryTypes.py   gmshToFoam 後に境界タイプを直す
```

`0.orig/` は OpenFOAM 公式チュートリアルの流儀。`setFields` が `0/alpha.water` を
上書きしてしまうため、原本を別に置き、実行のたびに `0.orig` -> `0` とコピーする。
元ケースに `alpha.water.bak` があったのはこれを手作業でやっていたため。

## 実行

```sh
./Allrun            # setFields -> decomposePar -> mpirun interFoam
```

個別に叩く場合:

```sh
cp -r 0.orig 0
setFields
decomposePar -force
mpirun -np 16 interFoam -parallel
```

`-np` の数は `system/decomposeParDict` の `numberOfSubdomains` と一致させること。
また**計算機の物理コア数を超えないこと**(超えると 20〜50 % 遅くなる)。

## 出力

| 出力 | 中身 |
|---|---|
| `processor*/<時刻>/` | 各プロセッサが持つ各時刻の場。5 s ごと |
| `postProcessing/waterVolume/0/volFieldValue.dat` | 水の総体積 [m3] を 20 ステップごと |
| `log.interFoam` | 毎ステップの Courant 数、残差、反復回数、経過時間 |

水位は `h = V / 6.066` [m](水槽 6.0 m2 + 導水路 0.066 m2)で概算できる。

## メッシュを作り直す場合

```sh
gmsh mesh/tank.geo -3 -o tank_prism.msh
gmshToFoam tank_prism.msh
python3 mesh/fixBoundaryTypes.py     # walls -> wall 型に直す
checkMesh
```

## 既知の注意点

1. **乱流モデル**: ESI 版が読むのは `constant/turbulenceProperties`(= `laminar`)。
   openfoam.org 版の `constant/momentumTransport` は**警告なく無視される**ので、
   そこに RNGkEpsilon と書いても効かない。元ケースはこれで取り違えが起きていた。
   本セットでは休眠していた `momentumTransport` / `phaseProperties` /
   `physicalProperties.*` / `0/k` / `0/epsilon` / `0/nut` をすべて削除してある。
   計算内容は元ケースと変わらない(もともと読まれていなかったため)。

2. **初期水位**: `setFieldsDict` の box は z < 0.02 m だが、鉛直 1 層が 9.17 mm なので
   実際に水になるのは下 2 層、初期水位は約 0.0183 m。解析対象は 0.03 m からなので、
   最初の約 140 s(壁時計で約 4 h)は解析に使わない区間を計算していることになる。

3. **鉛直分割**: `tank.geo` のコメントには「鉛直 5 mm」とあるが、実際の押し出しは
   6 層 + 10 層 = 16 層で **9.17 / 9.5 mm**。見積もりの際はコメントではなく実寸を使う。

4. **計算コスト**: 平均 dt = 7.4 ms、総ステップ 135,600、1 ステップ 0.74 s(16 並列)、
   合計 27.75 h。実時間に対して約 100 : 1。うち t = 500〜850 s の区間は
   `maxDeltaT = 0.01` の上限に張り付いている。

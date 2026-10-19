# template — 基準ケース B03 と同一の設定 (設定 v1)

新しいケースを作るための**原本**. ここでは実行しない. ケースは `cfd/tools/new_case.sh` で作り,
`cfd/tools/run_case.sh` で回す (手順と注意は `cfd/HANDOFF.md`).

- ソルバー: `interFoam` (非圧縮 2 相 VOF). **ESI 版 OpenFOAM v2412** (openfoam.com)
- 形状: 水槽 3.0 x 2.0 m (呼び値), 天井 0.13 m. 導水路 x = -0.6〜0 m (幅 0.11 m, 高さ 0.055 m)
- メッシュ: blockMesh 六面体 720,756 セル. 鉛直 5 mm (水柱内一様), 水平はポート近傍 10 mm・遠方 15 mm
- 流入: 導水路上流端の下 20 mm (44 面) から 0.5 L/s (`metadata/flow_levels.csv` の medium)
- 初期水位 20.00 mm の静水. 1000 s で 102 mm まで充填. 16 ランクで 5.2 h

## ファイル構成

```
template/
├── Allrun / Allclean       手で実行する場合の手順 (通常は cfd/tools/run_case.sh を使う)
├── 0.orig/                 初期条件と境界条件の原本
│   ├── U                     速度. 流入は variableHeightFlowRateInletVelocity (flowRate = Q)
│   ├── p_rgh                 修正圧力 p - rho*(g.x)
│   └── alpha.water           水の体積分率. 流入は fixedValue 1
├── constant/
│   ├── g                     重力
│   ├── transportProperties   水・空気の nu, rho と表面張力 sigma (0.07)
│   └── turbulenceProperties  乱流モデル (laminar)
├── system/
│   ├── controlDict           時間制御 (endTime 1000, 5 s ごと出力, binary) と水量の記録
│   ├── fvSchemes             離散化スキーム
│   ├── fvSolution            線形ソルバーと PIMPLE (nCorrectors 2)
│   ├── setFieldsDict         初期水位 (z < 0.02 m を水に)
│   ├── decomposeParDict      並列分割 (16, scotch)
│   └── surfSample            自由表面の流速をサンプリングする定義 (計算後に postProcess で使う)
└── mesh/
    ├── blockMeshDict         基準メッシュ (B01)
    ├── blockMeshDict_fine    水平 2 倍細分 (B07, 288 万セル)
    ├── blockMeshDict_zfine   鉛直 2.5 mm (B08, 138 万セル)
    └── tank.geo, fixBoundaryTypes.py   旧 gmsh 三角柱の手順. 新しいケースには使わない
```

`0.orig/` は OpenFOAM チュートリアルの流儀. `setFields` が `0/alpha.water` を上書きするので,
原本を別に置き, 実行のたびに `0.orig` → `0` とコピーする.

## 手で実行する場合の順序

```sh
cp mesh/blockMeshDict system/          # メッシュ定義を選ぶ
blockMesh && checkMesh                 # checkMesh が "Mesh OK" を返すこと
cp -r 0.orig 0 && setFields            # 基準メッシュなら "Selected 121556" (= 20.00 mm)
decomposePar -force
mpirun -np 16 interFoam -parallel
mpirun -np 16 postProcess -func surfSample -parallel
```

`-np` は `system/decomposeParDict` の `numberOfSubdomains` と一致させる.

## 出力

| 出力 | 中身 |
|---|---|
| `processor*/<時刻>/` | 各時刻の場. 5 s ごと (1 本で約 17 GB) |
| `postProcessing/waterVolume/0/volFieldValue.dat` | 水の総体積 [m3]. 質量保存の確認に使う |
| `postProcessing/surfSample/<時刻>/U_freeSurface.raw` | 自由表面の流速 (x y z Ux Uy Uz). 動画と判定指標の素材 |
| `log.interFoam` | 毎ステップの時間刻み, Courant 数, 残差, 経過時間 |

水位: h < 55 mm では `h = V / 6.066` (水槽 6.0 + 導水路 0.066 m2),
h > 55 mm では導水路が満管なので `h = 0.055 + (V - 0.3336) / 6.0`.

## 既知の注意点

- ESI 版が読む乱流辞書は `constant/turbulenceProperties`. openfoam.org 版の
  `momentumTransport` に書いても**警告なく無視される**
- そのほかのハマりどころは `cfd/HANDOFF.md` §10

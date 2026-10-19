# CLAUDE.md — cfd/template (基準ケース B03 と同一の設定の原本)

このディレクトリは新しいケースを作るための**原本**. ここで計算を実行しない.
ケースは `cfd/tools/new_case.sh` で作り, `cfd/tools/run_case.sh` で回す.
研究本体の規約はリポジトリ直下の `CLAUDE.md` と `AGENTS.md` に従う.

- 引き継ぎの入口: `cfd/HANDOFF.md` (場所・手順・ルール・ハマりどころ)
- これまでの結論: `cfd/campaign.md` (§0 結論, §2 全ケースの表, §3 指標の読み方)
- 2026-08 より前のこのファイルは旧メッシュ (三角柱) 時代の記述で, 多くが無効になった.
  経緯を知りたいときだけ `git log -p -- cfd/template/CLAUDE.md` と `cfd/campaign_log.md` を見る.

## 現行の設定 (設定 v1, 2026-07-22 確定. B03 で検証)

- interFoam, **ESI 版 OpenFOAM v2412**. laminar (乱流モデルなし), Euler,
  `div(rhoPhi,U) Gauss linearUpwind grad(U)`, MULES 陽解, PCG, nCorrectors 2
- 時間刻み: maxCo 1.0, maxAlphaCo 1.0, maxDeltaT 0.02 (A11/A12 で健全性確認)
- 流入: 導水路上流端の下 20 mm (44 面, 常時水没) から 0.5 L/s. alpha は `fixedValue 1`
- メッシュ: `mesh/blockMeshDict` (六面体 720,756 セル, 鉛直 5 mm, 水平 10-15 mm,
  y 方向は伸長比 1 で厳密な鏡像対称). 細分版 `blockMeshDict_fine` / `blockMeshDict_zfine`
- 初期水位 20.00 mm (setFields で 121,556 セル). 実験も 20 mm 静水から開始 (確認済み)
- 1000 s (水位 20 → 102 mm) で 5.2 h, 質量 99.5 %

## 今も有効な事実

- ESI 版が読む乱流辞書は `constant/turbulenceProperties`. openfoam.org 版の
  `momentumTransport` は**黙って無視される**
- **OpenFOAM は知らないキーワードを黙って読み飛ばす.** 設定が効いたかは必ずログで確認
  (`cfd/tools/case_status.sh` が選択されたモデルを表示する)
- `setFields` は `0/alpha.water` を上書きする. 原本は `0.orig/`. 実行ごとに `0.orig → 0`
- パッチ名 `inletOutlet` と BC 型名 `inletOutlet` は別物 (偶然の同名)
- メッシュの 3.0 x 2.0 m は呼び値. 実験水槽の内寸は 2.952 x 1.962 m (平面積 3.6 % 差,
  アスペクト比 0.31 % 差). 流量・水位の換算で実験と CFD の面積を混ぜない
- 導水路の高さ 55 mm = ポート高 a (実物と一致). 水位が a に達すると
  「ポート水没」と「導水路満管」が同時に起きる (装置の設計上分離できない)
- `mesh/tank.geo` と `mesh/fixBoundaryTypes.py` は旧 gmsh 三角柱の手順 (A00/X05 時代).
  新しいケースには使わない (全断面インレットに戻り, 流入が滝になる)

## 禁止事項

- y 対称の半領域にしない (対称性の破れを構造的に消す)
- 数値設定と物理設定を同じケースで同時に変えない (1 ケース 1 変更)
- ポート近傍の水平 10 mm を粗くしない (ジェット幅 0.11 m に 11 セルが下限)
- 参照ケース `~/OpenFOAM/yuna-v2412/run/psp_tests/` の中で何も実行しない (読み取り専用)

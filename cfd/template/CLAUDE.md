# CLAUDE.md — Inflow (単一ポート注水の VOF 計算)

このディレクトリは psp-singleport-regime 実験の数値計算コンパニオン (OpenFOAM ケース) である.
正本は repo の `cfd/template/`. 研究本体の規約はリポジトリ直下の `CLAUDE.md` と `AGENTS.md` に従う.
日本語の句読点は半角カンマ・ピリオド (`, .`) を使う.
注意: `constant/polyMesh` は git に入れない (147 MB). 実行環境では既存ケースからコピーするか
`mesh/tank.geo` から再生成して補う (手順は README.md).

## このケースの素性

- ソルバー: interFoam (非圧縮 2 相 VOF). **ESI 版 OpenFOAM v2412** (openfoam.com).
- 目的: 水槽 3.0 x 2.0 m, 単一ポート (幅 0.11 m, 高さ 0.055 m) の注水過程を再現し,
  表面速度場から実験と同じメトリクス (E, phi_lv, I_asym, I_circ, I_unst) を算出して比較する.
- 深さバンドと流量条件は repo の `metadata/depth_bands.csv`, `flow_levels.csv` が正.
- `Inflow_min` は完走パイロットと**機能的に同一**のクリーンな基準ケース.
  ファイル構成と実行手順は `README.md` を参照.

## 実行環境

- 本計算: koshiba-ws (Linux). ケースパス `/home/shonai/OpenFOAM/yuna-v2412/run/Inflow`.
  パイロットの全時刻データ (5 s ごと, 約 200 個) と `log.interFoam` は WS 側にのみある. 消さないこと.
- この Mac (M1 Max, 10 コア) は閲覧・編集用. OpenFOAM は未インストール.
- WS 実測 (2026-07-22): **Intel Core Ultra 9 285K, 24 コア (P8 + E16, HT なし), RAM 248 GB.**
  16 ランクはオーバーサブスクライブではない. P/E 混成なので最適ランク数は A06 で掃引.
- アカウント: koshiba (ユーザー) と shonai (学生・パイロット実行側). /home/shonai は 750 で
  koshiba から読めない → ログ・結果の共有は共有ディレクトリ経由にする (cfd/README.md 参照).
- 6 月の先行ケース (X01, 粗四面体, Foundation 版→ESI 版移行の痕跡) が
  koshiba@ws:~/OpenFOAM/yuna-v2512/run/tank に現存. 混入辞書の出どころはこれ.

## 確定した事実 (検証済み. 再調査不要)

### パイロット実測 (t = 0〜1000 s, 完走)
- 壁時計 27.75 h, 135,600 ステップ, 平均 dt 7.4 ms, 0.74 s/step (16 ランク).
- dt の推移: 序盤 ~2 ms → 単調増加 → **t = 500〜850 s は maxDeltaT 0.01 に張り付き** (全体の 26 %).
- 水位がポート天端 55 mm に達するのは t = 445 s. その直後に dt が上限到達.
- ステップ数などの数字は `postProcessing/waterVolume/0/volFieldValue_0.dat` から算出
  (`volFieldValue.dat` の方は放棄された別メッシュの残骸. 混同注意).

### メッシュ
- 三角柱 1,112,520 セル. 水平: 水槽 15 mm / ポート近傍 10 mm. 鉛直: **9.17/9.5 mm x 16 層**.
- `tank.geo` のコメント「鉛直 5 mm」は嘘. コメントは旧 5 mm 版の記述のまま.
- メッシュ変遷: 粗い四面体 (~11 万) → **一様 5 mm 三角柱 (2,085,578 セル, 遅すぎて t=0.72 s で放棄)**
  → 現行 9.17 mm (完走). 「一様 5 mm を試す」は既に失敗済みの道.
- バンド境界 (30, 50, 55, 60, 75, 100 mm) は 5 mm の倍数. 現行 9.17 mm 層では 55 mm しか
  セル面に乗らない. バンド B2 (幅 10 mm) は現行の鉛直解像度では実質分解できていない.

### 乱流設定 (重要)
- ESI 版が読むのは `constant/turbulenceProperties` = **laminar. パイロットは無モデルで走った.**
- openfoam.org 版の辞書 (`momentumTransport` = RNGkEpsilon 等) は**黙って無視されていた**.
  Inflow_min では休眠ファイル (momentumTransport, phaseProperties, physicalProperties.*,
  0/k, 0/epsilon, 0/nut) を削除済み. 計算内容は不変.
- **RNG k-epsilon URANS を「修正」として有効化しないこと.** メトリクスが測る解像非定常性
  (ジェット蛇行, 対称性破れ) を渦粘性が消す. 無モデル (粗い ILES) 継続が既定方針.
  格上げするなら WALE LES を検討.

### 初期水位とスピンアップ (2026-07 に方針確定)
- `setFieldsDict` の box z < 0.02 は**セル中心判定**で下 2 層が水になり, 実効初期水位 18.33 mm.
- これは意図的な選択: 実験は 0 mm から注水し 30 mm 到達時 (履歴 ~364 s) に PIV 開始.
  CFD は 18.33 mm 静止から 30 mm まで 142 s の発達時間を確保している.
- **「30 mm から始めて 7.4 h 節約」という案は撤回済み.** スピンアップが消えて実験と合わなくなる.
- ただし 142 s は実験の 364 s より短く, 循環 1 回転 (~250-300 s) 未満. 発達不足の懸念は残る.
  → 感度テストで決着させる (下記 TODO).

### 流入境界条件の相互作用
- `0/U` の variableHeightFlowRateInletVelocity は alpha で重み付けして流量配分する設計だが,
  `0/alpha.water` の inlet が fixedValue 1 のため**全断面一様 0.0826 m/s の注入**になっている.
- 結果, h < 55 mm では導水路内に落下流 (最大 ~0.85 m/s) が生じ, 序盤の dt を縛っている.
  実験の導水路に落下流はない. h が 55 mm に近づくほど差は消える.
- 教科書的ペアは alpha 側 variableHeightFlowRate. 変更するなら要検証.

### 文法・運用の教訓
- **OpenFOAM は知らないキーワードを黙って読み飛ばす.** 設定が効いているかは必ずログで確認.
  実例: 旧 setFieldsDict の `defaultValues` (正しくは `defaultFieldValues`) は無視されていた.
- `setFields` は `0/alpha.water` を上書きする. 原本は `0.orig/`, 実行は `./Allrun`.
- パッチ名 `inletOutlet` と BC 型名 `inletOutlet` は別物 (偶然の同名).

### 2026-07-22 WS 実地調査での重要な更新

- **パイロット (A00) の生データと log は WS 上から消失** (7/20 に Inflow ディレクトリが
  作り直しで上書き再利用されたため). Mac 側の postProcessing コピーと解析記録のみ残る.
  ケース不変則 (回したケースを編集しない) が必要な理由の実例.
- 学生が独自に**新メッシュ**を作成: 一様 5 mm プリズム, 天井を 0.13 m に下げて 1,809,830 セル.
  `tank.geo` のコメントと層数が今度は一致 (nLower 11, nUpper 15). **全バンド境界がセル面に一致**
  する良い方向. 六面体化 (シリーズ B) すれば同解像度で ~0.75M セルに減らせる余地は残る.
- 学生が **RAS RNGkEpsilon を有効化**して X05 を実行中 (endTime 300, 初期水位 20 mm = 4 層).
  本 CLAUDE.md の「RAS を有効化しないこと」と衝突 — 一方的に戻さず**学生と議論すること**.
  実測の懸念: bounding epsilon が 82% のステップで発生 (数値的ストレス),
  壁関数は y+ ~ 2-10 で適用範囲外の疑い.
- X05 実測: 1.68 s/step, 平均 dt 6.67 ms, p_rgh 反復 3.2/14.3/1.1 (計 18.6/step).
  → **GAMG の期待値は 1.2-1.5x に下方修正** (Final 補正はすでにほぼ無料).
- **質量収支NG → 原因特定 (A07/diff, 7/22)**: RAS はシロ (laminar でも 93.1%).
  真犯人は 7/21 の alpha 流入 BC 変更 (fixedValue 1 → variableHeightFlowRate).
  U 側 BC が U ∝ alpha で配分するため体積流束計は Q ちょうどでも
  **水の流束 = Q x (Σα²/Σα) < Q** となり, 界面がパッチを切る間 (h<0.055) 常に数%欠ける.
  **A08 で確定: fixedValue 1 に戻すと dV/dt = 100.0%** (代償: 落下流復活で dt 8.94→5.64 ms,
  浅水期の壁時計 +62%). 当面の方針 = fixedValue 1 (質量厳密は譲れない).
  恒久策 = B01 メッシュで常時水没の流入形状 (質量厳密と大 dt の両立).
- WS からの吸い上げ一式は Mac の `~/Downloads/ws_snapshot_20260722/Inflow_running/` に保存.
- **シリーズ A 完了 (7/22 夜)**: 確定設定 v1 = **laminar + alpha 流入 BC fixedValue 1 +
  nCorrectors 2 + PCG** (GAMG はこの構成では 3% 遅く不採用 — A10). 同レジーム単価で X05 比 ~1.7x,
  質量 100.0%. テストケース群は WS の `run/psp_tests/A07..A10`. 詳細は cfd/campaign.md の決定欄.
- **パイプライン全線開通 (7/23)**: B03 → surfSample → import_cfd_surface → s30/s31/s32 が
  無改造で完走し, band_metrics.csv に C0001 (=B03) の B1-B4 行が載った. CFD と実験が
  同一のメトリクス定義・同一の集計で比較可能になった. 詳細は campaign.md D 節.
- **シリーズ B 初戦合格 (7/22 深夜)**: B01 六面体メッシュ一発合格 (720,756 セル, 非直交 0,
  dict は repo `cfd/template/mesh/blockMeshDict`). B02 シェイクダウン全項目合格:
  **s/step 0.377, 壁:実時間 41:1 (X05 の 6 倍速), 質量 100.0%, 常時水没インレットで滝消滅**
  (序盤から dt≈10ms). 新たな律速は maxDeltaT 0.01 → cap 緩和 (A04/A05) を B メッシュ上で次に実施.

## 高速化プラン (検証済みの見積もり. 未適用)

方針: **変更は 1 つずつ. t=500 等からのリスタート ~20 s 区間で A/B 比較.**
健全性チェック = Min/Max(alpha), continuity error, waterVolume の傾き.

1. WS 物理コア数の確認 (全ての前提)
2. `log.interFoam` の p_rgh 反復回数を確認 → GAMG 効果の事前見積もり
3. p_rgh を PCG+DIC → **GAMG** (答えを変えない. 期待 1.3-1.8x)
4. `renumberMesh -overwrite` (答えを変えない. 期待 1.05-1.15x)
5. dt 緩和: maxCo/maxAlphaCo/maxDeltaT を**セットで**上げる + MULESCorr yes
   (答えを変えうる. 要検証. 期待 1.7-2.4x. sigma=0 も検討)
6. writeFormat binary + 表面サンプリング functionObject (3D 全場出力の削減)
7. **blockMesh 六面体化 + 鉛直 5 mm** (本命):
   z: 0〜0.11 m を 5 mm x 22 層 + 上部粗く, 水平は現行相当で**約 75 万セル**.
   現行より速く (面数 0.83x), かつ鉛直 1.83x 細かく, バンド境界が全てセル面に一致.
   検証は現行メッシュとの突き合わせ (総体積 0.90363 m3, パッチ面数, 初期水量).
8. 合計の現実的な見込み: 設定のみで ~3x, メッシュ込みで ~7-10x.

nCorrectors 3→2 は dt 緩和と排他 (大きい dt には 3 が必要). 両取りしない.

## TODO / 未決の論点

- [ ] WS の物理コア数・CPU 型番の確認
- [ ] `log.interFoam` から p_rgh 反復回数と Courant 履歴を抽出
- [ ] ParaView でパイロット t ≈ 140 s の表面速度場を確認: ジェット偏向が確立しているか
      (スピンアップ充足性の一次判定)
- [ ] スタート水位の感度テスト: 18.33 mm vs 27.5 mm で B1 の band-mean とメトリクスを比較.
      判定基準は実験の反復間ばらつき以下かどうか
- [ ] outflow ケースの流出 BC 設計 (variableHeightFlowRateInletVelocity の符号反転は設計外.
      flowRateOutletVelocity + 水相 or outletPhaseMeanVelocity. h < a の排水シェイクダウン必須)
- [ ] repo 側: `src/io/import_cfd_surface.m` を書けば CFD 平面が既存 s20→s30 パイプラインに
      そのまま乗る (canonical piv struct: x, y, u, v, typevector + meta. source='cfd')
- [ ] ケース一式を repo 管理下に移す検討 (dict 類は小さい. polyMesh は再生成可能なので除外)

## ケース管理 (2026-07 導入)

- 台帳と計画は repo 側: `psp-singleport-regime/cfd/{README.md, cases.csv, campaign.md}`.
  シリーズ A (ソルバー) → B (メッシュ) → C (スタート水位) → D (inflow 本番) → E (outflow).
- このディレクトリ (Inflow_min) は**テンプレート**. 直接実行せず `cp -r` で複製してから使う.
- 1 ケース 1 ディレクトリ. 回したケースは編集しない. 回す前に台帳へ行を足す.

## 禁止事項

- y 対称の半領域にしない (I_asym が測る対称性破れを構造的に消す)
- 数値設定と物理設定 (乱流モデル等) を同じリランで同時に変えない
- ポート近傍の水平 10 mm を粗くしない (ジェット幅 0.11 m に 11 セルが下限)
- WS のパイロット時刻データを消さない (mapFields 初期化・感度テストの資源)

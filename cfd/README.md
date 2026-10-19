# cfd/ — OpenFOAM ケース管理

実験の runs.csv と同じ発想で, CFD ケースを台帳駆動で管理する.
ケース本体 (重いデータ) は koshiba-ws に置き, ここには台帳と計画だけを置く.

**引き継いで自分で回す人は `HANDOFF.md` から読むこと** (場所・手順・ルール・ハマりどころ).

## ファイル

- `HANDOFF.md` — 引き継ぎの入口 (2026-10, shonai さん向けに作成)
- `cases.csv` — 小柴のケース台帳 (2026-07 キャンペーン). 1 ケース 1 行. これが正本
- `campaign.md` — キャンペーンの軸別の総括 (結論・全ケースの表・指標の読み方・棄却と訂正)
- `campaign_log.md` — 時系列の生記録 (撤回された判断も含む)
- `methods_audit.md` — 文献 (数値散逸・時間刻み) に照らした設定の監査
- `template/` — 基準ケース B03 と同一の設定の原本 (dict 類とメッシュ定義のみ.
  メッシュ本体 `constant/polyMesh` は git に入れず, 実行時に blockMesh で作る)
- `tools/` — ケースを作る・回す・見る道具 (`new_case.sh`, `run_case.sh`, `case_status.sh`,
  `surface_movie.py`). WS で動く. `surface_movie.py` は Python で, MATLAB 不要
- `recipes/` — 摂動・RANS ケースの組み方 (テンプレートに上書きするファイル一式)
- `shonai/` — shonai さんの台帳とメモ (ブランチ `shonai-cfd` 上にある)

## WS (koshiba-ws) のセットアップ

```sh
# 1. repo をクローン (共同利用者は GitHub の collaborator 登録が必要)
git clone https://github.com/kobeline2/psp-singleport-regime.git

# 2. ケースは repo の外に作る (結果データを git に近づけない). 道具が自動でやる
bash <repo>/cfd/tools/new_case.sh S01_example          # ~/OpenFOAM/yuna-v2412/run/psp_shonai/ に作る
bash <repo>/cfd/tools/run_case.sh <ケースのパス>       # メッシュ作成から表面サンプリングまで
```

メッシュは各ケースで `blockMesh` から作る (数秒). 古い手順 (既存 Inflow ケースから
polyMesh をコピー, gmsh の `tank.geo`) は三角柱 + 全断面インレットになり,
流入が滝になって時間刻みが潰れるので使わない (B04 の教訓).

## 3 台同期ルール (WS を含む)

- どのマシンでも作業前に `git pull`. `cases.csv` / `campaign.md` を更新したら commit + push
- 台帳は追記中心なのでコンフリクトは稀. 起きたら両方の行を残して整理
- ケース本体 (polyMesh, processor*, 時刻ディレクトリ, log) は絶対に git に入れない
  (`cfd/.gitignore` が保険として効いている)
- template の dict を変更したら: repo 側を編集 → push → WS で pull → WS の実行用 template に反映

## 運用ルール

1. **テンプレートは不変・実行しない.** 複製は `cp -r template <case_id>_<slug>`
2. **一度回したケースの設定は編集しない.** 変更 = 新ケース. 失敗ケースも削除せず
   台帳に failed / abandoned で残す (再調査防止. 文献管理の「入手メモ」と同じ思想)
3. **回す前に台帳に行を足す** (purpose を先に書く). 終わったら wall_h と verdict を書く
4. 各ケースディレクトリに `NOTES.md` を 1〜3 行置く (WS 単体でも素性が分かるように)
5. 変更は 1 ケースにつき 1 種類. 数値設定と物理設定を同時に変えない
6. 容量: 試行ランは `writeFormat binary` + `purgeWrite 3`.
   全時刻保存は参照ラン (A00 パイロットや本番 D/E) だけ
7. **継続ラン (リスタート) のチェックリスト** (A11 の初回クラッシュの教訓):
   `startFrom latestTime` に変更したか / `endTime` を更新したか / 参照ランと区間が一致するか /
   restart 時刻の場の BC を編集する場合は全プロセッサ分を python で置換したか
8. ランチャーは必ず `nohup` (または tmux) で切り離す — VPN や ssh が切れても計算は死なない

## CFD 結果を見る / 実験と比べる

**手早く見る (WS 上, MATLAB 不要)**: `python3 cfd/tools/surface_movie.py <ケース>` で
動画・平均場の図・判定指標 (campaign.md §2 の表と同じ定義. B03/P02/P09/R0006 で全桁一致を確認済み)
が `~/surface_movies/<label>_surface/` に出る. 実験側の参照 (R0006/R0008) も同じ道具で描ける
(`--frame-metrics` を渡す).

**実験側パイプライン (s30 以降) に通す (MATLAB)**:

1. OpenFOAM 側: `mpirun -np 16 postProcess -parallel -func surfSample -time '...'`
   (定義は `template/system/surfSample`. 実行中サンプリングなら controlDict の functions に追加)
2. `postProcessing/surfSample/` を Mac の `local/work/<run_id>/surfSample/` へ rsync
   (CFD ランは C0001 のような run_id で runs.csv 流儀の登録をする. piv_source='cfd')
3. MATLAB:
   `piv = import_cfd_surface("local/work/C0001/surfSample", 'run_id',"C0001");`
   `save(fullfile(cfg.WORK_DIR,'C0001',cfg.PIV_SINGLE_MAT), 'piv', '-v7.3');`
4. 以降 s30 (メトリクス) / s31 (水位マップ) / s32 (バンド集計) は無改造で動く
   (2026-07-23 に C0001 で実証済み). s33_compare_cfd_experiment.m で実験と比較:
   実測Q² (透過時間 Q=dV_band/T_band) で E を正規化し, 同 mode/flow の実験反復レンジと
   照合する. 比較用の CFD import は `C.metrics.omega_*` のグリッドに揃える (公平化).
   - 擬似 waterlevel.csv は waterVolume FO から生成 (生成ロジックは会話記録参照, 要スクリプト化).

## cases.csv のスキーマ

| 列 | 意味 |
|---|---|
| case_id | `<シリーズ><2桁>` 例 A01. X = 歴史的 (台帳導入前) |
| series | X / A (ソルバー高速化) / B (メッシュ) / C (スタート水位) / D (inflow 本番) / E (outflow) |
| status | planned / running / done / failed / abandoned |
| date | 実行日 YYYYMMDD |
| machine | koshiba-ws など |
| parent | 派生元 case_id (系譜. ブラッシュアップの鎖がこれで追える) |
| mesh | hex_5mm_h013 (基準 B01) / hex_fine_h013 (B07) / hex_z2.5mm_h013 (B08) / prism_* (旧) / tet_coarse (旧) |
| cells | セル数 |
| np | MPI ランク数 |
| delta | parent から変えた点 (1 フレーズ) |
| purpose | このケースが答える問い (先に書く) |
| sim_time_s | 計算した実時間 [s] |
| wall_h | 壁時計 [h] |
| verdict | 結果と判定 (1〜2 文). 次の行動が決まる書き方をする |

列を増やす場合はこの README も更新する (metadata/README.md と同じ規約).

# cfd/ — OpenFOAM ケース管理

実験の runs.csv と同じ発想で, CFD ケースを台帳駆動で管理する.
ケース本体 (重いデータ) は koshiba-ws に置き, ここには台帳と計画だけを置く.

## ファイル

- `cases.csv` — ケース台帳. 1 ケース 1 行. これが正本
- `campaign.md` — シリーズ (目的別のケース群) の計画と判定基準. Excel の「シート」に相当
- `template/` — クリーンな基準ケースの正本 (dict 類のみ, 84 KB).
  `constant/polyMesh` (147 MB) は git に入れない. 実行環境で補う (下記)
- `~/Downloads/Inflow_min` (Mac) は polyMesh 込みのローカルコピー. 設定の更新は repo 側を正とする

## WS (koshiba-ws) のセットアップ

```sh
# 1. repo をクローン (共同利用者は GitHub の collaborator 登録が必要)
git clone https://github.com/kobeline2/psp-singleport-regime.git

# 2. 実行ツリーは repo の外に作る (結果データを git に近づけない)
mkdir -p ~/OpenFOAM/$USER/run/psp && cd ~/OpenFOAM/$USER/run/psp
cp -r <repo>/cfd/template template

# 3. polyMesh を補う: 既存 Inflow ケースからコピー (または gmsh で再生成)
cp -r <既存Inflow>/constant/polyMesh template/constant/

# 4. 以後はテンプレート複製で運用
cp -r template A_solver/A01_gamg
```

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

## CFD 結果を実験側パイプライン (s30 以降) に通す

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
| mesh | tet_coarse / prism_5mm / prism_9mm / hex_5mm |
| cells | セル数 |
| np | MPI ランク数 |
| delta | parent から変えた点 (1 フレーズ) |
| purpose | このケースが答える問い (先に書く) |
| sim_time_s | 計算した実時間 [s] |
| wall_h | 壁時計 [h] |
| verdict | 結果と判定 (1〜2 文). 次の行動が決まる書き方をする |

列を増やす場合はこの README も更新する (metadata/README.md と同じ規約).

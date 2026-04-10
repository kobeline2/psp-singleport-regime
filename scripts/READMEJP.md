# scripts の使い方

このフォルダには、学生さんやプロジェクトメンバーが直接実行する MATLAB スクリプトを置いています。

方針として、スクリプトは大きな処理単位ごとの入口だけを担当し、細かい処理本体は `src/` に置くようにしています。学生さんは、まずこの `scripts/` のファイルを入口として使ってください。

## 現在あるスクリプト

- `s10_prepare_frames.m`
  前処理のメインスクリプトです。
  生動画を読み込み、`rectification.mat` を作成または更新し、rectified TIFF を出力し、さらに PIVLab 用の一時連番画像列も作成します。

- `s20_import_piv_results.m`
  `PIVlab_raw.mat` を canonical MATLAB 形式に取り込むスクリプトです。
  現在は `local/work/<run_id>/pivlab_single.mat` を保存します。

- `s25_preview_piv_movie.m`
  PIVLab の結果から確認用の動画を作る補助スクリプトです。
  主に流況の見た目確認用で、基本パイプラインの必須工程ではありません。

- `s30_compute_metrics.m`
  canonical PIV データから frame-wise / band-wise 指標を計算するための入口として予定しているスクリプトです。
  注意: 現在はまだプレースホルダで、実装途中です。

- `s40_make_paper_figures.m`
  論文用図を作るための入口として予定しているスクリプトです。
  注意: 現在はまだプレースホルダで、実装途中です。

## 学生さんが今ふつうに使うスクリプト

現時点で、学生さんが主に使うのは次の流れです。

1. `s10_prepare_frames.m`
2. PIVLab または外部 PIV ソフトで速度場を計算
3. `s20_import_piv_results.m` で canonical PIV を保存
4. その後の `s30`, `s40` は、対応機能が実装されてから使う

つまり、現在の実運用入口は `s10_prepare_frames.m` と `s20_import_piv_results.m` です。

## 実行前の確認

1. MATLAB はリポジトリのルートで開いてください。
2. 実験データは [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md) に従って `local/` に置いてください。
3. 対象の `runID` が `metadata/runs.csv` にあることを確認してください。
4. 実行前に、スクリプト冒頭の user settings を必ず見てください。

多くのスクリプトは内部で `init` を呼ぶので、通常は事前に `init` を手で実行しなくても大丈夫です。

`s10_prepare_frames.m` については、毎回変わる条件は
`local/settings/s10_prepare_frames_local.m`
で上書きできるようにしておくと、共有スクリプトを何度も編集せずに済みます。

## 学生さんの更新方法

このリポジトリは、コード改修は管理者 1 人が行い、学生さんは基本的に更新を受け取ってスクリプトを実行するだけ、という運用を前提にしています。

学生さんの通常手順は次の 2 行だけです。

```sh
git switch main
git pull --ff-only
```

注意:

- 管理者から指示がない限り、`main` 以外のブランチは使わないでください。
- 管理者から依頼されていない限り、リポジトリ内のコードは commit しないでください。
- `local/` は PC ごとのローカル作業領域です。別の PC の `local/raw/`、`local/work/`、`local/settings/` は Git では同期されません。

## `s10_prepare_frames.m` の使い方

[s10_prepare_frames.m](/Users/koshiba/Documents/git/psp-singleport-regime/scripts/s10_prepare_frames.m) を開いて、冒頭の設定を必要に応じて変更してください。

- `runID`
  処理対象の run を指定します。例: `"R0009"`

- `do_select_rectification`
  4点を新しく選び直す、または更新したいときは `true`
  既存の `rectification.mat` をそのまま使うときは `false`

- `rectification_frame_idx`
  rectification 用に点を選ぶフレーム番号です。

- `pivlab_variant`
  PIVLab 用一時画像フォルダ名に使われます。例: `tmp_pivlab_long`

- `opts`
  TIFF 出力条件です。フレーム範囲、フレーム間引き、前処理設定などをここで変えます。

- `pivlab_opts`
  PIVLab 用一時画像列の設定です。何フレームおきに使うか、何番から連番を始めるかなどをここで変えます。

これらを頻繁に変える場合は、共有スクリプト本体を毎回書き換えるより、
`local/settings/s10_prepare_frames_local.m`
を作って必要な変数だけ上書きする運用をおすすめします。

### `s10_prepare_frames.m` で作られるもの

たとえば `R0009` を処理すると、主に次の場所にファイルができます。

- `local/work/R0009/rectification.mat`
- `local/work/R0009/rectified_tif/`
- `local/work/R0009/tmp_pivlab_long/` などの variant 別一時フォルダ

## `s20_import_piv_results.m` の使い方

[s20_import_piv_results.m](/Users/koshiba/Documents/git/psp-singleport-regime/scripts/s20_import_piv_results.m) を開いて、主に次を確認してください。

- `runID`
  取り込み対象の run ID です。例: `"R0009"`

- `export_file`
  `local/work/<run_id>/` に置いた PIVLab MAT ファイル名です。
  現在の運用では `PIVlab_raw.mat` を使います。
  importer は最小限として
  `x`, `y`, `u_filtered`, `v_filtered`, `typevector_filtered`,
  `calxy`, `calu`, `calv`, `units`
  を残してください。

- `source_video_fps_hz`, `effective_sequence_fps_hz`, `export_step_frames`, `pair_step_frames`, `dt_pair_s`
  時間情報です。`local/work/<run_id>/piv_manifest.csv` に `export_file` と一致する行があれば、通常は `NaN` のままで構いません。

- `setting_file`, `session_file`, `preset_id`, `VDP`, `notes`
  追加の provenance 情報です。manifest に十分な情報がないときだけ書いてください。

### `s20_import_piv_results.m` で作られるもの

たとえば `R0009` なら、single-dt 用の canonical MAT として次が作られます。

- `local/work/R0009/pivlab_single.mat`

## Rectification の流れ

`do_select_rectification = true` のときは、動画フレーム上で次の順に 4 点をクリックします。

1. 左上
2. 右上
3. 右下
4. 左下

4点を選ぶと、その結果から幾何変換したプレビュー画像が表示されます。水域の形や縦横比が見た目に正しいと判断できるときだけ採用してください。

## 注意

- run フォルダ名は `metadata/runs.csv` の run ID と一致させてください。
- 生動画や TIFF 群は、方針変更がない限り `local/` の外に置かないでください。
- `s30`, `s40` はまだ日常運用向けではありません。
- エラーが出たときは、処理していた `runID` とエラーメッセージを保存して相談してください。

## 関連資料

- [local/README.md](/Users/koshiba/Documents/git/psp-singleport-regime/local/README.md)
- [README.md](/Users/koshiba/Documents/git/psp-singleport-regime/README.md)
- [piv_preprocessing_protocol.md](/Users/koshiba/Documents/git/psp-singleport-regime/doc/piv_preprocessing_protocol.md)

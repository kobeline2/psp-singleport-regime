# ORIGIN

このフォルダのファイルは別リポジトリから移行したもの。

| 項目 | 内容 |
|---|---|
| 移行元リポジトリ | `sho-yuna/pumped-storage-power-plants` (git@github.com:sho-yuna/pumped-storage-power-plants.git) |
| 移行元ブランチ | `master` |
| 移行元コミットID | `4b1e6a8e64fe641c18566c332e405470c55dcd37` |
| 移行元パス | `matlab/secondary_metrics/` |
| 移行先 | `kobeline2/psp-singleport-regime` の `shonai-cfd` ブランチ, `shonai/metrics/secondary/` |
| 移行日 | 2026-10-20 |

## コピーしたファイル

- `compute_divergence_sign.m` (変更なし)
- `compute_reattachment_length.m` (変更なし)
- `s38_compute_reattachment_divergence.m` (1 行のみ変更, 下記)
- `README.md` (変更なし。本文中の `pspRoot` 設定に関する記述は移行元のまま)

## 変更点

`s38_compute_reattachment_divergence.m` の 23 行目のみ。

```matlab
% 移行前
pspRoot = "PATH/TO/psp-singleport-regime";   % local clone, pull only
% 移行後
pspRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
```

このファイルは `<repo>/shonai/metrics/secondary/` にあるので、`fileparts` を 4 回適用するとリポジトリルートになる。
フォルダを移動した場合は `fileparts` の段数を合わせること。

## 備考

- 移行元の `master` ブランチのファイルは削除・変更していない。
- MATLAB での実行は未確認 (移行元 README の Status と同じ)。

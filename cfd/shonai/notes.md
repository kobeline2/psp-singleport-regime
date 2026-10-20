# shonai の CFD メモ

自分のケースの記録. 台帳 (1 ケース 1 行) は `cases.csv`, 考えたこと・見たことはここに書く.
書式は自由. 日付を見出しにして追記していくと後で追いやすい.

## 台帳 cases.csv の書き方

列は小柴の `cfd/cases.csv` と同じ. 最低限これだけ埋める:

| 列 | 書くこと |
|---|---|
| case_id | `S` + 2 桁の通し番号 (S01, S02, ...) |
| status | planned → running → done (落ちたら failed, 途中でやめたら abandoned. 消さずに残す) |
| parent | 何から変えたか. テンプレートそのままなら `B03` |
| mesh | `hex_5mm_h013` (base) / `hex_fine_h013` (fine) / `hex_z2.5mm_h013` (zfine) |
| delta | 変えたこと 1 つ (例: `sigma 0.07 -> 0`) |
| purpose | **回す前に**: 何が起きたら成功か (例: 偏りの移動平均が ±0.2 を 300 s 以上保持) |
| wall_h, verdict | 終わったら: かかった時間, 結果 1-2 文 (動画を見た印象 + metrics.txt の数字) |

---


## 2026-10-20 最初の 1 時間
- 動画ツール: B03 の指標が小柴の値と一致 (E_inst 0.000864, bias +0.076, lock 0.67)
- 試運転 S00_check (30 s): 1662 ステップ, 質量保存 100.00 %, laminar → 環境 OK (0.18 h)
- ffmpeg が WS に無い → 動画は GIF になる. 小柴に入れてもらう必要あり

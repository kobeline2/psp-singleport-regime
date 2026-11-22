# 根拠の控え — Methods 2.1 Facility と 2.2 Experimental programme

1 本目（JHR）の Methods 2.1「Facility」と 2.2「Experimental programme」を書くための事実の一覧である．原稿の文は書いていない．

- 作成：2026-11-22．行番号は同日の作業ツリー（ブランチ `cfd-campaign`，HEAD `b8295ed` に未コミットの変更が載った状態）のもの．`cfd/campaign.md` と `doc/settled_and_retracted.md` は未コミットの変更を含むので，行がずれていたら見出しで探す．
- パスはリポジトリのルートからの相対．「旧原稿」は凍結された `paper/2026_journal_Shonai/sections/methods.tex` を指す（素材としてだけ使う．撤回された記述を含む）．
- `local/` は PC ローカルで Git に載らない．数値はこの Mac の `local/` で計算した．
- status の意味
  - settled：`doc/settled_and_retracted.md` §1 に決着として載っているか，正本のファイル（定数，メタデータ，実装）で定まっている．
  - user-confirmed：ユーザーまたは実験者に確認した，という記録がある．
  - computed here：この控えを作るときに python3 で計算した（元の値の出どころは source の欄）．
  - unverified：記述はあるが，確認の記録が無い（旧原稿にだけある，索引にだけある，など）．
  - GAP：分からない．原稿では `\PH{…}` の空欄にする．探して埋めない．
  - provisional：仮の値（ν = 1.0e-6 m² s⁻¹）に基づく．
- 数値計算の結果は入れていない．`cfd/` のファイルを引いているのは，装置と手順についてユーザーと実験者に確認した記録がそこにあるためである．
- 範囲外：トレーサ粒子，照明，カメラ，PIV の条件，流量一定の検証の中身，深さの軸の切り替え，指標の定義．それぞれ別の控えで扱う．
- 流量一定の検証と深さの軸は，同じフォルダの `methods_discharge_depth.md`（Methods 2.3 の控え）が扱う．run 平均流量の値（inflow の比 0.745–0.891，水準ごとの中央値と平均）は，その控えの値と一致することを確かめた（2026-11-22）．

## 1. 水槽（basin）

| fact | value | source (file:line) | status |
|---|---|---|---|
| 平面の内寸 | 2.952 m（x，長手）× 1.962 m（y，短手）．実験者への確認で 295.2 cm × 196.2 cm と判明（2026-07-27） | `config/constants.m:16-22`，`AGENTS.md:98`，`doc/piv_conditions.md:55-57`，`doc/settled_and_retracted.md:25` | settled |
| 平面積 A | 5.7918 m²（2.952 × 1.962 = 5.791824） | `config/constants.m:24`，`AGENTS.md:98`，`doc/settled_and_retracted.md:25` | settled |
| 呼び寸法の扱い | 3.0 m × 2.0 m（6.0 m²）は平面積を 3.6% 過大にする．流量と正規化に使わない | `AGENTS.md:99-100`，`doc/settled_and_retracted.md:25`，`doc/piv_conditions.md:64` | settled |
| 深さ | 0.33 m．資料の語は「Basin depth」「深さ」（定数名は `C.basin.H_m`）だけである．これが壁の高さ（内法）を指すとは，どの資料も書いていない | `config/constants.m:23`，`AGENTS.md:101`，`README.md:22`，旧原稿 `methods.tex:7` | settled（正本の定数．測った記録は無い）．「壁の高さ」と読むのは unverified（監査で訂正） |
| 形 | 浅い矩形の水槽 | `README.md:7`，旧原稿 `methods.tex:7` | settled |
| 収録中の水深と水槽の深さ | 水深 0.03–0.10 m は水槽の深さ 0.33 m の 9–30% | 上の行と `config/constants.m:52-54` から計算 | computed here |
| 形の比 | L/W = 1.505，W/b = 17.84，L/b = 26.84，h/W = 0.015–0.051，L/h = 29.5–98.4（L = 2.952 m，W = 1.962 m，b = 0.11 m，h = 0.03–0.10 m） | 寸法から計算（L/W = 1.5046 は `doc/piv_conditions.md:95` にもある） | computed here |
| 1 run の体積変化 | A × 0.070 m = 0.4054 m³（405.4 L） | 計算 | computed here |
| 材質，底と壁の仕上げ（粗さ），水平の精度 | 記録が無い | — | GAP |

## 2. port

| fact | value | source (file:line) | status |
|---|---|---|---|
| 幅 b | 0.11 m | `config/constants.m:44`，`AGENTS.md:102`，`README.md:24` | settled |
| 高さ a | 0.055 m | `config/constants.m:45`，`AGENTS.md:103`，`README.md:25`，`metadata/README.md:49` | settled |
| 断面積 a b | 0.00605 m² | `config/constants.m:47` | settled |
| 下端の高さ | 水槽の底面（z = 0） | `config/constants.m:46`，旧原稿 `methods.tex:7` | settled |
| 平面の位置 | 短辺の壁の中央．噴流の横ずれの計算は port の軸を y = 0.981 m（= W/2）に置いている | `README.md:23`，`scripts/checks/jet_offset_by_band.py:9,26`，旧原稿 `methods.tex:7` | unverified（中央にあることを測った記録は無い） |
| 可逆の単一 port | 同じ port を inflow と outflow に使う | `README.md:7,23`，旧原稿 `methods.tex:7` | settled |
| 相対水深の範囲 | h = 0.03–0.10 m は h/a = 0.545–1.818 | 計算（`metadata/depth_bands.csv:2-5` は 0.55 と 1.82） | computed here |
| port の内部と縁（仕切り板，壁の厚さ，角の形） | 記録が無い．数値計算の作業記録（2026-07-25 の節）に，学生への確認項目として「導水路の加工精度, ポート内 3 枚の仕切り板の左右対称性, ホース接続の偏り, 流入口近傍の水路壁の仕上がり」とあるが，確認の結果は記録されていない | `cfd/campaign_log.md:563-564` | GAP |

## 3. 座標系

| fact | value | source (file:line) | status |
|---|---|---|---|
| 軸 | x：水槽の長手，y：短手，z：鉛直上向き | `AGENTS.md:106-109`，`config/constants.m:67-71`，旧原稿 `methods.tex:7` | settled |
| 原点 | 定義として書いた所は無い．解析領域の範囲（x = 0.045–2.909 m，y = 0.041–1.929 m．格子は port のある壁から約 45 mm 内側に始まる）と port の軸 y = 0.981 m から，x は port のある壁から，y は一方の側壁から測っていることになる | `config/constants.m:106-114`，`scripts/checks/jet_offset_by_band.py:9` | unverified（暗黙の取り決め） |
| y の向き（どちらの側壁が y = 0 か）と循環の符号 | 旧原稿は「解析座標系($x$ 右向き, $y$ 上向き ...)」とだけ書く．符号の規約は指標の控えで扱う | 旧原稿 `methods.tex:223`，`doc/metrics_primer.md:92` | unverified |

## 4. 給水路と h = a の交絡

| fact | value | source (file:line) | status |
|---|---|---|---|
| 給水路の形式 | 開水路（自由水面を持つ）．圧力管ではない．実験者への照会（2026-07-31） | `cfd/campaign_log.md:41-42`，`paper/README.md:141` | user-confirmed |
| 給水路の断面の高さ | 55 mm．port の高さ a と厳密に同じ | `cfd/campaign_log.md:43`，`paper/README.md:141-142`，`cfd/campaign.md:226` | user-confirmed |
| 交絡 | 水位が a に達した瞬間に，(1) port の潜没（水没）と (2) 給水路の満管が必ず同時に起きる．装置の設計による | `paper/README.md:141-144`，`cfd/campaign_log.md:56-62`，`doc/settled_and_retracted.md:24`，`cfd/campaign.md:242-243` | settled（2026-07-31） |
| 原稿に書くこと | h/a ≈ 1 前後の指標の変化を論じる箇所では，どちらの機構によるかを本装置では判定できない旨を明記する．分離には給水路の高さを変える改造が要る（将来の課題） | `paper/README.md:145-146`，`cfd/campaign_log.md:63-65` | settled |
| 給水路の上流 | 「給水路の上流はまっすぐで曲がりなし, 整流はあるが粗い.」（ユーザー確認 2026-11-15） | `cfd/campaign.md:407`，`doc/settled_and_retracted.md:30` | user-confirmed |
| 給水路の幅と長さ，材質 | 実物の値の記録が無い．リポジトリにある 0.6 m × 0.11 m は数値計算の格子の寸法で，実物と照合したのは高さだけである（使わない） | `cfd/campaign_log.md:45-47` | GAP |
| 整流の方法（何を，どこに置いたか） | 「整流はあるが粗い」より詳しい記録が無い | `cfd/campaign.md:407` | GAP |
| 水の回路（ポンプ，下池，配管，給水路への入れ方） | 記録が無い．下池があること（`doc/qdip_jet_check.md:17-19`）と，確認項目の中の「ホース接続」（`cfd/campaign_log.md:564`）だけが手がかり | `doc/qdip_jet_check.md:17-19`，`cfd/campaign_log.md:563-564` | GAP |
| outflow の水の経路と駆動 | 記録が無い．「排水の駆動方式によっては水深で変わりうる」とあるだけ | `doc/qdip_jet_check.md:110-111`，`cfd/campaign.md:274` | GAP |

## 5. 水位計

| fact | value | source (file:line) | status |
|---|---|---|---|
| 機種と方式 | KEYENCE FR-S01．60 GHz のレーダー式（ミリ波レーダー）．超音波式ではない | `doc/qdip_jet_check.md:20`，`doc/settled_and_retracted.md:19,44`，`cfd/campaign.md:309` | settled（2026-11-14．ロガーのヘッダーとユーザー確認） |
| ログのヘッダー | 24 run とも「モジュール 001 Port1 FR-S01 現在値」 | `local/raw/R0001/waterlevel.csv:1` ほか 24 ファイル | computed here（ファイルを読んで確認） |
| 取り付け位置 | port（inlet）に対面する壁の際．測っているのは実験の水槽（資料では「上池」）の水位 | `doc/qdip_jet_check.md:20`，旧原稿 `methods.tex:46`，`cfd/campaign.md:307` | settled |
| 中心線の上かどうか | 索引は「ポート対面の中心線上」と書く．正本は「inlet 対面の壁際」だけで，中心線とは書いていない | `doc/settled_and_retracted.md:19`，`doc/qdip_jet_check.md:20` | unverified |
| 高さ | レンズは床から約 0.50 m | `doc/qdip_jet_check.md:21`，`cfd/campaign.md:309` | settled |
| 水面までの距離 | 0.40–0.47 m（水深 0.10–0.03 m に当たる） | `doc/qdip_jet_check.md:21`，旧原稿 `methods.tex:46` | settled |
| 仕様の精度 | ±1 mm（0.3–1.5 m の区分）．推奨の取り付けで静的な水のときの保証値で，波立った水面を壁際で見る今回の条件はその外にある | `doc/qdip_jet_check.md:21-26`，`cfd/campaign.md:309` | settled |
| 読みの刻み | 1 mm | `doc/qdip_jet_check.md:117`，`scripts/s31_map_waterlevel.m:28-29` | settled |
| 記録の間隔 | 平均 0.310–0.312 s（約 3.2 Hz）．時刻の欄は 0.1 s 刻みの「分:秒」で，時の桁が無い | `local/raw/R0001`–`R0024/waterlevel.csv`（標本の数と始終の時刻から計算），`src/io/read_waterlevel.m:18-21` | computed here |
| 分かっている読みの狂い | h ≈ 45–55 mm で泡と水面の乱れにより読み違える．流量一定とした直線に対し，読みは h/a ≈ 1 付近で inflow 最大 −9 〜 −11 mm，outflow −4 〜 −6 mm ずれる | `doc/settled_and_retracted.md:19`，`doc/qdip_jet_check.md:32-38` | settled（中身は流量の検証と深さの軸の控えで扱う） |
| 絶対値の検証 | 読みの端点（30 mm と 100 mm）が正しいかは未検証 | `doc/settled_and_retracted.md:23,55`，`doc/qdip_jet_check.md:109`，`paper/README.md:156-160` | GAP（未決） |
| 壁からの距離，ロガーとアンプの機種，平均化や応答の設定，零点の合わせ方 | 記録が無い | — | GAP |

## 6. 流量の設定と 3 水準

| fact | value | source (file:line) | status |
|---|---|---|---|
| 流量の設定方法 | 「流量はポンプの Hz で設定.」（ユーザー確認 2026-11-15）．バルブ開度ではない | `cfd/campaign.md:407-408`，`doc/settled_and_retracted.md:30`，`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:163-165` | user-confirmed |
| 目標の水位変化率 | low 2.5，medium 5.0，high 7.5 mm/min | `metadata/flow_levels.csv:2-4`，`metadata/runs.csv:3-26`（nominal_dh_mm_min の列），`README.md:29-32` | settled |
| 名目流量 Q_n | low 0.25，medium 0.50，high 0.75 L/s | `metadata/flow_levels.csv:2-4`，`README.md:33-36` | settled |
| 名目流量の性格 | ポンプを合わせる目標の値（ラベル）で，実測ではない | `doc/notes_2d3d_collaboration.md:86-88`，`cfd/campaign.md:310`，`cfd/campaign_log.md:597` | settled |
| 水位変化率と名目流量の対応 | 0.25 / 0.50 / 0.75 L/s は，2.5 / 5.0 / 7.5 mm/min に呼びの平面積 6.0 m² を掛けた値にちょうど一致する．実測の 5.7918 m² では 0.2413 / 0.4827 / 0.7240 L/s で，3.6% 食い違う | `metadata/flow_levels.csv:2-4`，`metadata/README.md:75`，`doc/piv_conditions.md:64,80-81`，計算 | computed here |
| 流量の測り方 | 流量を直接測る計器の記録は無い．run の流量は水位計の読みと平面積から出す | `metadata/README.md:77,94`，`src/metrics/compute_branch_statistics.m:37-38` | 流量計の有無は GAP |
| inflow の run の中の流量 | 各 run でほぼ一定．走行中のランプは無い | `doc/settled_and_retracted.md:16,40`，`doc/qdip_jet_check.md:10-28` | settled |
| outflow の run の中の流量 | 一定かどうかは別に確かめる必要がある，と記録されている | `doc/qdip_jet_check.md:110-111`，`cfd/campaign.md:274` | unverified |
| ポンプの機種，各水準の周波数の値，日ごとに合わせ直したか | 記録が無い | — | GAP |
| outflow の流量の設定方法 | 「ポンプの Hz で設定」が outflow にも当てはまるかの記録が無い | `cfd/campaign.md:407-408`，`doc/qdip_jet_check.md:110-111` | GAP |

## 7. 24 run の構成

| fact | value | source (file:line) | status |
|---|---|---|---|
| run の数 | 24（inflow 12，outflow 12）．mode ごとに 3 水準 × 4 反復 | `metadata/runs.csv:3-26` | settled |
| run の状態 | `runs.csv` に載る 24 run は，どれも run_status = done，exclude_flag = FALSE である（表に載った 24 run の中に除外は無い）．ただし，表に載らないやり直しの痕跡がある（次の行）．原稿に「除外した run は無い」「全ての試行を採用した」とは書かない | `metadata/runs.csv:3-26` | settled（表の中身に限る．監査で訂正） |
| 表に載らない試行（やり直し） | `local/raw/Failure/` に「R0016 waterlevel.csv」がある．Date の欄は 2026-06-18，読みは 100 mm から 30 mm，標本は 4836 個，始終の時刻の差は 1499.9 s である．採用された R0016 は 2026-06-24 の記録である．R0024 にも「6/26にやり直す」のメモがあり，採用された記録は 2026-07-03 である．やり直した試行の数，理由，採否の基準は記録が無い | `local/raw/Failure/R0016 waterlevel.csv`（1–2 行と末尾の行），`metadata/runs.csv:18,26`，`local/raw/a.txt:26`，`local/raw/R0024/waterlevel.csv:2` | computed here（監査で追加）．数と理由は GAP |
| inflow の日程 | 4 日（2026-04-16，04-20，04-21，04-22）．各日に low，medium，high を 1 run ずつ．反復の番号は日の順 | `metadata/runs.csv:3-14` | settled |
| 計画の型 | 日をブロックとする乱塊法（randomized complete block design）．4 ブロック × 3 水準で，各水準が各ブロックに 1 回 | `paper/README.md:113`，`cfd/campaign.md:409`，`doc/settled_and_retracted.md:30`，旧原稿 `methods.tex:11` | 構成は settled（`runs.csv`），乱塊法という呼び名は user-confirmed |
| 1 日の中の順番 | 「1 日の中の run の順番は乱塊法 (順番の交絡はない).」（ユーザー確認 2026-11-15） | `cfd/campaign.md:409`，`doc/settled_and_retracted.md:30` | user-confirmed |
| 各日の実際の順番 | 記録が無い．`runs.csv` の planned_order は 1–24 の通し番号のままで，実施の順ではない（列の説明は「Planned execution order. Can be updated after randomization.」）．水位計のログの時刻には時の桁が無く，順番を復元できない．なお，`runs.csv` が名前を挙げる runlog.md と動画（piv.mp4，timelapse.mp4）は，この Mac の `local/raw/R0001`–`R0024/` には無い（24 フォルダとも waterlevel.csv だけ）．「記録が無い」は，リポジトリとこの Mac について言えることである | `metadata/runs.csv:1-26`，`metadata/README.md:7`，`local/raw/R0001/waterlevel.csv:2`，`src/io/read_waterlevel.m:18-21`，`local/raw/R0001`–`R0024/`（ファイルの一覧） | GAP（ほかの PC の記録は unverified by audit） |
| 同じ日の run の間隔と，間の処置（排水，待ち時間） | 記録が無い | — | GAP |
| outflow の日程 | 採用された 12 run は，12 の異なる日に 1 日 1 run（2026-05-20 から 07-03）．日によるブロックは無い．ほかに，不採用の試行が少なくとも 1 つある（2026-06-18．上の「表に載らない試行」の行） | `metadata/runs.csv:15-26`，旧原稿 `methods.tex:11` | settled（採用された 12 run について） |
| outflow の順 | 日付の順に high，low，medium，low，high，medium，high，low，medium，medium，low，high．順を無作為に決めたかの記録は無い | `metadata/runs.csv:15-26` を並べ替え | computed here（無作為化は GAP） |
| 日付の照合 | `runs.csv` の日付は，水位計のログの Date の欄と 24 run とも一致する | `metadata/runs.csv:3-26`，`local/raw/R00xx/waterlevel.csv:2` | computed here |
| inflow と outflow の時期 | inflow は 4 月，outflow は 5 月下旬から 7 月初め．inflow の最後（04-22）から outflow の最初（05-20）まで 28 日 | `metadata/runs.csv:3-26` | computed here |
| 実施者 | `runs.csv` の operator の列は 24 run とも空 | `metadata/runs.csv:3-26` | GAP |
| 局所の予定表 | `local/raw/schedule.xlsx`（2026-06-25 更新）は R0024 を 2026-06-26 としている．`runs.csv` と水位計のログは 2026-07-03．同じ場所のメモに「R0024 〇 6/26にやり直す」とある | `local/raw/schedule.xlsx`（B25），`local/raw/a.txt:26`，`metadata/runs.csv:26`，`local/raw/R0024/waterlevel.csv:2` | unverified（日付は runs.csv とログに従う） |

24 run の一覧（T と Q は 9 節の方法で計算．status：日付と水準は settled，T と Q は computed here）．

| run | mode | 水準 | 反復 | 日付 | 収録時間 T (s) | T (min) | Q (L/s) | Q/Q_n | 平均の水位変化率 (mm/min) | `metadata/runs.csv` の行 |
|---|---|---|---|---|---|---|---|---|---|---|
| R0001 | inflow | low | 1 | 2026-04-16 | 1859.9 | 31.00 | 0.2180 | 0.872 | 2.26 | 3 |
| R0002 | inflow | low | 2 | 2026-04-20 | 1820.6 | 30.34 | 0.2227 | 0.891 | 2.31 | 4 |
| R0003 | inflow | low | 3 | 2026-04-21 | 1846.6 | 30.78 | 0.2195 | 0.878 | 2.27 | 5 |
| R0004 | inflow | low | 4 | 2026-04-22 | 1958.8 | 32.65 | 0.2070 | 0.828 | 2.14 | 6 |
| R0005 | inflow | medium | 1 | 2026-04-16 | 1005.4 | 16.76 | 0.4032 | 0.806 | 4.18 | 7 |
| R0006 | inflow | medium | 2 | 2026-04-20 | 1001.9 | 16.70 | 0.4047 | 0.809 | 4.19 | 8 |
| R0007 | inflow | medium | 3 | 2026-04-21 | 1087.9 | 18.13 | 0.3727 | 0.745 | 3.86 | 9 |
| R0008 | inflow | medium | 4 | 2026-04-22 | 1064.5 | 17.74 | 0.3809 | 0.762 | 3.95 | 10 |
| R0009 | inflow | high | 1 | 2026-04-16 | 639.9 | 10.67 | 0.6336 | 0.845 | 6.56 | 11 |
| R0010 | inflow | high | 2 | 2026-04-20 | 641.5 | 10.69 | 0.6320 | 0.843 | 6.55 | 12 |
| R0011 | inflow | high | 3 | 2026-04-21 | 659.7 | 11.00 | 0.6145 | 0.819 | 6.37 | 13 |
| R0012 | inflow | high | 4 | 2026-04-22 | 678.8 | 11.31 | 0.5973 | 0.796 | 6.19 | 14 |
| R0013 | outflow | low | 1 | 2026-05-26 | 1627.0 | 27.12 | 0.2492 | 0.997 | 2.58 | 15 |
| R0014 | outflow | low | 2 | 2026-05-31 | 1716.0 | 28.60 | 0.2363 | 0.945 | 2.45 | 16 |
| R0015 | outflow | low | 3 | 2026-06-14 | 2050.0 | 34.17 | 0.1978 | 0.791 | 2.05 | 17 |
| R0016 | outflow | low | 4 | 2026-06-24 | 2077.7 | 34.63 | 0.1951 | 0.781 | 2.02 | 18 |
| R0017 | outflow | medium | 1 | 2026-05-29 | 906.2 | 15.10 | 0.4474 | 0.895 | 4.63 | 19 |
| R0018 | outflow | medium | 2 | 2026-06-04 | 902.2 | 15.04 | 0.4494 | 0.899 | 4.66 | 20 |
| R0019 | outflow | medium | 3 | 2026-06-16 | 900.9 | 15.02 | 0.4500 | 0.900 | 4.66 | 21 |
| R0020 | outflow | medium | 4 | 2026-06-22 | 934.9 | 15.58 | 0.4336 | 0.867 | 4.49 | 22 |
| R0021 | outflow | high | 1 | 2026-05-20 | 583.6 | 9.73 | 0.6947 | 0.926 | 7.20 | 23 |
| R0022 | outflow | high | 2 | 2026-06-02 | 578.2 | 9.64 | 0.7011 | 0.935 | 7.26 | 24 |
| R0023 | outflow | high | 3 | 2026-06-06 | 593.6 | 9.89 | 0.6830 | 0.911 | 7.08 | 25 |
| R0024 | outflow | high | 4 | 2026-07-03 | 595.3 | 9.92 | 0.6811 | 0.908 | 7.06 | 26 |

inflow のブロックの構成（出どころ：`metadata/runs.csv:3-14`．Q は 9 節）．

| ブロック（日） | 日付 | low | medium | high |
|---|---|---|---|---|
| 1 | 2026-04-16 | R0001（反復 1，Q = 0.218 L/s，Q/Q_n = 0.872） | R0005（反復 1，Q = 0.403 L/s，Q/Q_n = 0.806） | R0009（反復 1，Q = 0.634 L/s，Q/Q_n = 0.845） |
| 2 | 2026-04-20 | R0002（反復 2，Q = 0.223 L/s，Q/Q_n = 0.891） | R0006（反復 2，Q = 0.405 L/s，Q/Q_n = 0.809） | R0010（反復 2，Q = 0.632 L/s，Q/Q_n = 0.843） |
| 3 | 2026-04-21 | R0003（反復 3，Q = 0.220 L/s，Q/Q_n = 0.878） | R0007（反復 3，Q = 0.373 L/s，Q/Q_n = 0.745） | R0011（反復 3，Q = 0.615 L/s，Q/Q_n = 0.819） |
| 4 | 2026-04-22 | R0004（反復 4，Q = 0.207 L/s，Q/Q_n = 0.828） | R0008（反復 4，Q = 0.381 L/s，Q/Q_n = 0.762） | R0012（反復 4，Q = 0.597 L/s，Q/Q_n = 0.796） |

outflow の日付順の並び（出どころ：`metadata/runs.csv:15-26`．Q は 9 節）．

| 日付順 | 日付 | run | 水準 | 反復 | Q (L/s) | Q/Q_n |
|---|---|---|---|---|---|---|
| 1 | 2026-05-20 | R0021 | high | 1 | 0.695 | 0.926 |
| 2 | 2026-05-26 | R0013 | low | 1 | 0.249 | 0.997 |
| 3 | 2026-05-29 | R0017 | medium | 1 | 0.447 | 0.895 |
| 4 | 2026-05-31 | R0014 | low | 2 | 0.236 | 0.945 |
| 5 | 2026-06-02 | R0022 | high | 2 | 0.701 | 0.935 |
| 6 | 2026-06-04 | R0018 | medium | 2 | 0.449 | 0.899 |
| 7 | 2026-06-06 | R0023 | high | 3 | 0.683 | 0.911 |
| 8 | 2026-06-14 | R0015 | low | 3 | 0.198 | 0.791 |
| 9 | 2026-06-16 | R0019 | medium | 3 | 0.450 | 0.900 |
| 10 | 2026-06-22 | R0020 | medium | 4 | 0.434 | 0.867 |
| 11 | 2026-06-24 | R0016 | low | 4 | 0.195 | 0.781 |
| 12 | 2026-07-03 | R0024 | high | 4 | 0.681 | 0.908 |

## 8. 収録した水深の範囲と開始の手順

開始の手順は宣言済みの空欄である（`paper/README.md:83-87`）．下の表は資料が言っていることをそのまま並べたもので，どれが正しいかは決めていない．**「静水から開始した」とは書かない**（`doc/settled_and_retracted.md:30,48`）．

| fact | value | source (file:line) | status |
|---|---|---|---|
| 解析に使う水深の範囲 | 0.03–0.10 m（h/a = 0.55–1.82） | `config/constants.m:52-54`，`AGENTS.md:104`，`metadata/flow_levels.csv:2-4`（depth_range_m），`metadata/depth_bands.csv:2-5` | settled |
| 収録の向き | inflow は 0.03 m → 0.10 m，outflow は 0.10 m → 0.03 m | `metadata/runs.csv:3-26`（start_depth_m，end_depth_m），`README.md:26-28` | settled |
| start_depth_m の意味 | 「Water depth at the start of recording.」 | `metadata/README.md:15-16` | settled（メタデータの定義） |
| 格納されている水位計のログ | 24 run とも，最初の読みが 30 mm（inflow）か 100 mm（outflow），最後の読みが 100 mm か 30 mm．読みが 20–30 mm の区間を含むログは無い | `local/raw/R0001`–`R0024/waterlevel.csv`（先頭と末尾の行） | computed here |
| 格納されている PIV の時間軸 | 24 run とも，`frame_metrics.csv` の先頭の行は depth_m = 0.03（inflow）か 0.10（outflow），末尾は 0.10 か 0.03 | `local/derived/metrics/R00xx/frame_metrics.csv` | computed here |
| ログと動画の対応づけ | 両者を同じ区間の記録とみなし，正規化した時間で対応させる（ログの時刻そのものは使わない） | `src/metrics/assign_depth_bands.m:21-28`，`src/io/read_waterlevel.m:18-21` | settled（実装） |
| ログと PIV の長さの差 | 21 run で 0.61 s 以下．R0006 は 6.30 s，R0022 は 1.46 s，R0010 は 1.29 s（どれもログのほうが長い．ログの時刻は 0.1 s 刻み） | 計算（ログの始終の時刻と `frame_metrics.csv` の time_s）．R0006 の 6.2 s は `doc/qdip_jet_check.md:178-179` にもある | computed here |
| 始点の後の読みの戻り | R0005，R0009，R0011 では，読みが 30 mm で始まった後に 29 mm まで下がる | `local/raw/R0005`，`R0009`，`R0011/waterlevel.csv`（最小値 29），`frame_metrics.csv`（depth_m の最小 0.029） | computed here |
| inflow の初期の状態 | 静水ではない．「初期水位は注入しながら水位計を見て, 20 mm になったらすぐ撮影開始 (静水で待たない).」（ユーザー確認 2026-11-15） | `cfd/campaign.md:407-408,313`，`doc/settled_and_retracted.md:30,48` | user-confirmed |
| 撮影の前の噴流 | R0006 は撮影開始の時点で噴流が既に曲がっていた（分枝は撮影の前に選ばれうる） | `doc/settled_and_retracted.md:22`，`paper/README.md:130` | settled（2026-11-22） |
| 撮影を始めた水位 | 資料が食い違う．(a) ユーザー確認（2026-11-15）は 20 mm．(b) 旧原稿と 2026-07-25 の記録は 30 mm（「PIV は 30 mm 到達時点から記録する」）．(c) 格納された記録は 30 mm から始まる | (a) `cfd/campaign.md:408`．(b) 旧原稿 `methods.tex:13`，`doc/notes_2d3d_collaboration.md:92`，`cfd/campaign_log.md:598-599`．(c) 上の 2 行．空欄の宣言は `paper/README.md:85` | GAP |
| inflow の注水を始めた水位 | 記録が無い．2026-07-25 の「20 mm の静水から注水を開始し」は，静水の部分が撤回されており，注水を始めた水位としても確認されていない | `doc/notes_2d3d_collaboration.md:92`，`doc/settled_and_retracted.md:48`，`paper/README.md:85` | GAP |
| outflow の開始 | 100 mm の静水から始めたかどうかの記録が無い．旧原稿は「outflow では \SI{0.10}{m} から撮影を開始し」とだけ書く | `paper/README.md:85-86`，旧原稿 `methods.tex:13` | GAP |
| run の間の残留流の確認 | 旧原稿は，タイムラプスの動画と E(t) の基準（停止直前の 5% 未満が 5 分以上）で確かめたと書く．定数と手順書に痕跡はあるが，全 run で実際に行った記録は無い．`runs.csv` が名前を挙げる timelapse.mp4 は，この Mac の `local/raw/` には無い．inflow の「静水開始」は撤回済み | 旧原稿 `methods.tex:51,126`，`config/constants.m:117-119`，`doc/piv_preprocessing_protocol.md:20`，`metadata/runs.csv:3-26`（timelapse_video_file の列），`doc/settled_and_retracted.md:48` | unverified（書かない） |
| 局所のメモ | `local/raw/a.txt` に「R0008 短」「R0010 短」「R0015 〇スタート未定→逆算」「R0022 短 カット済み」とある．意味は確認されていない | `local/raw/a.txt:9,11,17,24` | unverified |

開始の手順について未解決の問い（どれも `\PH{…}` にする）．

1. inflow の注水を始めたときの水槽の状態（空か，残り水か，その水位）．
2. inflow の撮影を始めた水位は 20 mm か 30 mm か．「20 mm」「30 mm」は水位計の読みか．
3. 20 mm で撮影を始めたのなら，20–30 mm の区間を動画とログから切り落としたのか（格納された記録は 24 run とも 30 mm か 100 mm から始まる）．切り落としたのなら，誰がどの基準で切ったか．
4. ポンプの周波数を撮影の前に固定し，100 mm まで触らなかったか．注水の開始から 30 mm までにかかった時間．
5. outflow を始めたとき水槽は静水だったか．排水を始めた水位は 100 mm か，それより上か．
6. outflow の前にどうやって水を張ったか（同じ port から注水したか）．張り終えてから排水までの待ち時間．
7. outflow の駆動の方式（ポンプか自然流下か）と，その流量の設定方法．
8. run と run の間の待ち時間と水位の戻し方．残留流の確認（5%，5 分の基準とタイムラプス）を実際に行ったか．
9. `local/raw/a.txt` の「短」「カット済み」「スタート未定→逆算」の意味．

## 9. run 平均流量

| fact | value | source (file:line) | status |
|---|---|---|---|
| 定義 | Q = A × Δh / T．Δh は収録区間の水深変化の大きさ，T は収録時間．run 全体で 1 つの値 | `src/metrics/compute_branch_statistics.m:37-38,101-105`，`doc/qdip_jet_check.md:50-51`，旧原稿 `methods.tex:36` | settled |
| 原稿で引く流量 | run 平均（`branch_stats.csv` の Q_run_mean_Lps）．帯ごとの水位由来の流量は使わない | `doc/settled_and_retracted.md:17`，`paper/README.md:119-120`，`src/metrics/compute_branch_statistics.m:40-52` | settled |
| ここでの計算 | A = 5.791824 m²．Δh と T は `frame_metrics.csv` の先頭と末尾の行の depth_m と time_s．Δh は 24 run とも 0.070 m | `local/derived/metrics/R00xx/frame_metrics.csv`，`config/constants.m:24` | computed here |
| 名目に対する比 | inflow 0.745–0.891，outflow 0.781–0.997 | 計算．既存の記載は「公称の 0.75-0.89 倍」（`doc/settled_and_retracted.md:16`），「inflow 0.75-0.89 倍, outflow 0.78-1.00 倍」（`doc/qdip_jet_check.md:51`） | computed here（既存の記載と一致） |
| inflow の照合 | 12 run とも `branch_stats.csv` の Q_run_mean_Lps と一致（差の最大 5e-16 L/s）．outflow はこの表に無いので照合の相手が無い | `local/derived/metrics/branch_stats.csv:2-13` | computed here |
| 「0.219 / 0.392 / 0.623 L/s」の中身 | 各水準 4 run の中央値（0.2188 / 0.3921 / 0.6233）である．算術平均は 0.2168 / 0.3904 / 0.6193．索引などは「ラン平均」と呼んでいる | `doc/settled_and_retracted.md:16`，`doc/metrics_primer.md:28`，計算 | computed here（原稿でどちらを書くかを決める） |
| medium の R0007 と R0008 | 0.3727 と 0.3809 L/s．差は 2.2%．medium の 4 run は 0.373–0.405 L/s | 計算．`paper/README.md:116-118` と一致 | computed here |
| 同じ水準の中のばらつき（inflow） | (最大 − 最小)/平均は low 7.2%，medium 8.2%，high 5.9%．4 日目（04-22）は low と high でその水準の最小 | 計算 | computed here |
| outflow の low のばらつき | 0.249，0.236（5 月）と 0.198，0.195 L/s（6 月）に分かれ，幅は平均の 24.6% | 計算 | computed here |
| 時間の取り方による差 | T を水位計のログの長さに替えると，Q は R0006 で −0.62%，R0022 で −0.25%，R0010 で −0.20%，残りの 21 run は 0.11% 以内 | 計算 | computed here |
| 読みの刻みによる粗さ | Δh = 70 mm に対し読みの刻みは 1 mm（1.4%） | `doc/qdip_jet_check.md:117`，計算 | computed here |
| 給水路の平面積 | この Q は，h < a で水位とともに満ちる給水路の平面積を無視している．約 1% と見積もられているが，見積もりは給水路の長さを 0.6 m と仮定したもので，実物の長さは確認されていない | `src/metrics/compute_branch_statistics.m:44-45`，`doc/piv_conditions.md:132` | unverified |
| 絶対値 | Δh は水位計の 30 mm と 100 mm の読みに頼っており，水位計の span は未検証．「名目の 0.75–0.89 倍」もこの前提を引き継ぐ．下池の平面積を 1 回測るか，静的な較正を 1 回行えば閉じる | `paper/README.md:156-160`，`doc/settled_and_retracted.md:23,55`，旧原稿 `methods.tex:23-32` | GAP（未決） |
| 実験者の予定表の流量 | `local/raw/schedule.xlsx` の「5.5-10.0cm 流量(L/s)」（0.215–0.821 L/s）は，水深 5.5–10.0 cm の区間の所要時間（D 列）から出した区間の流量で，撤回された種類の量である．45 mm × 呼びの平面積 6.0 m² ÷ D 列の時間 で，23 run のうち 22 run の値を 0.001 L/s 以内で再現できる（R0009 だけは 0.828 になり，表の 0.821 と合わない）．D 列の時間は，outflow の 9 run（R0014–R0020，R0022，R0023）で，水位計のログの先頭行の余白に書かれた時間（R0014 は 17:09.0）と一致するので，水位計のログから読んだ時間とみられる | `local/raw/schedule.xlsx`（D1–E24），`local/raw/R0014/waterlevel.csv:2` ほか，`doc/settled_and_retracted.md:17,42`，計算 | 使わない（監査で根拠を追加） |

水準ごとのまとめ（Q の単位は L/s．比は Q/Q_n．computed here）．

| mode | 水準 | Q_n (L/s) | Q 最小 | Q 最大 | Q 平均 | Q 中央値 | 比 最小 | 比 最大 | 比 平均 | (最大 − 最小)/平均 |
|---|---|---|---|---|---|---|---|---|---|---|
| inflow | low | 0.25 | 0.207 | 0.223 | 0.217 | 0.219 | 0.828 | 0.891 | 0.867 | 7.2% |
| inflow | medium | 0.50 | 0.373 | 0.405 | 0.390 | 0.392 | 0.745 | 0.809 | 0.781 | 8.2% |
| inflow | high | 0.75 | 0.597 | 0.634 | 0.619 | 0.623 | 0.796 | 0.845 | 0.826 | 5.9% |
| outflow | low | 0.25 | 0.195 | 0.249 | 0.220 | 0.217 | 0.781 | 0.997 | 0.878 | 24.6% |
| outflow | medium | 0.50 | 0.434 | 0.450 | 0.445 | 0.448 | 0.867 | 0.900 | 0.890 | 3.7% |
| outflow | high | 0.75 | 0.681 | 0.701 | 0.690 | 0.689 | 0.908 | 0.935 | 0.920 | 2.9% |

## 10. 収録時間

| fact | value | source (file:line) | status |
|---|---|---|---|
| 収録時間 T | `frame_metrics.csv` の time_s の末尾 − 先頭．下の表 | `local/derived/metrics/R00xx/frame_metrics.csv` | computed here |
| 名目の所要時間 | low 28.0，medium 14.0，high 9.33 min（70 mm を目標の水位変化率で割った値） | `metadata/flow_levels.csv:2-4`（nominal_duration_min） | settled |
| 平均の水位変化率 | 70 mm / T．目標の率（2.5 / 5.0 / 7.5 mm/min）に対する比は，名目流量に対する比より 3.6% 大きい（6 節の食い違いのため） | 計算 | computed here |

| mode | 水準 | T 最小 (s) | T 最大 (s) | T 平均 (s) | T 平均 (min) | T の範囲 (min) | 名目の所要時間 (min) | 平均の水位変化率 (mm/min) 範囲 | 同 平均 | 目標の率に対する比 |
|---|---|---|---|---|---|---|---|---|---|---|
| inflow | low | 1820.6 | 1958.8 | 1871.5 | 31.19 | 30.34–32.65 | 28.0 | 2.14–2.31 | 2.25 | 0.858–0.923 |
| inflow | medium | 1001.9 | 1087.9 | 1039.9 | 17.33 | 16.70–18.13 | 14.0 | 3.86–4.19 | 4.04 | 0.772–0.838 |
| inflow | high | 639.9 | 678.8 | 655.0 | 10.92 | 10.67–11.31 | 9.33 | 6.19–6.56 | 6.42 | 0.825–0.875 |
| outflow | low | 1627.0 | 2077.7 | 1867.7 | 31.13 | 27.12–34.63 | 28.0 | 2.02–2.58 | 2.27 | 0.809–1.033 |
| outflow | medium | 900.9 | 934.9 | 911.1 | 15.18 | 15.02–15.58 | 14.0 | 4.49–4.66 | 4.61 | 0.898–0.932 |
| outflow | high | 578.2 | 595.3 | 587.7 | 9.79 | 9.64–9.92 | 9.33 | 7.06–7.26 | 7.15 | 0.941–0.968 |

## 11. port の代表流速と無次元数

| fact | value | source (file:line) | status |
|---|---|---|---|
| U_p の定義 | U_p = Q_n / (a b)．Q_n はその水準の**名目**流量．指標の正規化（u_th = 0.2 U_p，I_circ と I_rot の a/U_p）はこの U_p を使っている | `scripts/s30_compute_metrics.m:46-59,61-63,77-78`，`src/metrics/compute_frame_metrics_circ.m:4-5,61`，`doc/metrics_primer.md:23-25,89`，`config/metrics_defaults.m:12-16`，`paper/2026_journal_Shonai/jhr/notation.tex:25`．`frame_metrics.csv` の low_speed_threshold_m_s は R0001 で 0.008264 m/s = 0.2 × 0.25e-3/0.00605（名目）で，実装のとおりである | settled（実装） |
| U_p の値 | low 0.0413，medium 0.0826，high 0.1240 m/s | 計算（medium の 0.0826 m/s は `doc/metrics_primer.md:25` にもある） | computed here |
| 物理の議論での流量 | 物理のスケーリングを論じるときは run 平均の実測値を使う，とされている | `doc/metrics_primer.md:26-29` | settled |
| 無次元数の定義（JHR の原稿） | R = U_p a / ν，F = U_p / sqrt(g h) | `paper/2026_journal_Shonai/jhr/notation.tex:31-32`．旧原稿 `methods.tex:107-116` も Fr = U_p / sqrt(g h) | settled（notation.tex） |
| g と ν | g = 9.81 m s⁻²．ν = 1.0e-6 m² s⁻¹ は仮の値（「use updated value later if temperature correction is needed」） | `config/constants.m:60-61` | ν は GAP |
| 水温 | 記録が無い | `paper/README.md:90`，`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:69-71` | GAP |
| Reynolds 数の扱い | ν が仮の値なので**暫定**．R は 1/ν に比例する．inflow（4 月）と outflow（5 月下旬から 7 月初め）は時期が違うので，同じ ν とは限らない | `metadata/runs.csv:3-26`，`config/constants.m:61` | provisional |
| Froude 数の水深 | F は h に依存し，1 run の中で h = 0.03 m から 0.10 m まで変わる．下の表は h = a，0.03 m，0.10 m の 3 つを示す | 計算 | computed here |
| h < a での port の出口の流速 | h < a では port の出口の平均流速は Q/(b h) で，Q/(a b) の a/h 倍になる（h = 0.03 m で 1.83 倍）．U_p は代表の尺度であって，h < a の実際の流速ではない | `doc/qdip_jet_check.md:132`，計算 | computed here |

下の表は ν = 1.0e-6 m² s⁻¹，g = 9.81 m s⁻²，a = 0.055 m，b = 0.11 m で計算した（computed here．R は暫定）．名目の行が U_p，R，F の定義どおりの値で，run 平均の行は Q_n を run 平均流量に替えたものである．

| 水準 | 流量の取り方 | Q (L/s) | Q/(ab) (m/s) | R = (Q/ab) a/ν | F（h = a） | F（h = 0.03 m） | F（h = 0.10 m） |
|---|---|---|---|---|---|---|---|
| low | 名目 Q_n（U_p） | 0.25 | 0.0413 | 2273 | 0.056 | 0.076 | 0.042 |
| low | inflow の run 平均（4 run の平均．括弧は最小–最大） | 0.217（0.207–0.223） | 0.0358（0.0342–0.0368） | 1971（1882–2024） | 0.049（0.047–0.050） | 0.066（0.063–0.068） | 0.036（0.035–0.037） |
| low | outflow の run 平均（4 run の平均．括弧は最小–最大） | 0.220（0.195–0.249） | 0.0363（0.0323–0.0412） | 1996（1774–2265） | 0.049（0.044–0.056） | 0.067（0.059–0.076） | 0.037（0.033–0.042） |
| medium | 名目 Q_n（U_p） | 0.50 | 0.0826 | 4545 | 0.113 | 0.152 | 0.083 |
| medium | inflow の run 平均（4 run の平均．括弧は最小–最大） | 0.390（0.373–0.405） | 0.0645（0.0616–0.0669） | 3549（3388–3679） | 0.088（0.084–0.091） | 0.119（0.114–0.123） | 0.065（0.062–0.068） |
| medium | outflow の run 平均（4 run の平均．括弧は最小–最大） | 0.445（0.434–0.450） | 0.0736（0.0717–0.0744） | 4046（3942–4091） | 0.100（0.098–0.101） | 0.136（0.132–0.137） | 0.074（0.072–0.075） |
| high | 名目 Q_n（U_p） | 0.75 | 0.1240 | 6818 | 0.169 | 0.229 | 0.125 |
| high | inflow の run 平均（4 run の平均．括弧は最小–最大） | 0.619（0.597–0.634） | 0.1024（0.0987–0.1047） | 5630（5430–5760） | 0.139（0.134–0.143） | 0.189（0.182–0.193） | 0.103（0.100–0.106） |
| high | outflow の run 平均（4 run の平均．括弧は最小–最大） | 0.690（0.681–0.701） | 0.1140（0.1126–0.1159） | 6273（6192–6374） | 0.155（0.153–0.158） | 0.210（0.208–0.214） | 0.115（0.114–0.117） |

## 12. 実機との関係（prototype，scaling）

| fact | value | source (file:line) | status |
|---|---|---|---|
| 位置づけ | 実機を参照した室内実験（prototype-informed laboratory experiment）．特定の実機の厳密な縮尺模型ではない．相似を言い過ぎない | `AGENTS.md:218`，`README.md:7`，旧原稿 `methods.tex:103`，`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:144` | settled |
| 旧原稿の説明 | 揚水発電の上池の可逆の取放水運転を念頭に設計した．「実在する揚水発電上池を参考に, basin の代表長さ, 平均水深, および運転流量のオーダーを整理した.」 | 旧原稿 `methods.tex:103,105` | unverified |
| 参照した実機の名前と数値 | 旧原稿は 1 つも挙げていない．リポジトリのほかの場所にも無い | 旧原稿 `methods.tex:100-119` | GAP |
| 縮尺比 | 記載が無い | 旧原稿 `methods.tex:100-119` | GAP |
| 水深の範囲を決めた理由 | 旧原稿：「低水深側では表面張力や画像計測上の不安定性を避けつつ, $h/a \approx 1$ 近傍を十分に含むように定めたものである.」 | 旧原稿 `methods.tex:105` | unverified |
| Froude 数による条件の設定 | 旧原稿は，Fr = U_p / sqrt(g h) を「参照しながら流量条件を設定した」と書く．実際の水準は水位変化率 2.5 / 5.0 / 7.5 mm/min で決めてあり，Froude 数から決めた記録は無い | 旧原稿 `methods.tex:107-117`，`metadata/flow_levels.csv:2-4`，`README.md:29` | unverified |
| Reynolds 数 | 旧原稿：Reynolds 数を含むすべての無次元量を実機と同時に一致させることは意図していない | 旧原稿 `methods.tex:117` | unverified（方針は `AGENTS.md:218` と合う） |
| 主な整理の変数 | 旧原稿は，幾何の関係，相対水深 h/a，代表的な Froude 数を挙げる．1 本目の今の重心は流量による分枝の選択で，h/a の転換は従 | 旧原稿 `methods.tex:119`，`paper/README.md:55-59`，`doc/settled_and_retracted.md:21` | 重心は settled |

## Conflicts with the old manuscript

旧原稿は `paper/2026_journal_Shonai/sections/methods.tex`（凍結）．

| # | 旧原稿の記述（行） | 今の立場 | 正本 | 扱い |
|---|---|---|---|---|
| 1 | 「流量の調整はバルブ開度によって行った」（L9） | 流量はポンプの周波数（Hz）で設定した | `cfd/campaign.md:407-408`，`doc/settled_and_retracted.md:30`，`paper/2026_journal_Shonai/jhr/CONVENTIONS.md:163-165` | 書かない |
| 2 | 「各 run は静水状態から開始した.」（L51） | inflow は静水ではない（注入を続けたまま撮影を始めた）．outflow は不明 | `doc/settled_and_retracted.md:30,48`，`paper/README.md:85-87` | 書かない．開始の手順は `\PH{…}` |
| 3 | 残留流の確認：「$E(t)$ が停止直前値の \SI{5}{\percent} 未満となり, その状態が \SI{5}{min} 以上継続」（L51），「静水開始条件の確認には別途タイムラプス撮影を行い」（L126） | 全 run で実際に行った記録が無い．2 と一緒に空欄 | `config/constants.m:117-119`（基準の値だけがある） | 書かない |
| 4 | 「inflow では水深 \SI{0.03}{m} に達した時点で撮影を開始し」（L13） | ユーザー確認（2026-11-15）は「20 mm になったらすぐ撮影開始」．格納された記録は 30 mm から．未解決 | `cfd/campaign.md:408`，`paper/README.md:85`，8 節 | `\PH{…}` |
| 5 | 「実際の流量は水深および開口の没水状態に応じて名目値からずれる」（L21） | 流量は各 run でほぼ一定．名目からのずれは run 全体でほぼ一定の倍率（0.75–0.89）．水深による変化は水位計の見かけ | `doc/settled_and_retracted.md:16,40-42` | 書かない |
| 6 | 名目流量 0.25 / 0.50 / 0.75 L/s が水位変化率 2.5 / 5.0 / 7.5 mm/min に「対応する」（L19-20） | 対応は呼びの平面積 6.0 m² でしか成り立たない．実測の平面積では 3.6% 食い違う | 6 節（計算），`doc/piv_conditions.md:64,80-81` | どちらが設定の目標だったかは GAP |
| 7 | 表 `tab:run_conditions` の脚注：「The actual discharge was steady within each run」（L74-78） | inflow は決着．outflow は一定かどうかを別に確かめる必要がある，と記録されている | `doc/qdip_jet_check.md:110-111`，`cfd/campaign.md:274` | outflow については断定しない |
| 8 | inflow の block 計画（L11） | 日付と構成は `runs.csv` と一致．旧原稿には 1 日の中の順番（乱塊法）の記述が無い | `metadata/runs.csv:3-14`，`cfd/campaign.md:409` | 乱塊法を足す．実際の順番は GAP |
| 9 | 「一方 outflow は 1 日 1 run の日程で実施した」（L11） | `runs.csv` の日付と一致（12 run が 12 の異なる日） | `metadata/runs.csv:15-26` | そのまま使える |
| 10 | 水位計：60 GHz レーダー式（KEYENCE FR-S01），inlet に対向する壁際，水面まで 0.40–0.47 m（L46） | 一致．足せるのはレンズの高さ（床から約 0.50 m）と読みの刻み（1 mm） | `doc/qdip_jet_check.md:20-21,117` | そのまま使える |
| 11 | 寸法，平面積 5.79 m²，port の寸法と位置，座標（L7） | 一致 | `config/constants.m:16-24,43-47`，`AGENTS.md:98-109` | そのまま使える（port が中央にあることは unverified） |
| 12 | h = a の交絡（L15） | 一致 | `paper/README.md:141-146`，`doc/settled_and_retracted.md:24` | そのまま使える |
| 13 | 実機の上池を参考に条件を整理した（L105），Froude 数を参照しながら流量条件を設定した（L107-117） | 参照した実機の名前も数値も無い．Froude 数から水準を決めた記録も無い | 12 節 | 実機の値は `\PH{…}`．Froude 数で設定したとは書かない |
| 14 | 水深帯 B2 を独立の帯として扱った（L17） | 帯の境界は `depth_bands.csv` と一致．ただし深さの軸は時間比例に替えると決裁済みで，帯への割り当てが変わる | `metadata/depth_bands.csv:2-5`，`doc/settled_and_retracted.md:20` | 帯の定義は別の控えで扱う |

旧原稿のほかにも，同じ古い記述が残っている所がある（引かない）．

| 場所 | 古い記述 | 今の立場 |
|---|---|---|
| `doc/notes_2d3d_collaboration.md:91-93`，`cfd/campaign_log.md:598-600`，`cfd/template/CLAUDE.md:20` | 「実験は現在も 20 mm の静水から注水を開始し」「実験も 20 mm 静水から開始 (確認済み)」 | 撤回済み（`doc/settled_and_retracted.md:48`） |
| `README.md:38`，`metadata/README.md:76-77` | 実流量は水深と潜没の程度で名目からずれるので，必要なら代表水深帯ごとに評価する | 流量は各 run で一定．帯ごとの流量は使わない（`doc/settled_and_retracted.md:16-17`） |
| `paper/2026_journal_Shonai/slides/build_deck.py:68,91,232` | 「valve-set」など，バルブで流量を設定したという表現 | ポンプの周波数（`doc/settled_and_retracted.md:30`） |
| `doc/settled_and_retracted.md:16`，`doc/metrics_primer.md:28`，`doc/notes_2d3d_collaboration.md:88` | 「ラン平均 … low 0.219 / medium 0.392 / high 0.623 L/s」 | 値は 4 run の中央値．算術平均は 0.217 / 0.390 / 0.619（9 節） |
| `doc/settled_and_retracted.md:19` | 水位計は「ポート対面の中心線上」 | 正本（`doc/qdip_jet_check.md:20`）は「inlet 対面の壁際」だけ |

## Gaps

原稿では `\PH{…}` にする．探して埋めない．

1. **開始の手順（inflow）**：注水を始めたときの水槽の状態と水位，撮影を始めた水位（20 mm か 30 mm か），20–30 mm の区間を切り落としたか，ポンプの周波数を撮影の前に固定したか（8 節の問い 1–4）．
2. **開始の手順（outflow）**：始めたとき静水だったか，排水を始めた水位，その前の水の張り方と待ち時間（8 節の問い 5–6）．
3. **outflow の駆動と流量**：駆動の方式（ポンプか自然流下か），流量の設定方法，run の中で流量が一定か（`doc/qdip_jet_check.md:110-111`）．
4. **run の間の処置**：待ち時間，水位の戻し方，残留流の確認を実際に行ったか（8 節の問い 8）．
5. **1 日の中の実際の順番**（inflow の 4 日）と無作為化の方法．outflow の順を無作為に決めたか．run の記録（`runs.csv` が挙げる runlog.md）がほかの PC にあるかは確かめていない．
6. **ポンプ**：機種，各水準の周波数の値，日ごとに合わせ直したか．設定の目標は水位変化率か名目流量か（両者は実測の平面積で 3.6% 食い違う）．流量計の有無．
7. **水の回路**：下池，配管とホース，給水路への入れ方，整流の具体（「整流はあるが粗い」まで）．
8. **給水路の幅，長さ，材質**（確認されているのは，開水路であること，高さ 55 mm，上流がまっすぐなことだけ）．
9. **port の細部**：仕切り板の有無（「ポート内 3 枚の仕切り板」は確認項目として `cfd/campaign_log.md:563` に出るほか，同 `:460` に「加工精度・仕切り板」とあるだけで，実物を確認した記録は無い），縁の形，壁の厚さ，短辺の中央からのずれ．
10. **水槽**：材質，底と壁の仕上げ，水平の精度．深さ 0.33 m を測った記録と，それが壁の高さを指すかどうか．
11. **水位計**：壁からの距離，中心線の上かどうか，ロガーとアンプの機種と設定，零点の合わせ方．
12. **水位と流量の絶対値**：水位計の span（30 mm と 100 mm の読み）が未検証．下池の計測の詳細も未記録（`doc/qdip_jet_check.md:17-19`）．
13. **水温と動粘性係数**：記録が無い．ν = 1.0e-6 m² s⁻¹ は仮の値で，Reynolds 数は暫定．
14. **実機**：参照した上池の名前，寸法，流量，縮尺比．旧原稿は 1 つも挙げていない．
15. **座標の原点と y の向き**の正式な定義．
16. **実施者**（`runs.csv` の operator の列が空）．
17. **局所のメモの意味**：`local/raw/a.txt` の「短」「カット済み」「スタート未定→逆算」（R0008，R0010，R0015，R0022）．
18. **やり直した試行**：`runs.csv` に載らない試行の数，理由，採否の基準（`local/raw/Failure/` に 2026-06-18 の R0016 のログがあり，R0024 に「6/26にやり直す」のメモがある．7 節）．
19. **給水路の底の高さ**：交絡の記述（水位が a に達した瞬間に満管になる）は，給水路の底が水槽の底（z = 0）と同じ高さにあることを前提にしている．これを明記した資料は無い（`cfd/campaign_log.md:57-62` は「導水路高 = ポート高なので」とだけ書く）．

## Audit (second reader)

監査：2026-11-22．この控えが引いている資料を，引かれた行で開いて照合した．数値は，`local/derived/metrics/R00xx/frame_metrics.csv`，`local/derived/metrics/branch_stats.csv`，`local/raw/R00xx/waterlevel.csv`，`metadata/*.csv` から python3 で計算し直した．ほかのファイルは書き換えていない．

### 照合の範囲と結果

- 照合した記述は約 190 件である（各節の表の行，24 run の一覧，ブロックの表，outflow の表，水準ごとの表，無次元数の表，旧原稿との食い違い，古い記述の表）．
- 計算し直して一致したもの：24 run の T，Q，Q/Q_n，平均の水位変化率．水準ごとの最小，最大，平均，中央値，ばらつき．inflow 12 run と `branch_stats.csv` の Q_run_mean_Lps の一致（差の最大 5e-16 L/s）．収録時間の表．U_p，R，F の表（名目と run 平均の両方）．形の比，体積変化，3.6% の食い違い．水位計のログのヘッダー，日付，記録の間隔（0.310–0.312 s），ログと PIV の長さの差（R0006 6.30 s，R0022 1.46 s，R0010 1.29 s，ほかは 0.61 s 以下），R0005，R0009，R0011 の 29 mm．「0.219 / 0.392 / 0.623 L/s」が中央値であること．
- 行番号を開いて一致したもの：`config/constants.m`，`AGENTS.md`，`README.md`，`metadata/` の 4 ファイル，`doc/qdip_jet_check.md`，`doc/piv_conditions.md`，`doc/metrics_primer.md`，`doc/notes_2d3d_collaboration.md`，`doc/settled_and_retracted.md`，`paper/README.md`，`cfd/campaign.md`（226，242-243，274，307-313，407-409），`cfd/campaign_log.md`（41-65，563-564，597-600），旧原稿 `methods.tex`（7，9，11，13，15，17，19-21，23-32，36，46，51，74-78，103-119，126，223），`src/` と `scripts/` の引用行，`notation.tex`，`CONVENTIONS.md`，`local/raw/a.txt`，`local/raw/schedule.xlsx`．旧原稿からの引用文は原文と一致した．
- `doc/settled_and_retracted.md` §2 の撤回済みの記述を，有効なものとして載せている所は無い．数値計算の結果も載っていない．「静水から開始した」という記述も無い．

### 直した所

1. 7 節「run の状態」：「除外した run は無い」は言い過ぎであった．`runs.csv` の 24 行に除外が無いことしか言えない．`local/raw/Failure/R0016 waterlevel.csv`（2026-06-18）と R0024 の「6/26にやり直す」のメモがあるので，行を書き直し，「表に載らない試行（やり直し）」の行と Gaps の 18 を足した．「outflow の日程」の行にも，採用された 12 run についての記述であることを書き足した．
2. 7 節「各日の実際の順番」と 8 節「run の間の残留流の確認」：`runs.csv` が名前を挙げる runlog.md と動画は，この Mac の `local/raw/` に無い（24 フォルダとも waterlevel.csv だけ）ことを書き足した．「記録が無い」は，リポジトリとこの Mac の範囲のことである．Gaps の 5 にも書き足した．
3. 1 節「深さ」：「壁の高さ」という言い換えは，どの資料にも無い．資料の語（Basin depth，深さ）に戻し，Gaps の 10 に書き足した．
4. 9 節「実験者の予定表の流量」：「水位計から出した」の根拠が引かれていなかった．D 列の時間が水位計のログの余白の時間と 9 run で一致すること，流量の値が呼びの平面積 6.0 m² で 0.001 L/s 以内で再現できること（R0009 を除く）を書き足した．
5. 11 節「U_p の定義」：引かれた行は，I_circ と I_rot の a/U_p の正規化を含んでいなかった．`src/metrics/compute_frame_metrics_circ.m:4-5,61` などを足した．
6. Gaps の 9：「1 度出るだけ」を，出どころの行（`cfd/campaign_log.md:563` と `:460`）に書き直した．
7. Gaps の 19 を足した（給水路の底の高さは，交絡の記述の前提であるが，明記した資料が無い）．

### 監査で確かめられなかったもの（unverified by audit）

- 「記録が無い」とした GAP の行は，無いことを証明できない．`doc/`，`cfd/campaign.md`，`cfd/campaign_log.md`，`paper/README.md`，`README.md`，`metadata/` を語（仕切り，水温，材質，整流，ホース，周波数，流量計，実機，縮尺，乱塊，中心線，やり直 など）で検索した範囲では，控えと食い違う記述は見つからなかった．ほかの PC の `local/`，runlog.md，動画，実験の帳面は見ていない．
- 「乱塊法」は，資料の文言が「1 日の中の run の順番は乱塊法 (順番の交絡はない).」（`cfd/campaign.md:409`）だけである．日をブロックとし，日の中の順番を無作為に決めた，という読みは用語の意味からの解釈で，無作為化の方法と実際の順番を裏づける記録は無い．
- 水位計の取り付け位置（inlet に対面する壁の際），レンズの高さ，水面までの距離は，`doc/qdip_jet_check.md:20-21` の記述のとおりであることを確かめただけで，実物とは照合していない．
- `local/raw/Failure/R0016 waterlevel.csv` の先頭行の余白に「14:22.4」「2026/6/18 24:59.0 101」「2026/6/18 53:17.5 30」と書かれたセルがある．意味は確認していない．8 節の問い 3 と 9 に関わるので，実験者に聞くときに併せて確かめるのがよい．
- `cfd/campaign_log.md:601` に「(一時「実験は 0 mm から」と記録したが誤り. 撤回済み.)」とある．控えには載っていない．8 節の問い 1 に関わるが，撤回済みの記述なので使わない．
- `local/raw/schedule.xlsx` の R0009 の流量（0.821 L/s）は，D 列の時間（5min26s）から計算した値（0.828 L/s）と合わない．どちらも使わない量なので，原因は調べていない．

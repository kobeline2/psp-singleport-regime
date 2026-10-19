# CFD 引き継ぎ — shonai さんへ (2026-10)

小柴が 2026 年 7 月に回した CFD (OpenFOAM interFoam) のキャンペーンを引き継いで,
自分で条件を変えて回し, 動画で確かめるための入口. **最初に全部読む必要はない.
§1-§4 を読めば回し始められる.** 残りは必要になったときに引けばよい.

Claude Code を使う場合は, 起動時に `doc/fork_prompt_cfd_shonai.md` の枠内を貼ること.

---

## 1. 目標と現状

- **目標**: 実験で見えている「**偏向流**」— ジェットが片側の壁に付着し, 盆地全体を回る
  単一の大きな循環 — を CFD で出すこと.
- **現状**: 29 ケース, 約 160 時間回して **一度も出ていない**. CFD は毎回, 左右対称の
  二つの渦 (上半分と下半分に鏡像) に落ちる. 何を変えて何が起きたかは §8 と `campaign.md`.

## 2. 一番大事な注意 — 「一瞬偏る」は成功ではない

CFD の流れは, 動画で見ると**瞬間的には片側に大きく偏る**ことがある (偏り指数で ±0.27 まで.
実験のロック値 ±0.25 を超えることすらある). しかしすぐ反対側に振れて, 平均すると対称に戻る.

実験の偏向流は**数百秒間ずっと同じ側に張り付いて動かない** (偏り ±0.25 から ±0.007 しか
ずれない). だから見るべきは「**偏りが保持されるか**」.

`surface_movie.py` が作る動画の下段がこれを見るための時系列で, 青い太線 (60 秒の移動平均) が
橙の帯 (実験のロック値 ±0.25) に**張り付いたまま数百秒動かなければ**成功に近い.
最後に平均場の図 (`*_meanfield.png`) で, **一つの渦が盆地を満たしているか**を確かめる.

## 3. 場所

| もの | 場所 |
|---|---|
| 計算機 | koshiba-ws (10.244.3.122), アカウント `shonai`. 学外からは VPN |
| **参照ケース (読み取り専用)** | `~/OpenFOAM/yuna-v2412/run/psp_tests/` — 小柴の 29 ケース, 322 GB. **中身を変えない.** 使いたいファイルはコピーして使う (コピーも読み取り専用になるので `chmod -R u+w <コピー先>`) |
| 自分の作業場 | `~/OpenFOAM/yuna-v2412/run/psp_shonai/` (`new_case.sh` が自動で作る) |
| 以前のケース | 同じ `run/` の `Inflow`, `Inflow_260720`, `tank`, `tank1` (6-7 月. 台帳の X 系列). **`Inflow` は消さない**: 参照ケース A01-A10 がそのメッシュをリンクで使っている |
| repo | WS 上の `~/psp-singleport-regime` (ブランチ `shonai-cfd`) |
| 自分の記録 | repo の `cfd/shonai/cases.csv` (台帳) と `cfd/shonai/notes.md` (メモ) |

参照ケースが読み取り専用なのは, テンプレートの `Allrun` のような実行スクリプトを
その中でうっかり叩くと, 冒頭の `rm -rf processor* postProcessing` で 17 GB の結果が消えるため.

このアカウントには小柴の Mac の ssh 鍵が登録されていて, 小柴 (と小柴の Claude) が
レビューのために中を見ることがある. §5 で作る GitHub 用の ssh 鍵もこのアカウントの中に置かれる.

## 4. Git — Claude Code に任せてよい

- 作業を始めるとき: Claude に「**pull して**」
- 区切りがついたら: 「**push して**」(作業中のファイルも含めて commit して push する)
- 作業するブランチは **`shonai-cfd` だけ**. `main` と `cfd-campaign` には commit しない
- 小柴が道具やテンプレートを直したら「**cfd-campaign の更新を取り込んで**」
  (`git fetch` → `git merge origin/cfd-campaign`. 自分の記録 `cfd/shonai/` とはぶつからない)
- 計算結果 (メッシュ, processor*, 時刻ディレクトリ, 動画) は git に入れない.
  repo に入れるのは台帳・メモ・設定ファイルの変更だけ
- 小柴のファイル (`cfd/cases.csv`, `cfd/campaign*.md`, `cfd/methods_audit.md`) は参照用. 編集しない

## 5. 最初の 1 時間 — 道具が自分の手で動くか確かめる

**初回だけの準備** (Claude Code に頼めばやってくれる):

```sh
# 1. repo を持ってくる (公開 repo なので clone に認証は要らない)
git clone https://github.com/kobeline2/psp-singleport-regime.git ~/psp-singleport-regime
cd ~/psp-singleport-regime && git checkout shonai-cfd
git config user.name "<自分の名前>" && git config user.email "<GitHub のメール>"

# 2. push できるようにする. WS に gh は無いので ssh 鍵を使う
ssh-keygen -t ed25519 -C "shonai@koshiba-ws"   # 質問は Enter でよい
cat ~/.ssh/id_ed25519.pub                     # 表示された 1 行を, 自分の GitHub の
#                                               Settings → SSH and GPG keys → New SSH key に貼る (自分でやる)
ssh -T git@github.com                         # "Hi <自分の GitHub 名>!" と出れば OK
git remote set-url origin git@github.com:kobeline2/psp-singleport-regime.git

# 3. 動画ツールの部品
python3 -c "import numpy, scipy, matplotlib"   # WS には入っている
ffmpeg -version | head -1                     # 無いと動画は mp4 でなく GIF になる (小柴に入れてもらう)
```

WS には pip も sudo 権限も無い (Ubuntu 24.04) ので, 足りない部品は自分では入れられない. 小柴に頼む.

参照用の動画と平均場の図 (実験 R0006・R0008, CFD B03・P02) は
`~/OpenFOAM/yuna-v2412/run/psp_tests/_reference/` に置いてある. **まず実験の 2 本を見て,
目標の姿を目に焼き付けてから**, B03 (典型的な失敗) と比べるとよい.

**(a) 動画ツール**: 参照ケース B03 (基準) と P02 (唯一単一渦になったケース) の動画を作る.

```sh
cd ~/psp-singleport-regime
python3 cfd/tools/surface_movie.py ~/OpenFOAM/yuna-v2412/run/psp_tests/B03_fullfill --label B03
python3 cfd/tools/surface_movie.py ~/OpenFOAM/yuna-v2412/run/psp_tests/P02_perturb_geom --label P02
```

出力は `~/surface_movies/B03_surface/` (動画 `B03_surface.mp4`, 平均場の図, 指標) に入る.
`B03_metrics.txt` が次の値になれば, 判定指標も小柴の表 (`campaign.md` §2) と同じ物差しで出ている:
`E_inst 0.000864, mean-flow 0.000449, fluct 48.0 %, bias +0.076, dominant 50.3 %, largest 35.7 %, lock 0.67`

**(b) 計算の手順**: 30 秒だけ回して, B03 の最初の 30 秒と比べる.

```sh
bash cfd/tools/new_case.sh S00_check
# S00_check/system/controlDict の endTime を 30 に変える
bash cfd/tools/run_case.sh ~/OpenFOAM/yuna-v2412/run/psp_shonai/S00_check
bash cfd/tools/case_status.sh ~/OpenFOAM/yuna-v2412/run/psp_shonai/S00_check
```

10 分ほどで終わる. B03 は t = 30 s までに 1662 ステップ (`log.interFoam` の `Time = ` の行数).
ぴったりは一致しない: B03 のメッシュは座標を丸めた ascii 形式, 新しいケースは binary 形式で書かれるので,
軌道がわずかにずれる (2026-10 の確認では t = 10 s までが 647 対 646 ステップ). ステップ数の差が 1-2 % 以内で,
`case_status.sh` の質量保存が 99.9 % 以上なら環境は正しい. 確認したら `S00_check` は消してよい (台帳には残す).

## 6. 1 本回す手順

```sh
bash cfd/tools/new_case.sh S01_sigma0             # 1. ケースを作る (基準ケース B03 と同一設定)
#                                                    2. 設定を 1 箇所だけ変える (§7 の早見表)
#                                                    3. cfd/shonai/cases.csv に行を足す
bash cfd/tools/run_case.sh <ケース>               # 4. 切り離して実行 (VPN が切れても止まらない)
bash cfd/tools/case_status.sh <ケース>            # 5. 1-2 分後に一度見て, モデル選択と質量を確認
python3 cfd/tools/surface_movie.py <ケース>       # 6. 終わったら動画と判定指標 (~/surface_movies/ に出る)
```

時間の目安 (16 ランク, 1000 秒): 基準メッシュ 5-6 h / RANS 6.6 h / 鉛直細分 14 h / 水平細分 41 h.
**同時に 2 本回すと両方遅くなる**ので, 1 本ずつ. `run_case.sh` は走っている計算があると止まる.

`surface_movie.py` の主なオプション: `--no-movie` (指標と平均場の図だけ, 1-2 分),
`--window T0 T1` (判定窓を指定), `--tmin/--tmax` (動画の時間範囲), `--every 2` (間引き).
判定窓は流量に合わせて自動で決まる (0.5 L/s なら 485-950 s = 深水帯).

## 7. どこを変えると何が変わるか (これまでの軸の早見表)

| 変えたいもの | ファイル | 過去の例 |
|---|---|---|
| 表面張力 | `constant/transportProperties` の `sigma` | (未実施. 0 にする案 = N2) |
| 運動量の移流スキーム | `system/fvSchemes` の `div(rhoPhi,U)` | P07 `Gauss upwind`, P08 `Gauss linear` |
| 時間スキーム | `system/fvSchemes` の `ddtSchemes` | (未実施. `Euler` → `CrankNicolson 0.9` 等 = N3) |
| 乱流モデル | `constant/turbulenceProperties` + `0.orig/` に場を追加 | P06 RANS, B06 WALE → `cfd/recipes/P06_rans` |
| 流量 | `0.orig/U` の `flowRate` | D02 `0.00075` (+ `endTime` を 700 に) |
| メッシュ | `new_case.sh --mesh base / fine / zfine` | P09 水平 2 倍, P10 鉛直 2 倍 |
| 流入面の形 (非対称注入) | `system/pre_run.sh` + 手術用 dict | P02, P05 → `cfd/recipes/` |
| ポート開口の形 | `system/pre_run.sh` + `createBafflesDict` | P04 → `cfd/recipes/` |
| 計算時間・出力間隔 | `system/controlDict` の `endTime`, `writeInterval` | |

`cfd/recipes/<名前>/` のファイルはケースに上書きコピーして使う. 手順は `cfd/recipes/README.md`,
各レシピの中身と結果は中の `RECIPE_<名前>.md`.

## 8. もう試したこと / まだ試していないこと

**試して偏向流が出なかったもの** (詳細は `campaign.md` §2. 同じものを回すなら理由を書く):

| 軸 | 試したこと | 結果 |
|---|---|---|
| 種 (非対称のきっかけ) | P01 流入速度に 5% の横成分 / P04 ポートの 1/11 を壁に | 何も起きない |
| | **P02 流入面の上半分だけから注水** | **唯一, 単一渦になった**. ただし渦が小さく壁に付着しない |
| | P05 対称のまま流入速度 2 倍 (P02 の対照) | 脈動が悪化 → P02 の効果は非対称そのもの |
| 拡散 | P08 中心差分 / P06 RANS / P07 upwind | 変動は減るが対称のまま. 拡散を足すと対称がむしろ安定化 |
| メッシュ | P09 水平 2 倍 / P10 鉛直 2 倍 / B05 三角柱 | 変わらない |
| 流量 | D02 high (実験が 4 本中 4 本ロックする条件) | 変わらない |
| 乱流モデル | B06 / P03 WALE | 効果が測れないほど小さい |

**まだ試していないもの** (アイデアの例. 何を回すかは自分で決めてよい):

- **σ = 0** (表面張力を切る). 物理的には無視できる大きさで, 今の設定は表面張力由来の
  時間刻み制約を破っている (`methods_audit.md` §1). 1 行の変更で, 最初の 1 本に向いている
- **時間スキーム**を 2 次に (`CrankNicolson 0.9` / `backward`)
- **作ってから外す**: P02 型の非対称注入で単一渦を作り, 途中から対称注入に戻して
  渦が保持されるかを見る. 「CFD は偏向を保持できるか」への最も直接的な答えになる
  (場の受け渡しが要るので Claude と相談しながら)
- **非対称注入 × 高流量** (P02 × D02)
- 移流スキーム `LUST`, 乱流モデル `Smagorinsky` (WALE と違い平均剪断で効く)
- 底面の壁の扱い (浅い流れでは底面摩擦が効く)

## 9. 守ってほしいこと

1. **1 ケース 1 変更**. 何から変えたか (親ケース) を台帳に書く
2. **回す前に台帳に行を足す**. purpose 列に「何が起きたら成功か」を先に書く
3. 判定の前に**平均場の渦度の図を必ず見る** (数字だけで判断すると読み違える)
4. **脈動している解は 1 本で結論しない** (同じ設定でも数値が ±5 割ばらつく)
5. 試したことのある軸 (§8) を回すときは理由を書く
6. **参照ケース (`psp_tests`) には触らない**. 実行は自分の作業場でだけ

## 10. ハマりどころ (小柴が実際に踏んだもの)

- **綴りを間違えた設定は黙って無視される**. `case_status.sh` の「選択されたモデル」で確認
- RAS / LES で k や ε を足したら, `fvSolution` の正規表現は `"(k|epsilon).*"`.
  `.*` が無いと最終補正の `kFinal` が見つからず, 初回ステップで落ちる
- 流入の alpha は `fixedValue 1` のまま. 全断面インレット + `variableHeightFlowRate` に戻すと
  水の流束が Q より小さくなり, 質量が 7% 抜ける
- **流量を変えたら終了時刻も変える**: 満水 (102 mm) まで `1000 × 0.5 / Q[L/s]` 秒.
  判定窓は `surface_movie.py` が自動で合わせる
- メッシュは `blockMeshDict` から作る. `template/mesh/tank.geo` (gmsh, 三角柱) は古い手順で,
  使うと全断面インレットに戻り, 流入が滝のように落ちて時間刻みが潰れる
- リスタートは `startFrom latestTime` に変え, `endTime` も更新する
- ディスク: 基準メッシュで 1 本 17 GB, 細分は 30-63 GB. `df -h ~` で残りを見る
- VPN が切れても計算は止まらない. 状況確認は再接続してから

## 11. 参照資料

| ファイル | 中身 |
|---|---|
| `cfd/campaign.md` | 小柴のキャンペーンの総括. §0 (結論), §2 (全ケースの表), §3 (指標の読み方) |
| `cfd/cases.csv` | 全ケースの台帳 (小柴分). verdict 列に各ケースの詳しい結果 |
| `cfd/campaign_log.md` | 時系列の生記録. 撤回された判断も含む |
| `cfd/methods_audit.md` | 文献 (数値散逸, 時間刻み) に照らした設定の監査 |
| `cfd/template/` | 基準ケース B03 と同一の設定 (メッシュ定義は `template/mesh/`) |
| `cfd/recipes/` | 摂動・RANS ケースの組み方 |
| `cfd/tools/` | `new_case.sh` / `run_case.sh` / `case_status.sh` / `surface_movie.py` |

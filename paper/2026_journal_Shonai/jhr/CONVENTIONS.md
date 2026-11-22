# JHR 原稿の書式の細目

`paper/README.md` の「1 本目 — 書き方の取り決め」の細目である．原稿に触る前に，その節と
`doc/settled_and_retracted.md` を読み，それからここを読む．食い違ったら `paper/README.md` が正しい．

## 1. ファイルと二つのビルド

| ファイル | 役割 |
|---|---|
| `sections/*.tex` | 本文．英語と日本語の直訳を段落ごとに対にして持つ．二つのビルドで共有する |
| `tables/*.tex` | 表（英語のみ）．`tables/all.tex` が初出の順に読み込む |
| `figures/all.tex` | 図．まだ無い図は `\figplaceholder{…}` で場所だけ取る |
| `notation.tex` | 記号のマクロ．**名前のある量は手で書かず，必ずこのマクロを使う**（座標 $x, y, z$，時刻 $t$，添字 $i, j, k$ は直接書いてよい）．要る記号が無いときは，自分の節のファイルの先頭に `\providecommand` で仮に定義し，その旨を報告する（`notation.tex` は共有なので直接は足さない） |
| `bilingual.sty` | 対の段落，空欄，出典の仕組み |
| `main.tex` | 投稿用（英語のみ）．pdflatex，`tJHR2e.cls` |
| `review.tex` | 精査用（日本語が主，英語は小さい字，出典つき）．lualatex，ltjsarticle |
| `make_bib.py` | Zotero の export から `refs.bib` を作る（月などの欄を落とす）．書誌の正本は Zotero |
| `evidence/*.md` | 各段落の根拠の控え（引用元のメモの場所，数値の出どころ） |
| `build.sh` | 両方を組む．`./build.sh review` で精査用だけ |
| `lint.py` | 対の構造，段落の番号，引用キー，空欄の数，表記の決まりを機械的に検査する．**書いたら必ず通す**（`python3 lint.py`．ERROR は 0 にする．WARN は一つずつ確かめる） |

`tJHR2e.cls` と `template/` は出版社の配布物なので，公開リポジトリには入れていない
（`.gitignore`）．投稿用を組む PC では，JHR の Instructions for authors の「Latex template」
から取って `main.tex` の隣に置く．精査用は無くても組める．

## 2. 段落の書き方

```latex
\begin{en}[I-3]
English paragraph \citep{dufresneClassificationFlowPatterns2010}.
\end{en}
\begin{ja}
日本語の直訳 \citep{dufresneClassificationFlowPatterns2010}．
\src{Dufresne 2010: review\_master.tex L395--410，確認 p.3--5}
\end{ja}
```

- 段落の番号は，序論が `I-1, I-2, …`，方法が小節ごとに `M1-1, M1-2, …, M2-1, …`（小節 2.1 の 1 段落目が `M1-1`），結果 `R1-1`，考察 `D1-1`，結論 `C-1`，後付け（謝辞，資金など）`B-1`．
  **一度振った番号は変えない．** 段落を足すときは `I-3a` のように枝番を使う（指摘が番号で来るため）．
- `\begin{en}` `\end{en}` `\begin{ja}` `\end{ja}` は，それぞれ単独の行に書く．
- **段落と段落の間は空行 1 つ．対の中（en と ja の間）には空行を入れない．**
- 数式（equation 環境）は en と ja の外に置く．文の途中に数式が入る段落は，
  「対 → 数式 → 対」の順に，**空行を入れずに**続ける．数式の後ろの対には番号を付けない．
- en と ja の中に verbatim は書けない．`#` も書かない．
- 節は `\bisection{English}{日本語}`，小節は `\bisubsection{English}{日本語}`．**節の番号は 2 段まで**（JHR）．
- 原稿の一部ではない精査者への注は `\jnote{…}`（精査用にだけ出る）．

## 3. 直訳の決まり

日本語は内容の精査のためのもので，文章の美しさは問わない．

- **英語の一文を日本語の一文にする．** 文の数と順序を変えない．
- 意訳しない．英語に無い補足を足さない．英語にある限定を落とさない．
- **主張の強さを保つ．** suggests は「示唆する」，indicates は「示す」，demonstrates は「実証する」，
  may は「〜しうる」，is likely は「〜の可能性が高い」，to our knowledge は「著者らの知る限り」．
- 記号，数値，単位，引用，式の番号，図表の番号は英語と同じものを同じ位置に書く．
- 専門用語は 7. の訳語の表に従う．inflow，outflow，port，basin，run は訳さずそのまま書く
  （旧和文原稿と同じ）．
- 句読点は「，．」．英語の `;` と `:` は，文を分けずに「；」「：」で写してよい（文の数を英語と合わせるため）．
- 英語の shows / reported / describes は，「示す」「報告した」「述べている」と，動詞の強さをそのまま写す．

## 4. 空欄と印

| マクロ | 意味 | 使い方 |
|---|---|---|
| `\PH{…}` | **分からない数値・事実**．無理に探さず，推測で埋めない | en と ja の同じ位置に置く．中身は en では英語，ja では日本語 |
| `\PHref{…}` | **後で足す文献**（揚水発電の重要性などの周辺文献）．literature チャットが把握している | 同上．勝手に文献を探して埋めない |
| `\unverified` | 人が原典と照合していない文献（AI-DRAFT に基づく記述）の印 | `\citep{…}\unverified` のように引用の直後に付ける |
| `\src{…}` | 引用元のメモの場所と確認ページ，数値の出どころ | **ja の末尾**に置く（精査用にだけ出る）．`_` は `\_` と書く |

空欄の中身は短い見出しにし，内訳（何を確かめれば埋まるか）は直後の `\jnote` に書く．空欄の中の語は
分量に数えない（`lint.py` が両方の語数を出す）．

現時点で空欄と決まっているもの：実験の開始手順（inflow の注水を始めた水位，撮影開始の水位，
outflow を静水から始めたか），トレーサ粒子の種類と粒径，水温と動粘性係数，下池の計測の詳細，
流量と水位の絶対値の検証，著者の所属，謝辞，資金．

## 5. 文献

- 引用できるのは `literature/review_master.tex` の**確認済みの本文**だけ．`% ==== AI-DRAFT` の
  ブロック（行頭が `%`）は引用できない．
- 例外：`cherdronAsymmetricFlowsInstabilities1978` と `fearnNonlinearFlowPhenomena1990` は，
  AI-DRAFT のまま `\unverified` を付けて使ってよい（2026-11-22 ユーザー指示）．
- **メモに書いてあることだけを書く．** メモの「限界・適用範囲」に「〜は本論文に無い」とあれば，それを引かない．
- 引用キーは `literature/refs/zotero_export.bib` のもの．`\citep{…}`（括弧つき）と `\citet{…}`（文中）を使う．
- 引用する文ごとに，`\src{著者 年: review\_master.tex L行--行，確認 p.頁}` を付ける．
- `literature/review_master.tex` と `literature/refs/` は literature チャットの持ち物である．**書き換えない．**

## 6. JHR の表記

- 英綴りはイギリス式の -ize（characterize，analyse，behaviour，centre，colour，modelled）．
- 引用符は一重（‘ ’）．TeX では `` `…' ``．
- 略語は初出で綴りを書き，括弧で略語を示す：pumped-storage hydropower (PSH)，particle image velocimetry (PIV)．
- 単位は SI，立体，`m s^{-1}` の形．**`m/s` と書かない．** 数値と単位の間は `~`．
  `notation.tex` の単位のマクロ（`\Lps`，`\mps` など）を使う．
- 文中の式は `=` の前後を空ける：`$\aport = 0.055$~m`．
- 記号は初出の文で定義する（単位は本文に書かず Notation に書く）．
- 変数を 2 文字にしない．数字と括弧を斜体にしない．添字は変数と同じ書体（`\sub{…}`），数字の添字は立体．
- 無次元数は立体のサンセリフ：`\Rey`，`\Fro`．
- 参照は，文頭で `Figure~\ref{…}`，文中で `Fig.~\ref{…}`，小図は `Fig.~1a`．
  式は `Equation~(\ref{…})`，表は `Table~\ref{…}`．
- 図と表は文献の後ろに置く．本文には参照だけを書く．表題は表の上，注は表の下．
- 非差別的な言葉づかい．一人称は we を使ってよい．

## 7. 訳語の表

| 英語 | 日本語 |
|---|---|
| pumped-storage hydropower (PSH) | 揚水発電 |
| upper reservoir / lower reservoir | 上池 / 下池 |
| intake/outlet structure | 取放水口 |
| basin（模型）/ reservoir（実機） | basin / 貯水池 |
| port | port |
| feed channel | 給水路 |
| inflow (pumping mode) / outflow (generating mode) | inflow（揚水運転）/ outflow（発電運転） |
| mode（inflow と outflow の別） | 運転 |
| discharging into / withdrawal, withdrawing from | 吐出 / 吸込 |
| free surface | 自由表面 |
| port velocity scale | port の流速尺度 |
| gauge reading / gauge-derived discharge | 水位計の読み / 水位計由来の流量 |
| jet test（流量一定の確認） | 噴流の試験（「検定」は統計的検定に取っておく） |
| flowmeter | 流量計 |
| analysed record | 解析した記録 |
| frame（指標の文脈） | フレーム（流速場の一つ一つ．2.4 節の動画のフレームと区別する） |
| run | run |
| discharge / nominal discharge / run-average discharge | 流量 / 名目流量 / run 平均流量 |
| water depth / relative submergence $h/a$ | 水深 / 相対水深 $h/a$ |
| submerged, submergence | 潜没 |
| full-pipe transition | 満管遷移 |
| confound, confounded | 交絡 |
| depth band | 水深帯 |
| time-proportional depth / gauge depth | 時間比例の水深 / 水位計の水深 |
| water-level gauge | 水位計 |
| surface particle image velocimetry (PIV) | 表面 PIV |
| interrogation window | 検査窓 |
| image-pair interval | 画像対間隔 |
| noise floor | ノイズ床 |
| jet deflection / deflected jet | 噴流の偏向 / 偏向した噴流 |
| wall attachment / attached jet | 壁面付着 / 付着した噴流 |
| recirculation / reattachment | 再循環 / 再付着 |
| symmetry breaking | 対称性の破れ |
| bifurcation / pitchfork bifurcation / imperfect bifurcation | 分岐 / ピッチフォーク分岐 / 不完全分岐 |
| branch / branch selection | 分枝 / 分枝の選択 |
| bistability, bistable | 双安定性，双安定 |
| imperfection, bias | 欠陥，偏り |
| net circulation | 正味循環 |
| lock strength | ロック強度 |
| sign persistence | 符号保持率 |
| jet lateral offset | 噴流の横ずれ |
| area-mean squared surface speed | 面平均の表面流速の二乗 |
| low-velocity area fraction | 低流速域面積率 |
| asymmetry index | 左右非対称指標 |
| rotation activity index | 回転活動度 |
| unsteadiness index | 非定常指標 |
| randomized complete block design | 乱塊法 |
| replicate | 反復 |
| exact permutation test | 正確な順列検定 |
| prototype-informed laboratory experiment | 実機を参照した室内実験 |
| scale effects | 縮尺効果 |
| sedimentation | 堆砂 |

## 8. 事実の正本

| 事柄 | 正本 |
|---|---|
| 決着した事実，撤回した記述 | `doc/settled_and_retracted.md` |
| 装置の寸法 | `config/constants.m`，`AGENTS.md` |
| run の条件，日付，水準 | `metadata/runs.csv`，`metadata/flow_levels.csv`，`metadata/depth_bands.csv` |
| 流量の検証，水位計，深さの軸 | `doc/qdip_jet_check.md` §0 |
| PIV の解析条件 | `doc/piv_conditions.md` |
| 指標の定義 | `src/metrics/*.m`（実装），`config/metrics_defaults.m`，`doc/metrics_primer.md`（解説） |
| 分枝の集計 | `src/metrics/compute_branch_statistics.m`，`scripts/checks/branch_sign_tests.py` |
| 噴流の横ずれ | `scripts/checks/jet_offset_by_band.py` |
| 実験の手順（ユーザー確認分） | `cfd/campaign.md` §9.2 |
| 旧和文原稿（素材．凍結） | `../sections/*.tex` |

**書かないこと**（`doc/settled_and_retracted.md` §2）：帯ごとの水位由来の流量，遷移時間法，
流量が水深で変わるという記述，超音波式の水位計，「静水開始」，バルブ開度による流量の設定，
CFD の図と数値．

## 9. 分量の目安

JHR は刷り上がり 15 頁（図表を含めて約 15,000 語相当）まで．序論は 900--1100 語，
方法は 2200--2600 語と表 2--3 枚を目安にする．初稿（2026-11-22）は空欄の中身を除いて序論 1100 語，
方法 2441 語で，どちらも上限に近い．**足すときは同じ節で同じだけ削る．**

## 10. 未決の表記

- ロック強度 `\Rlock`（$R_{lock}$）が Reynolds 数 `\Rey`（サンセリフの R）と紛らわしい．
  `notation.tex` の 1 行で変えられる．Page の統計量 `\Lpage`（$L_P$）と basin の長さ `\Lx`（$L$）も近い．
- フレームにわたる平均と標準偏差を $\mu_k(\cdot)$，$\sigma_k(\cdot)$，$\Band{3}$ と $\Band{4}$ をまとめた集合を添字 $d$ で
  書いている（`\tmean`，`\tsd`，`\deep`）．Notation の一覧では演算子として載せている．
- $\EL$，$\ER$ の L，R が実際のどちらの側壁かは，符号の向き（M5-3 の空欄）が決まるまで書けない．
- 無次元数は，Instructions for authors（2026-11-16）では F と R，テンプレートの手引き（2025-09）では
  Fr と Re．前者に従っている．`notation.tex` の 2 行で変えられる．

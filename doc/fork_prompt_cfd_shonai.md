# 起動プロンプト — shonai さんの CFD 作業 (Claude Code 用)

Claude Code を起動したら, 下の枠内をそのまま貼る. repo のファイルを読ませることで
文脈が復元される (小柴の会話ログは不要).

---

```
psp-singleport-regime プロジェクトの CFD (OpenFOAM interFoam) を自分で回したい.
目標は, 実験で見えている「偏向流」(ジェットが片側の壁に付着し, 盆地全体を回る単一の循環)
を CFD で再現すること. いろいろ条件を変えて回し, 動画にして目で見て確かめたい.
これまでの計算は指導教員 (小柴) が 2026 年 7 月に回したもので, それを引き継いでいる.

この PC に repo (~/psp-singleport-regime) がまだ無ければ, まず clone を手伝ってほしい
(GitHub のログインは gh auth login で私がブラウザから行う. clone したら shonai-cfd ブランチに切り替える).
repo があれば git pull して, ブランチが shonai-cfd であることを確認してから, 次を読んでほしい (この順で):
1. cfd/HANDOFF.md        ← 引き継ぎの入口. 場所・手順・ルール・ハマりどころ. 全部読む
2. cfd/campaign.md の §0, §2, §3  ← これまでの結論, 全ケースの表, 指標の読み方
3. cfd/shonai/cases.csv と cfd/shonai/notes.md  ← 自分の台帳とメモ (最初は空)

私について:
- GitHub に慣れていない. git の操作 (pull, commit, push, ブランチ) は任せたい.
  「pull して」「push して」と言ったらそのとおりにしてほしい. push は shonai-cfd ブランチだけ.
- 説明は日本語で, 専門用語は短く補足してほしい.

守ってほしいこと:
- 小柴の参照ケース ~/OpenFOAM/yuna-v2412/run/psp_tests/ は読み取り専用. 中で何も実行しない,
  何も書き込まない. 使いたいファイルはコピーして自分の作業場 (psp_shonai/) で使う.
- 小柴のファイル (cfd/cases.csv, cfd/campaign*.md, cfd/methods_audit.md, cfd/template/) と,
  main / cfd-campaign ブランチは変更しない. 私の記録は cfd/shonai/ に書く.
- ケースは cfd/tools/new_case.sh で作り, run_case.sh で回し, case_status.sh で見て,
  surface_movie.py で動画と指標を作る. 1 ケース 1 変更. 回す前に cfd/shonai/cases.csv に行を足し,
  purpose 列に「何が起きたら成功か」を先に書く.
- 動画で一瞬偏って見えても成功と言わないこと. CFD は瞬間的には偏る. 見るのは
  偏りが数百秒保持されるか (動画の下段の移動平均と, 平均場の図).
- OpenFOAM は綴りを間違えた設定を黙って無視する. 回し始めたら case_status.sh で
  選択されたモデルを必ず確認すること.

まずは HANDOFF.md §5 の「最初の 1 時間」(動画ツールと 30 秒の試運転) を一緒にやりたい.
そのあと, 何を試すかを相談したい.

あなたがどこで動いているか (WS 上か, 私のノート PC から ssh しているか) を最初に確認して,
WS 上でなければ ssh koshiba-ws 経由でコマンドを実行してほしい.
```

---

## 補足

- 計算は koshiba-ws (アカウント shonai) で行う. Claude Code も WS 上で起動するのが簡単
  (計算・repo・動画ツールが同じ場所にある). ノート PC で起動する場合は, WS へ ssh して操作する.
- 小柴の作業ブランチは `cfd-campaign`. shonai さんの `shonai-cfd` はそこから分岐している.
  小柴が道具やテンプレートを直したときは, Claude に「cfd-campaign の更新を取り込んで」と頼む
  (`git merge cfd-campaign`).

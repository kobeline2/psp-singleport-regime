# Fearn, Mullin & Cliffe (1990) -- check of the AI-DRAFT note against the PDF

- Checked 2026-11-22 by a subagent. Evidence only; no manuscript text was written.
- PDF: `/Users/takahiro/Zotero/storage/SDBRDQJP/Fearn et al. - 1990 - Nonlinear flow phenomena in a symmetric sudden expansion.pdf`, 14 pages, all read. PDF page 1 = journal p. 595, PDF page 14 = journal p. 608. **Every page number below is a journal page.**
- Note checked: `literature/review_master.tex` L1184--1196, the block `% ==== AI-DRAFT: fearnNonlinearFlowPhenomena1990 ====`. The block is still commented out (AI-DRAFT, not promoted).
- This check was made by an AI, not by the user. The `\unverified` mark stays on every citation of this paper until the user has compared the original (`paper/README.md` L76--78 and L171).
- Words that occur nowhere in the paper (text search over the 14 pages): pitchfork, imperfect bifurcation, slow / slowly, transient, free surface, shallow, jet, basin, reservoir. The word hysteresis occurs only on p. 596 (about the numerical results of Sobey & Drazin) and on p. 608 (title of Fuchs 1988), never about the authors' own results.
- Overall: all four numbers asked about are printed as the note gives them (critical Reynolds number 40.45, stability limit of the disconnected branch 47.3, imposed offset 0.05 mm, shift of the limit point over 13%). No bullet is wrong. Three bullets add a word or an inference that the paper does not contain (pitchfork, hysteresis, and the transfer to free-surface flow), and one sentence of the last bullet is the note-writer's own reasoning with no counterpart in the paper.

## 1. Verdict per bullet of the AI-DRAFT

Line numbers are those of `literature/review_master.tex`.

| bullet (short) | verdict (supported / partly / wrong / not found) | journal page | what the paper actually says |
|---|---|---|---|
| L1185 問い: 3:1 の対称な平面急拡の定常非対称流を分岐理論で説明できるか，実験と数値は一致するか | supported | 595 (abstract), 596, 607 | The aim is the origin of steady asymmetric flows, studied by experiment and numerics; the asymmetry is shown to arise at a symmetry-breaking bifurcation with good agreement between the two (abstract, p. 595). A single channel of expansion ratio 3:1 was used (p. 596). The conclusions repeat this (p. 607). |
| L1186 手法: 水・グリセリン水，拡大比 3，下流アスペクト比 8，放物分布，Re を約 1% で制御，LDV と可視化，有限要素の 2D 定常 NS 分岐解析，Re = dU/nu | supported | 596--599 | Water--glycerol mixtures of about 7 cSt for Re up to 60, distilled water up to Re = 380; flow controlled to about 1% in Re (p. 598). Expansion ratio 3:1 and downstream aspect ratio 8:1, aspect ratio defined as width over height (p. 596); the expanded section is 80 step-heights long (p. 597). An entry section 60 channel-heights long develops the parabolic profile (p. 597); inlet profiles measured 15 mm upstream at Re 30--280 agree with parabolas (p. 599; Fig. 2 on p. 598). LDV and flow visualization (pp. 596, 598--599). Numerical bifurcation techniques applied to a finite-element discretization of the two-dimensional Navier--Stokes equations, accuracy stated as better than 0.2% (p. 599). Re = dU/nu, d = upstream channel half-height, U = maximum inlet velocity (p. 596). |
| L1188: Re_c = 40.45 で対称性破壊（ピッチフォーク）分岐，一対の安定な非対称解，実験とよく一致 | partly | 601 (number); 599--602 | The number is right: Re_c = 40.45 +/- 0.17% (p. 601). Three qualifications. (i) It is the **numerical** prediction for a perfectly symmetric channel (p. 601); the experiment showed no critical Reynolds number (p. 602). (ii) The paper's term is symmetry-breaking bifurcation; **the word pitchfork is not in the paper**. (iii) Agreement is called satisfactory away from the immediate vicinity of the bifurcation point (p. 601), good in the abstract (p. 595) and close in the conclusions (p. 607). Supported parts: above Re_c there are three solutions, the symmetric one unstable and two stable asymmetric ones of opposite sense (p. 601); in the experiment either the upper or the lower recirculation region becomes the longer one (p. 600). Flow visualization: a unique stable symmetric flow below about Re 35 (p. 599) and no stable symmetric flow above Re 33 (pp. 599--600). |
| L1189: 実験の分岐図は小さな欠陥で分断，明確な臨界 Re は無い，Re をゆっくり上げると常に上側が長い枝，反対の枝は Re > 50 の急な立ち上げでのみ到達，その場合はどちらの側にも偏り無し | supported (one wording caveat) | 601--602 | The experimental bifurcation diagram is disconnected, which the authors attribute to small, unavoidable imperfections of the apparatus (pp. 601--602). No critical Reynolds number and no perfectly symmetric state were observed (p. 602). Only the upper branch (longer upper recirculation region) could be reached by a continuous increase of Re (p. 602). The lower branch (longer lower recirculation region) was disconnected and reachable only by starting the flow impulsively at Re > 50; with that method the larger separation 'might attach to either side of the channel without preference' (p. 602). Caveat: 「ゆっくり」 is the note's word; the paper says the increase was continuous and gives no rate. The term imperfect bifurcation (不完全分岐) is also the note's; the paper speaks of a disconnected diagram. No number of impulsive starts is reported. |
| L1190: 分断された枝は Re = 47.3 まで下げると不安定になり接続した枝へ不連続に移る（ヒステリシス） | partly | 602 | Facts right: the low-Reynolds-number limit of stability of the lower branch, found by decreasing Re, is Re = 47.3, where the flow jumped abruptly to the upper branch (the authors' adverb is catastrophically) (p. 602). But **the authors do not call this hysteresis**; the label is the note's. The paper describes no loop and no return path beyond the two facts (reachable only by impulsive start at Re > 50; lost at 47.3 on the way down). |
| L1191: 下流部を 0.05 mm（装置の 1% 未満）ずらした計算で分岐図が分断，極限点が臨界点から 13% 以上ずれ，分断の大きさは実験と同程度 | supported | 602, 604 (Fig. 9 on p. 604) | The whole downstream section of the grid was shifted up by 0.05 mm relative to the axis of symmetry (p. 602). The authors state that this amounts to under 1% of the apparatus and corresponds to their estimate of the misalignment between the two sections (p. 604). It disconnects the bifurcation diagram and shifts the limit point by over 13% from the original critical point; the experimental disconnection is of the same order (p. 604). The paper concludes that the recorded features are properties of the Navier--Stokes equations and not of the accuracy of this rig (p. 604). Not printed: the Reynolds number of the shifted limit point, and the length against which the 1% is taken. |
| L1192: 開いた系の欠陥の影響は，閉じた Taylor--Couette 系（1--2%）よりはるかに大きい | supported (the paper hedges) | 604--605 | One sentence: the authors remark that imperfections appear to matter far more in this open system than in a closed one, and give the Taylor--Couette system (disconnection of order 1--2%, Pfister et al. 1988) as the comparison (pp. 604--605). It is a hedged remark, not an analysis. |
| L1193: Re 約 125 で第 3 の再循環，Re 約 151 超で非定常，2D Hopf ではなく先に生じた 3 次元性 | supported | 605--607 | Third recirculation region observed at Re = 125, on the same wall as the small recirculation; it is also present in the steady 2D numerical solution (p. 605). The flow was seen to become unsteady at about Re 155, and the highest Re with steady flow in the LDV measurements was 151 (p. 606). A search for a Hopf bifurcation on the asymmetric branches indicated that the loss of steadiness was not a two-dimensional Hopf bifurcation; three-dimensional circulations were already visible at Re = 140 while the flow still looked steady, i.e. three-dimensionality preceded unsteadiness; the authors conclude only that a three-dimensional disturbance may be the cause (p. 607). |
| L1194 限界: 閉じ込め水路の層流（Re 数百まで），欠陥のモデルは下流部の平行移動 1 種類，枝の選択は Re をゆっくり変えた場合と急に立ち上げた場合の 2 通りのみ | supported | 596--598, 602 | Flow conditioners give controlled flow for Re 0--400 (p. 597); distilled water served for investigations up to Re = 380 (p. 598), while the largest Reynolds numbers for which results are shown are 273 for the inlet profile (Fig. 2, p. 598) and 207 downstream (p. 606). One geometry only (p. 596). One imperfection only, the 0.05 mm shift in one direction (p. 602). The two ways of reaching a branch are the continuous increase and the impulsive start at Re > 50 (p. 602). The word laminar (層流) is the note's: the authors do not apply it to their own flow (it occurs only on p. 595 about Taylor--Couette flow and on p. 608 in a reference title); they speak of low Reynolds number flow (p. 597) and of steady flow up to Re = 151 (p. 606). |
| L1195 接点 (前半): 「不完全分岐では小さな欠陥が枝を選ぶ」ことを実験と数値の両方で定量的に示した原典 | partly | 595, 601--604 | Shown: small imperfections disconnect the diagram, only one branch is reached by a continuous increase, and a 0.05 mm offset reproduces a disconnection of the same order (pp. 601--604). **Not stated**: a rule that the sign or direction of the imperfection decides which side is preferred. Only one offset direction was computed, the direction of the misalignment of the real rig is not reported, and the paper does not say the offset direction was chosen to match the experiment. In Fig. 9 the connected numerical branch is the upper one, as in the experiment (figure reading, p. 604). On priority, the authors describe their work as the first extensive use of bifurcation theory in an experimental study of this flow (p. 595). |
| L1195 接点 (1): 枝が偏るのは Re をゆっくり上げた場合で，急に立ち上げると偏りは消えた | supported | 602 | As in the L1189 row. The impulsive start was used only at Re > 50. The rest of the sentence (that the start-up of the present experiment may affect the branch) is the note's inference about our experiment, not a statement of the paper. |
| L1195 接点 (2): 欠陥の符号が一定なら優先される枝は一定で，Re による反転は単純な不完全ピッチフォークからは出てこない | not found | -- | **The paper says nothing about the preferred side changing with Reynolds number, and nothing about the sign of the imperfection.** This sentence is the note-writer's own reasoning. It must not carry a citation of Fearn et al. |
| L1195 接点 (末尾): 開いた系ほど欠陥に敏感という指摘は，開水路の本研究にも当てはまる | partly | 595, 597, 604--605, 607--608 | First half: the hedged remark of pp. 604--605. Second half is not in the paper. Open system there means a through-flow channel as opposed to the closed Taylor--Couette system (pp. 595, 604--605, 607); the rig is a channel in a continuous flow circuit (p. 597), and no free surface is mentioned anywhere. The phrase open channel flows on p. 608 is not defined there; set beside the open-system wording of p. 595 it reads as through-flow channels and not as free-surface flow, but that is a reading, not a statement of the paper. |
| L1180 (Cherdron の AI-DRAFT 内の言及): 後の Fearn 1990 は定常 2D 解の対称性破壊分岐として説明し直している | supported | 607 | The conclusions state that bifurcation theory explains the steady asymmetric flows and that they are solutions of the two-dimensional Navier--Stokes equations (p. 607). |
| L619 (Mullin 2003 の確認済みメモ内の言及): 微小幾何欠陥がピッチフォークを大きく分断（Fearn 1990） | supported, except the word pitchfork | 601--604 | Consistent with the disconnection by small imperfections and the shift of over 13% (pp. 601--604). Pitchfork is the wording of the Mullin memo, not of Fearn et al. |

### Answers to the specific questions

| question | journal page | what the paper says |
|---|---|---|
| (a) symmetry-breaking bifurcation and its disconnection by imperfections | 601--602, 604 | Numerics, perfectly symmetric channel: the unique stable steady solution loses stability at Re_c = 40.45 +/- 0.17% through a symmetry-breaking bifurcation; above it three solutions exist, two of them stable and asymmetric with opposite sense (p. 601). Experiment: the diagram is disconnected by small imperfections of the apparatus, so there is no observed critical Reynolds number (pp. 601--602). Numerics with a 0.05 mm offset: disconnected diagram, limit point shifted by over 13% (p. 604). The word pitchfork is not used. |
| (b) branch taken when Re is raised, and how the other is reached | 602 | Continuous increase of Re leads only to the upper branch (longer upper recirculation region). The lower branch is reached only by an impulsive start at Re > 50, and then the larger separation attaches to either side without preference. No ramp rate and no number of trials are given. |
| (c) hysteresis | 602 (facts); 596, 608 (the word) | The authors never apply the word to their own results. The facts are: the lower branch cannot be reached by a continuous increase; once on it, decreasing Re leads to loss of stability at Re = 47.3 with a jump to the upper branch (p. 602). |
| (d) how small an imperfection suffices | 602, 604 | One size only was computed: a 0.05 mm shift of the downstream section, less than 1% of the apparatus, equal to the estimated misalignment of the two sections. No smaller size, no threshold and no scaling with size are given. The reference length for the 1% is not stated. Absolute channel dimensions are not given in the text; the axes of Figs 4, 7 and 10 are labelled y (mm) and carry the tick labels 6, 0, 6 (pp. 601, 603, 605; no minus sign is printed), the text puts the lower wall at y = -6 (p. 605), and the inlet-profile axis of Fig. 2 has the ticks 2, 0, -2 with no unit (p. 598), i.e. a downstream height of 12 mm and an upstream height of 4 mm by figure reading, consistent with the 3:1 ratio. |
| (e) preferred side changing with Reynolds number | -- | **Absent.** Under a continuous increase the same (upper) branch is followed over the whole range plotted in Fig. 8 (about Re 30 to 53 by figure reading, p. 604). At higher Re (125 to 207) the paper treats the third recirculation, three-dimensionality and unsteadiness (pp. 605--607) and mentions no change of side. The only statement about side preference is the absence of preference under an impulsive start (p. 602). |
| (f) open-flow versus closed-flow sensitivity to imperfections | 595, 604--605, 607 | The study is framed as carrying the Taylor--Couette (closed system) approach over to an open-system channel flow (p. 595). Imperfections appear to matter far more in this open system than in the closed one, where the disconnection is of order 1--2% (pp. 604--605). The route to time-dependence known from the closed system is judged not to apply to this open system (p. 607). |

## 2. Sentences the Introduction may safely use

Each sentence is a paraphrase, not a quotation. The page is the journal page; the bracket gives the AI-DRAFT line that carries the same content, for `\src{...}`. Every use needs `\unverified`.

1. Fearn et al. (1990) studied low-Reynolds-number flow through a plane symmetric sudden expansion of expansion ratio 3:1 by laser-Doppler velocimetry, flow visualization and finite-element bifurcation calculations of the two-dimensional Navier--Stokes equations. (pp. 596, 598--599) [L1186]
2. Their calculations for a perfectly symmetric channel give a symmetry-breaking bifurcation at a Reynolds number of 40.45, based on the upstream half-height and the maximum inlet velocity, above which two stable asymmetric flows of opposite sense exist. (pp. 596, 601) [L1188]
3. In their experiment the bifurcation was disconnected by small imperfections of the apparatus, so that no sharp critical Reynolds number was observed. (pp. 601--602) [L1189]
4. When the Reynolds number was increased continuously, the flow always followed the same branch, whereas the other branch could be reached only by starting the flow impulsively at a Reynolds number above 50. (p. 602) [L1189]
5. After an impulsive start at a Reynolds number above 50 the larger separation region attached to either wall without preference. (p. 602) [L1189]
6. On decreasing the Reynolds number, the disconnected branch lost stability at a Reynolds number of 47.3 and the flow jumped to the other branch. (p. 602) [L1190]
7. A calculation in which the downstream section was offset by 0.05 mm, less than 1% of the apparatus, reproduced a disconnection of the same order as in the experiment and moved the limit point by more than 13% from the critical point of the symmetric problem. (pp. 602, 604) [L1191]
8. The authors remarked that the imperfection appeared to have a much larger effect in this open system than in the closed Taylor--Couette system, where the disconnection is of order 1--2%. (pp. 604--605) [L1192]
9. They concluded that the steady asymmetric flows are solutions of the two-dimensional Navier--Stokes equations that arise at a symmetry-breaking bifurcation. (p. 607) [L1185, L1188]
10. Compressed form for one Introduction sentence: For low-Reynolds-number flow in a plane symmetric sudden expansion, Fearn et al. (1990) showed that the asymmetry arises at a symmetry-breaking bifurcation and that small imperfections of the apparatus disconnect it, so that a continuous increase in Reynolds number always leads to the same branch. (pp. 595, 601--602, 604) [L1188, L1189, L1191]

Wording to keep when citing this paper: symmetry-breaking bifurcation (not pitchfork, unless a second source carries that word; `literature/review_master.tex` L617 and L619, the confirmed Mullin et al. 2003 memo, use it); continuous increase (not slow increase); disconnected by small imperfections (the term imperfect bifurcation is not the paper's); low Reynolds number (the authors do not call their own flow laminar).

## 3. Do not cite this paper for

1. **A preferred side that reverses with Reynolds number or discharge.** Nothing of the kind is in the paper (question (e) above). The reasoning in L1195 (2) is the note-writer's.
2. **A rule that the sign or direction of an imperfection decides the preferred side.** One offset in one direction was computed (p. 602); the direction of the real misalignment is not reported (pp. 602, 604).
3. **Hysteresis as the authors' own finding or term**, or the width of a hysteresis loop. Only the two facts of p. 602 can be stated (sentences 4 and 6 above).
4. **An experimental critical Reynolds number.** The value 40.45 is numerical (p. 601); the experiment had none (p. 602). The visual statements on pp. 599--600 (below about 35; above 33) are not a measured threshold.
5. **Turbulent flow.** The work is at low Reynolds number, Re up to 380 with steady flow up to 151 (pp. 598, 606). The statement that asymmetry and multiple solutions persist in the turbulent regime is a citation of Abbott & Kline (1962) and Restivo & Whitelaw (1978) on p. 596, not a result of this paper.
6. **Free-surface, shallow-water or reservoir flows, or jets in basins.** None is mentioned. The open system of the paper is a through-flow channel in a closed circuit (pp. 595, 597), so the sensitivity remark of pp. 604--605 does not transfer to open-channel (free-surface) flow on the authority of this paper. The last clause of L1195 does exactly this and must not be cited.
7. **How small an imperfection suffices in general**, a threshold, or a scaling of the disconnection with the size of the imperfection. One size only (pp. 602, 604).
8. **Probabilities or counts of branch choice** under an impulsive start. The paper only says there was no preference (p. 602).
9. **The dependence on expansion ratio or aspect ratio.** One geometry was studied; the dependence is reported from earlier experiments (p. 596).
10. **Any comparison of Reynolds number with the present experiment.** The definition uses the upstream half-height and the maximum inlet velocity (p. 596), and the Reynolds number of the present experiment rests on a placeholder (the water temperature, hence the kinematic viscosity; `paper/README.md` L90).
11. **The start-up procedure of the present experiment.** L1195 states that filming began at 20 mm during filling, as does `doc/settled_and_retracted.md` L30 (dated 11-15); the later `paper/README.md` L85--87 (11-22) lists the start-up procedure, including whether filming began at 20 mm or 30 mm, as a placeholder to be confirmed by the user. Follow `paper/README.md` and do not copy that clause from the note.

## 4. Bibliographic data as printed on the paper (authors, year, journal, volume, pages) and whether literature/refs/zotero_export.bib (key fearnNonlinearFlowPhenomena1990) matches

Printed on p. 595:

| field | as printed (p. 595) | `literature/refs/zotero_export.bib` L412--427 | match |
|---|---|---|---|
| authors | R. M. Fearn, T. Mullin and K. A. Cliffe | Fearn, R. M. and Mullin, T. and Cliffe, K. A. (L414) | yes |
| title | Nonlinear flow phenomena in a symmetric sudden expansion | same words, in title case (L413) | yes (capitalization differs) |
| year | 1990 | 1990 (L415) | yes |
| journal | J. Fluid Mech. | Journal of Fluid Mechanics (L417) | yes |
| volume | 211 | 211 (L418) | yes |
| pages | 595--608 | 595--608 (L419) | yes |
| DOI | 10.1017/S0022112090001707 (publisher's margin stamp on every page) | same (L421) | yes |
| month | not printed | feb (L416) | cannot be checked from the PDF |
| issue | not printed | absent | -- |

- Also printed on p. 595: affiliations (Fearn and Mullin: Clarendon Laboratory, Oxford; Cliffe: Theoretical Physics Division, Harwell Laboratory) and the dates (received 29 March 1989, revised 29 July 1989).
- `paper/2026_journal_Shonai/jhr/refs.bib` L268--277 (generated by `make_bib.py`) carries the same authors, title, year, journal, volume, pages and DOI, without the month.
- Three authors, so the in-text form is Fearn et al. (1990).

## 5. Gaps (leave as placeholders or leave out; do not guess)

1. Rate at which the Reynolds number was increased in the continuous-increase runs: not given (p. 602).
2. Number of impulsive starts and how often each side was obtained: not given (p. 602).
3. Reynolds number of the shifted limit point in the perturbed calculation: not printed; only the shift of over 13% is (p. 604). The product 40.45 x 1.13 = 45.7 is arithmetic on the printed numbers, and Fig. 9 shows the limit point slightly above Re = 45 by figure reading; neither is a value stated by the authors.
4. Length against which the offset of 0.05 mm is less than 1%: not stated (p. 604). Channel dimensions appear only as figure axes.
5. Direction and size of the actual misalignment of the rig: only an estimate equal to the imposed 0.05 mm is mentioned (p. 604); the direction is not reported.
6. Whether a smaller offset would also disconnect the diagram, and how the shift scales with the offset: not examined.
7. Details of the numerical method and of the three-dimensional and time-dependent effects are deferred to Fearn (1988, D.Phil. thesis) and Cliffe (1989, in preparation) (pp. 599, 607, 608); neither is in hand.
8. Month of publication (bib says February): not on the paper.
9. Stale line in the literature chat's file, for information only: `literature/review_master.tex` L1237 still lists Cherdron et al. 1978 and Fearn et al. 1990 as not obtained, although both now have AI-DRAFT blocks (L1170, L1184). Not ours to edit.

## Audit (second reader)

- Audited 2026-11-22 by a second subagent, independently of the writer of sections 1--5. Like the first check this is an AI check, not the user's; the `\unverified` mark stays (`paper/README.md` L76--78, L171).
- Method: all 14 PDF pages re-read as page images (journal pp. 595--608) and as a text layer; the word searches of the header were repeated on de-hyphenated text and on Zotero's own text cache of the PDF. Also opened: `literature/review_master.tex` L611--624, L1170--1196, L1237; `literature/refs/zotero_export.bib` L412--427; `paper/2026_journal_Shonai/jhr/refs.bib` L268--277; `paper/README.md` L43--172; `doc/settled_and_retracted.md` L12--49; `paper/2026_journal_Shonai/jhr/CONVENTIONS.md` L73--82.
- Scope: every row and item of sections 1--5 (about 120 single statements), not a sample.

### Result

- **No number is wrong.** Read again on the page: 40.45 +/- 0.17% (p. 601); Re > 50 and 47.3 (p. 602); 0.05 mm (p. 602); less than 1% and over 13% (p. 604); 1--2% (p. 605); 125 (p. 605); about 155 and 151 (p. 606); 140 (p. 607); about 7 cSt, 60, 380 and about 1% (p. 598); 0--400, 60 channel-heights, 80 step-heights, 8:1 (p. 597); 3:1 and 8:1 (p. 596); 15 mm, 30 to 280, 0.2%, about 35 (p. 599); 33 (pp. 599--600).
- **The verdicts of section 1 stand**, including the "partly" verdicts (L1188, L1190, L1195 first half, L1195 last clause) and the "not found" verdict for L1195 (2).
- Status of the note: `literature/review_master.tex` L1184--1196 is still an AI-DRAFT (every line begins with `%`). It is citable only under the exception of `paper/README.md` L76--78 and `CONVENTIONS.md` L77--78, with `\unverified`. The key `fearnNonlinearFlowPhenomena1990` exists (`literature/refs/zotero_export.bib` L412). The Mullin et al. (2003) memo that the sheet calls confirmed is confirmed text (`literature/review_master.tex` L611--624, not commented out, 「確認: p.433--452」 at L624).
- Section 4 (bibliographic data): every row agrees with p. 595 and with the two bib files at the cited lines.
- Against `doc/settled_and_retracted.md` §2 (L38--49): the sheet carries no retracted statement and no CFD content. Its one remark on the start-up of the present experiment (section 3, item 11) reports the open point as it stands in `paper/README.md` L85--87 and does not say that the experiment began from still water.
- The only direct quotation in the sheet (section 1, row L1189) is 10 words long and matches p. 602.

### Changed in place (8 small edits; they tighten wording, none changes a number or a verdict)

1. Section 1, row L1194: "measurements up to Re = 380" replaced. The paper says only that distilled water served for investigations up to Re = 380 (p. 598); the largest Reynolds numbers for which results are shown are 273 (Fig. 2, p. 598) and 207 (p. 606).
2. Section 1, row L1195 (末尾): the sheet stated as a fact that open channel flows on p. 608 "is used in" the through-flow sense. The paper does not define the phrase (p. 608). Now marked as a reading.
3. Answers, row (d): "axes run from -6 to 6 mm" replaced by what is printed: tick labels 6, 0, 6 on an axis labelled y (mm), without a minus sign (pp. 601, 603, 605); the value y = -6 is in the text of p. 605. The ticks of Fig. 2 (2, 0, -2; p. 598) added as a cross-check of the 3:1 ratio.
4. Section 2, sentence 5: "at a Reynolds number above 50" added. The absence of preference was observed only with the impulsive start at Re > 50 (p. 602).
5. Section 2, sentence 8: "open flow" changed to "open system", the paper's own term (pp. 604--605), so that the sentence cannot be read as open-channel (free-surface) flow (cf. section 3, item 6).
6. Section 2, sentence 10: p. 604 and L1191 added to the sources, because "showed that small imperfections disconnect it" rests on the calculation with the offset grid (pp. 602, 604) and not only on the attribution on pp. 601--602.
7. Section 3, item 4: "p. 599" changed to "pp. 599--600" (the sentence about Re above 33 runs over the page break).
8. Section 3, item 10: `paper/README.md` L90 lists the water temperature (hence the kinematic viscosity and the Reynolds number) as the blank, not the Reynolds number as such. Reworded.

### Confirmed by figure reading only (approximate; not for the manuscript)

- Fig. 8 (p. 604): the Re axis has ticks from 30 to 55; the experimental crosses run from about 30 to about 53 on the upper branch and from about 47 to about 53 on the lower branch.
- Fig. 9 (p. 604): the connected numerical curve is the upper one; the limit point of the disconnected lower branch lies a little above Re = 45, consistent with 40.45 x 1.13 = 45.7 (arithmetic on printed numbers, not a printed value; gap 3 stands).

### Additional observations (not in sections 1--5)

- p. 601: the sign of the asymmetry measure (vertical velocity at a fixed point 25.5 mm downstream, pp. 600--601) is said to depend "initially" on the sense of the asymmetry; the paper does not explain the adverb. This is a remark about the measure, not a statement that the preferred side changes with Reynolds number. Answer (e), "absent", stands.
- p. 607: the word bi-stable occurs once, for flip-flop devices as a possible application. The paper does not call its own flow bistable; what it states is that two stable asymmetric solutions of opposite sense exist above the critical Reynolds number (p. 601). If the manuscript uses bistability next to this citation, the word is ours.
- p. 595: the onset of asymmetry with increasing Reynolds number is said to be sometimes called the Coanda effect in the literature. The term is not used again in the paper.

### Could not verify (unverified by audit)

- Month of publication (bib: feb, `literature/refs/zotero_export.bib` L416): not printed on the paper. Gap 8 stands.
- Anything deferred to Fearn (1988) or Cliffe (1989) (pp. 599, 607, 608): not in hand. Gap 7 stands.
- The meaning of open channel flows on p. 608: a reading only (edit 2).
- The statements that certain words occur nowhere in the paper rest on the OCR text of a scanned PDF. Two text layers and the reading of all 14 page images agree, but an OCR miss cannot be ruled out strictly.

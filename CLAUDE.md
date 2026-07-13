# CLAUDE.md

This file gives Claude Code its working instructions for **psp-singleport-regime**.

## Single source of truth

The project's working conventions live in `AGENTS.md`. Treat it as authoritative
and follow it for all code, metadata, Git, and writing tasks.

@AGENTS.md

## Orientation

- `README.md` — research concept, pipeline overview, repository policy, and data layout.
- `AGENTS.md` — coding/Git/metrics/writing conventions (the rules above).
- `doc/piv_preprocessing_protocol.md` — rectification and frame-prep protocol.
- `metadata/README.md` — schema for `runs.csv`, `depth_bands.csv`, `flow_levels.csv`.
- `scripts/README.md` — what each `s10`–`s40` driver does and the routine run order.

## Quick facts

- MATLAB, function-based (no `classdef`). Reusable logic in `src/`, coarse driver
  scripts in `scripts/` (`s10` prepare frames → `s20` import PIV → `s30` metrics,
  with `s25`/`s35` optional; `s40` is an unimplemented placeholder).
- Analysis is **tool-agnostic after import**: PIVLab/external PIV are normalized
  into the canonical `piv` struct before any metric computation.
- `local/` is a gitignored, machine-local data root and is **not** synced by Git.
  Daily per-run settings go in disposable copies under the gitignored `tmp/`
  folder (copy a script from `scripts/`, edit the copy, run it from there).
- `main` is sync-only; do substantial work on a topic branch.

## 2台運用の同期ルール（重要）
このリポジトリは2台のPC（WS=ラボ, LT=ノート）で共有している。
- ユーザーが「pushして」「離れる」等と言ったら: `git add -A` で作業中のファイルも含めて全てcommit（WIPコミットで可）し、`git push` する。中途半端な変更を勝手に除外しない。
- ユーザーが「pullして」「始める」等と言ったら: 最初に `git pull` し、コンフリクトがあれば止めて報告する。
- 大容量データ（tiff等）や環境固有の設定（ローカルパス）はコミットしない。

#!/bin/bash
# run_case.sh -- ケースを最後まで流す.
#   メッシュ作成 → checkMesh → (system/pre_run.sh があれば実行) → 初期水位 → 分割
#   → 本計算 → 表面サンプリング
#
#   usage: bash run_case.sh <ケースのパス> [--foreground] [--allow-parallel]
#
# 既定では切り離して (setsid nohup) 実行するので, ssh や VPN が切れても止まらない.
# 進行は <ケース>/run.log に追記される. 進捗は case_status.sh で見る.
# 並列数は system/decomposeParDict の numberOfSubdomains (既定 16) に従う.
set -uo pipefail

TOOLS="$(cd "$(dirname "$0")" && pwd)"
[ $# -ge 1 ] || { sed -n '2,12p' "$0"; exit 1; }
CASE="$(cd "$1" 2>/dev/null && pwd)" || { echo "ケースが見つからない: $1"; exit 1; }
shift
FOREGROUND=0
ALLOW_PARALLEL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --foreground) FOREGROUND=1; shift ;;
    --allow-parallel) ALLOW_PARALLEL=1; shift ;;
    *) echo "不明な引数: $1"; exit 1 ;;
  esac
done

# --- 安全装置 (参照ケースを壊さない / 結果を消さない) -------------------------------
case "$CASE" in
  */psp_tests/*) echo "psp_tests は参照ケース (読み取り専用). new_case.sh で自分のケースを作ること"; exit 1 ;;
esac
[ -w "$CASE" ] || { echo "書き込めない: $CASE  (psp_tests からコピーしたなら chmod -R u+w で書けるようにする)"; exit 1; }
{ [ -d "$CASE/system" ] && [ -d "$CASE/0.orig" ]; } \
  || { echo "ケースの形をしていない (system/ と 0.orig/ が要る): $CASE"; exit 1; }
if ls -d "$CASE"/processor* >/dev/null 2>&1; then
  echo "既に回した形跡がある (processor* がある). 結果を消さないよう中止する."
  echo "やり直すなら new_case.sh で別名のケースを作ること (失敗ケースも台帳に残す)"
  exit 1
fi
if pgrep -x interFoam >/dev/null && [ "$ALLOW_PARALLEL" = 0 ]; then
  echo "別の interFoam が走っている. 同時に回すと両方とも遅くなる."
  echo "待つのが基本. どうしても並行するなら --allow-parallel を付ける"
  exit 1
fi

if [ "$FOREGROUND" = 1 ]; then
  bash "$TOOLS/_pipeline.sh" "$CASE" 2>&1 | tee -a "$CASE/run.log"
else
  setsid nohup bash "$TOOLS/_pipeline.sh" "$CASE" >> "$CASE/run.log" 2>&1 < /dev/null &
  echo "切り離して開始した: $CASE"
  echo "進捗:   bash $TOOLS/case_status.sh $CASE"
  echo "1-2 分後に一度 case_status.sh を見て, 乱流モデルなどの選択が意図どおりか確認すること"
  echo "(OpenFOAM は綴りを間違えた設定を黙って無視する)"
fi

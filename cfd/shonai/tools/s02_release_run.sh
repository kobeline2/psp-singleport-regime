#!/bin/bash
# s02_release_run.sh -- s02_release_setup.sh で作ったケースを再開して最後まで流す (切り離し実行).
#   usage: bash s02_release_run.sh <ケースのパス>
# run_case.sh は processor* があると中止するので, 再開はこちらを使う. 進捗は case_status.sh で見る.
CASE="$(cd "$1" && pwd)" || exit 1
case "$CASE" in */psp_tests/*) echo "参照ケースでは実行しない"; exit 1 ;; esac
pgrep -x interFoam >/dev/null && { echo "別の interFoam が走っている"; exit 1; }
cat > "$CASE/_restart_body.sh" <<'BODY'
. /usr/lib/openfoam/openfoam2412/etc/bashrc 2>/dev/null
cd "$1" || exit 1
log() { echo "[$(date '+%F %T')] $*"; }
rm -f DONE FAILED
NP=$(awk '/^numberOfSubdomains/ {gsub(/;/,""); print $2}' system/decomposeParDict)
log "再開: $1 ($NP ランク)"
mpirun -np "$NP" --oversubscribe interFoam -parallel > log.interFoam 2>&1
log "interFoam 終了: $(grep -c '^Time = ' log.interFoam) steps, $(grep '^Time = ' log.interFoam | tail -1)"
grep -q "FOAM FATAL" log.interFoam && { log "失敗: FATAL"; touch FAILED; exit 1; }
mpirun -np "$NP" --oversubscribe postProcess -func surfSample -parallel > log.surfSample 2>&1 || { log "失敗: surfSample"; touch FAILED; exit 1; }
log "表面サンプリング: $(ls postProcessing/surfSample 2>/dev/null | wc -l) 時刻"
touch DONE; log "完了"
BODY
setsid nohup bash "$CASE/_restart_body.sh" "$CASE" >> "$CASE/run.log" 2>&1 < /dev/null &
echo "切り離して開始した: $CASE"

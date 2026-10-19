#!/bin/bash
# _pipeline.sh -- run_case.sh から呼ばれる本体. 直接は使わない.
# OpenFOAM の bashrc は set -e や関数の中で読むと壊れる (pop_var_context エラー) ので,
# このスクリプトの最上位で, エラーを無視して読む.
CASE="$1"
. /usr/lib/openfoam/openfoam2412/etc/bashrc 2>/dev/null
cd "$CASE" || exit 1

log() { echo "[$(date '+%F %T')] $*"; }
fail() { log "失敗: $*"; touch FAILED; exit 1; }

NP=$(awk '/^numberOfSubdomains/ {gsub(/;/,""); print $2}' system/decomposeParDict)
log "開始: $CASE  ($NP ランク)"

if [ -f system/blockMeshDict ]; then
  blockMesh > log.blockMesh 2>&1 || fail "blockMesh (log.blockMesh を見ること)"
  log "blockMesh: $(grep -m1 'nCells' log.blockMesh | sed 's/^ *//')"
fi
checkMesh > log.checkMesh 2>&1
grep -q "Mesh OK" log.checkMesh || fail "checkMesh が Mesh OK を返さない (log.checkMesh)"
log "checkMesh: Mesh OK"

# メッシュ手術 (流入面の分割など) はケースの system/pre_run.sh に書く. cfd/recipes を参照
if [ -f system/pre_run.sh ]; then
  log "system/pre_run.sh を実行"
  bash system/pre_run.sh > log.pre_run 2>&1 || fail "pre_run.sh (log.pre_run)"
fi

rm -rf 0 && cp -r 0.orig 0
setFields > log.setFields 2>&1 || fail "setFields (log.setFields)"
log "setFields: $(grep -m1 'Selected' log.setFields | sed 's/^ *//')  (基準メッシュなら 121556 = 水位 20.00 mm)"

decomposePar -force > log.decomposePar 2>&1 || fail "decomposePar (log.decomposePar)"

log "interFoam 開始"
mpirun -np "$NP" --oversubscribe interFoam -parallel > log.interFoam 2>&1
STEPS=$(grep -c '^Time = ' log.interFoam)
LAST=$(grep '^Time = ' log.interFoam | tail -1)
log "interFoam 終了: $STEPS steps, $LAST"
grep -q "FOAM FATAL" log.interFoam && fail "interFoam に FATAL (log.interFoam の末尾を見ること)"

log "表面サンプリング (postProcess -func surfSample)"
mpirun -np "$NP" --oversubscribe postProcess -func surfSample -parallel > log.surfSample 2>&1 \
  || fail "surfSample (log.surfSample)"
log "表面サンプリング: $(ls postProcessing/surfSample 2>/dev/null | wc -l) 時刻"

touch DONE
log "完了. 動画と指標: python3 <repo>/cfd/tools/surface_movie.py $CASE"

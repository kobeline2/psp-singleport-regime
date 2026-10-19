#!/bin/bash
# レシピ P05_symmetric_fast のメッシュ手術. run_case.sh がメッシュ作成の直後に, ケースの中で実行する.
# 出力は log.pre_run. 基準メッシュなら「faceSet upFaces now size 22」になるはず.
topoSet > log.topoSet 2>&1 || exit 1
grep "now size" log.topoSet | tail -1
createPatch -overwrite > log.createPatch 2>&1 || exit 1
grep "faces from faceSet" log.createPatch

#!/bin/bash
# レシピ S17_slip_p02 のメッシュ手術. run_case.sh がメッシュ作成の直後に, ケースの中で実行する.
# 出力は log.pre_run. 基準メッシュなら「faceSet loFaces now size 24」と「faceSet floorFaces now size 30389」になるはず.
topoSet > log.topoSet 2>&1 || exit 1
grep "now size" log.topoSet
createPatch -overwrite > log.createPatch 2>&1 || exit 1
grep "faces from faceSet" log.createPatch

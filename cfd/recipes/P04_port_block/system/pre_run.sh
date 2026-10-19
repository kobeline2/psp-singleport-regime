#!/bin/bash
# レシピ P04_port_block のメッシュ手術. run_case.sh がメッシュ作成の直後に, ケースの中で実行する.
# 出力は log.pre_run. 基準メッシュなら「Converted 11 faces into boundary faces」になるはず.
topoSet > log.topoSet 2>&1 || exit 1
grep "now size" log.topoSet | tail -1
createBaffles -overwrite > log.createBaffles 2>&1 || exit 1
grep "Converted" log.createBaffles

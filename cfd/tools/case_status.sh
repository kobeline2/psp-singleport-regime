#!/bin/bash
# case_status.sh -- ケースの進捗と健全性を表示する.
#   usage: bash case_status.sh <ケースのパス>
CASE="${1:?ケースのパスを指定}"
cd "$CASE" || exit 1

echo "=== $CASE"
[ -f DONE ] && echo "状態: 完了" || { [ -f FAILED ] && echo "状態: 失敗 (run.log を見ること)" || echo "状態: 実行中または未開始"; }
pgrep -x interFoam >/dev/null && echo "WS 上で interFoam が実行中 ($(pgrep -x interFoam | wc -l) プロセス)"
[ -f run.log ] && { echo "--- run.log (末尾)"; tail -4 run.log; }

if [ -f log.interFoam ]; then
  echo "--- 選択されたモデル (意図どおりか確認. 綴り違いは黙って無視される)"
  grep -m4 -E "^Selecting (turbulence model type|RAS turbulence model|LES model|incompressible transport)" log.interFoam \
    || echo "  (まだ出ていない)"
  END=$(awk '/^endTime/ {gsub(/;/,""); print $2}' system/controlDict)
  T=$(grep '^Time = ' log.interFoam | tail -1 | awk '{print $3}')
  E=$(grep 'ExecutionTime' log.interFoam | tail -1 | awk '{print $3}')
  N=$(grep -c '^Time = ' log.interFoam)
  DT=$(grep '^deltaT' log.interFoam | tail -1 | awk '{print $3}')
  echo "--- 進捗"
  awk -v t="$T" -v e="$E" -v n="$N" -v end="$END" -v dt="$DT" 'BEGIN{
    if (t == "" || e == "" || t <= 0) { print "  まだ時間ステップが出ていない"; exit }
    printf "  t = %s / %s s,  %d steps,  dt = %s s\n", t, end, n, dt
    printf "  経過 %.2f h,  壁:実時間 = %.1f:1,  残り約 %.1f h\n", e/3600, e/t, (end-t)*(e/t)/3600 }'
  echo "  FATAL: $(grep -c 'FOAM FATAL' log.interFoam)   bounding: $(grep -ci 'bounding' log.interFoam)"
fi

# 質量保存: 水量の増加率 / 流入流量 (100 % が正常. 99 % 台なら許容, 98 % 以下は要調査)
Q=$(grep -E '^\s*flowRate' 0.orig/U 2>/dev/null | head -1 | awk '{gsub(/;/,""); print $2}')
VF=$(ls postProcessing/waterVolume/*/volFieldValue*.dat 2>/dev/null)
if [ -n "$Q" ] && [ -n "$VF" ]; then
  cat $VF | grep -v '^#' | sort -g | awk -v q="$Q" 'NF>=2 { if (!s) { t0=$1; v0=$2; s=1 } t1=$1; v1=$2 }
    END { if (t1 > t0) printf "--- 質量保存: %.2f %%  (t = %.0f-%.0f s, Q = %s)\n", 100*(v1-v0)/(q*(t1-t0)), t0, t1, q }'
fi

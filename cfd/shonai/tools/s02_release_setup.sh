#!/bin/bash
# s02_release_setup.sh -- P02 (流入面の上半分のみ注水) の t=T の場から, 流入面全体の注水に切り替えて再開するケースを作る.
#   usage: bash s02_release_setup.sh [ケース名] [T]     既定: S02_p02_release 600
# 参照ケース psp_tests/P02_perturb_geom は読むだけ (書かない).
#
# 切り替え: 壁 inletLowerWall (24 面) を注水面にする. 流入面全体 (44 面) で Q = 0.0005 m3/s を
#   面積按分して配る (variableHeightFlowRateInletVelocity は各パッチの flowRate を濡れ面積で割るので,
#   inletLowerWall = Q*24/44, inletOutlet = Q*20/44 とすれば流入速度は B03 と同じ).
# 手順: P02 の serial メッシュと processor*/T をコピー -> reconstructPar (ascii) -> 境界条件を書き換え
#       -> decomposePar -time T. 場の書式は ascii で書き換えるので, 終わったら writeFormat を binary に戻す.
. /usr/lib/openfoam/openfoam2412/etc/bashrc 2>/dev/null
set -u
NAME="${1:-S02_p02_release}"; T="${2:-600}"
SRC=$HOME/OpenFOAM/yuna-v2412/run/psp_tests/P02_perturb_geom
DEST=$HOME/OpenFOAM/yuna-v2412/run/psp_shonai/$NAME
Q=0.0005; NLOW=24; NALL=44
[ -e "$DEST" ] && { echo "既にある: $DEST"; exit 1; }
[ -d "$SRC/processor0/$T" ] || { echo "P02 に t=$T が無い"; exit 1; }
log() { echo "[$(date '+%F %T')] $*"; }

mkdir -p "$DEST" && cd "$DEST" || exit 1
cp -r "$SRC/constant" "$SRC/system" "$SRC/0.orig" .
for p in "$SRC"/processor*; do
  n=$(basename "$p"); mkdir -p "$n"
  cp -r "$p/constant" "$n/"; cp -r "$p/$T" "$n/"
done
chmod -R u+w .
log "P02 の t=$T をコピー ($(du -sh . | cut -f1))"

# --- 面積比の確認 (serial メッシュが ascii のときだけ) -----------------------------
python3 - <<'PY'
import re
m = "constant/polyMesh/"
def body(f):
    t = open(m+f, encoding="utf-8", errors="replace").read()
    return t
if "format      ascii" not in body("points")[:600]:
    print("points は ascii でない: 面積比の確認を省略"); raise SystemExit
pts = [tuple(map(float, l.strip("()\n").split())) for l in re.findall(r"^\(.*\)$", body("points"), re.M)]
faces = [tuple(map(int, l.split("(")[1].rstrip(")").split())) for l in re.findall(r"^\d+\(.*\)$", body("faces"), re.M)]
b = body("boundary")
def area(name):
    s = re.search(name + r"\s*\{[^}]*?nFaces\s+(\d+);\s*startFace\s+(\d+);", b, re.S)
    n, s0 = int(s.group(1)), int(s.group(2))
    tot = 0.0
    for f in faces[s0:s0+n]:
        p = [pts[i] for i in f]
        d1 = [p[2][k]-p[0][k] for k in range(3)]; d2 = [p[3][k]-p[1][k] for k in range(3)]
        c = (d1[1]*d2[2]-d1[2]*d2[1], d1[2]*d2[0]-d1[0]*d2[2], d1[0]*d2[1]-d1[1]*d2[0])
        tot += 0.5*(c[0]**2+c[1]**2+c[2]**2)**0.5
    return n, tot
nl, al = area("inletLowerWall"); no, ao = area("inletOutlet")
print(f"面数 inletLowerWall {nl} / inletOutlet {no};  面積 {al:.6g} / {ao:.6g};  下側の面積比 {al/(al+ao):.4f} (24/44 = {24/44:.4f})")
PY

# --- reconstruct (ascii) -> 境界条件の書き換え -> decompose ---------------------------
sed -i 's/^writeFormat .*/writeFormat      ascii;/' system/controlDict
reconstructPar -time "$T" > log.reconstructPar 2>&1 || { log "reconstructPar 失敗"; exit 1; }
rm -rf processor*
log "reconstructPar: $(ls $T | tr '\n' ' ')"

python3 - "$T" "$Q" "$NLOW" "$NALL" <<'PY'
import re, sys, glob, os
T, Q, nlow, nall = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
qlow, qup = Q*nlow/nall, Q*(nall-nlow)/nall
def entry(text, patch, body):
    pat = re.compile(r"(\n[ \t]*" + patch + r"\s*\{)(.*?)(\n[ \t]*\})", re.S)
    assert len(pat.findall(text)) == 1, patch
    return pat.sub(lambda m: m.group(1) + body + m.group(3), text)
low_U = "\n        type            variableHeightFlowRateInletVelocity;\n        flowRate        constant %.9g;\n        alpha           alpha.water;\n        value           uniform (0 0 0);" % qlow
up_U  = "\n        type            variableHeightFlowRateInletVelocity;\n        flowRate        constant %.9g;\n        alpha           alpha.water;\n        value           uniform (0 0 0);" % qup
low_p = "\n        type            fixedFluxPressure;\n        gradient        uniform 0;\n        value           uniform 0;"
low_a = "\n        type            fixedValue;\n        value           uniform 1;"
def edit(path, patch, body):
    t = open(path, encoding="utf-8").read()
    open(path, "w", encoding="utf-8").write(entry(t, patch, body))
for d in (T, "0.orig"):
    edit(f"{d}/U", "inletLowerWall", low_U)
    edit(f"{d}/p_rgh", "inletLowerWall", low_p)
    edit(f"{d}/alpha.water", "inletLowerWall", low_a)
edit(f"{T}/U", "inletOutlet", up_U)
# 0.orig の inletOutlet は flowRate 0.0005 のまま (元は全面注水の値). 面積按分に合わせる
t = open("0.orig/U", encoding="utf-8").read()
t = re.sub(r"(inletOutlet\s*\{.*?flowRate\s+)[0-9.eE+-]+;", lambda m: m.group(1) + "%.9g;" % qup, t, count=1, flags=re.S)
open("0.orig/U", "w", encoding="utf-8").write(t)
if os.path.exists(f"{T}/alpha.water_0"):
    edit(f"{T}/alpha.water_0", "inletLowerWall", low_a)
print("flowRate: inletLowerWall %.9g / inletOutlet %.9g" % (qlow, qup))
PY
sed -i "s/^startTime .*/startTime       $T;/; s/^writeFormat .*/writeFormat      binary;/" system/controlDict
decomposePar -force -time "$T" > log.decomposePar 2>&1 || { log "decomposePar 失敗"; exit 1; }
rm -rf "$T" 0
# reconstructPar は uniform/ (time, cumulativeContErr) を持ってこないので P02 のものを全ランクに補う
for p in processor*; do rm -rf "$p/$T/uniform"; cp -r "$SRC/processor0/$T/uniform" "$p/$T/"; done
log "decomposePar 完了: $(ls -d processor* | wc -l) ランク"
grep -E "^(startFrom|startTime|endTime|writeFormat)" system/controlDict
grep -c inletLowerWall processor0/$T/U
log "準備完了. 計算は s02_release_run.sh で開始する"

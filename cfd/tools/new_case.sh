#!/bin/bash
# new_case.sh -- テンプレートから新しいケースを作る (計算はまだしない).
#
#   usage: bash new_case.sh <ケース名> [--mesh base|fine|zfine]
#   例   : bash new_case.sh S01_sigma0
#          bash new_case.sh S05_fine_check --mesh fine
#
#   --mesh base   B01: 72 万セル. 水平 10-15 mm, 鉛直 5 mm (既定. 1000 s で約 5 時間)
#          fine   B07: 288 万セル. 水平を 2 倍細分 (約 41 時間)
#          zfine  B08: 138 万セル. 鉛直を 2.5 mm に (約 14 時間)
#
# 作られる場所: $PSP_RUN/<ケース名>  (既定 ~/OpenFOAM/yuna-v2412/run/psp_shonai)
# 中身はテンプレート (= 基準ケース B03 と同一設定) のコピー + 選んだメッシュ定義.
# 作ったら設定を 1 箇所だけ変え, cfd/shonai/cases.csv に行を足してから run_case.sh で回す.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
RUN_ROOT="${PSP_RUN:-$HOME/OpenFOAM/yuna-v2412/run/psp_shonai}"

NAME="${1:-}"
[ -n "$NAME" ] || { sed -n '2,17p' "$0"; exit 1; }
shift
MESH=base
while [ $# -gt 0 ]; do
  case "$1" in
    --mesh) MESH="$2"; shift 2 ;;
    *) echo "不明な引数: $1"; exit 1 ;;
  esac
done
case "$MESH" in
  base)  MESH_DICT=blockMeshDict ;;
  fine)  MESH_DICT=blockMeshDict_fine ;;
  zfine) MESH_DICT=blockMeshDict_zfine ;;
  *) echo "--mesh は base / fine / zfine のどれか"; exit 1 ;;
esac

DEST="$RUN_ROOT/$NAME"
case "$DEST" in
  */psp_tests/*) echo "psp_tests は参照ケース置き場 (読み取り専用). 別の場所に作ること"; exit 1 ;;
esac
[ -e "$DEST" ] && { echo "既にある: $DEST  (上書きしない. 別の名前にすること)"; exit 1; }

mkdir -p "$DEST"
cp -r "$REPO/cfd/template/0.orig" "$REPO/cfd/template/constant" "$REPO/cfd/template/system" "$DEST/"
cp "$REPO/cfd/template/mesh/$MESH_DICT" "$DEST/system/blockMeshDict"
rm -rf "$DEST/constant/polyMesh"

cat > "$DEST/NOTES.md" <<EOF
# $NAME

- 作成: $(date '+%F %T')
- テンプレート: $(git -C "$REPO" rev-parse --short HEAD) (branch $(git -C "$REPO" branch --show-current))
- メッシュ: $MESH ($MESH_DICT)
- 変更点: (基準ケース B03 からの変更を 1 行で. 1 ケース 1 変更)
EOF

echo "作成した: $DEST"
echo "次の手順:"
echo "  1. 設定を 1 箇所だけ変える (変更点を $DEST/NOTES.md に 1 行で書く)"
echo "  2. cfd/shonai/cases.csv に行を足す (purpose 列に判定基準を先に書く)"
echo "  3. bash $REPO/cfd/tools/run_case.sh $DEST"

#!/bin/bash
# Export a commit of this repository to $ESIBD_BUILD_DIR/src and install it, with the pinned packages,
# in the Windows Python of the Wine prefix.  Usage: prepare.sh [commit]   (default HEAD)
set -euo pipefail
source "$(dirname "$0")/env.sh"
COMMIT=$(git -C "$REPO" rev-parse "${1:-HEAD}")
rm -rf "$SRC"
mkdir -p "$SRC"
git -C "$REPO" archive "$COMMIT" | tar -x -C "$SRC"
echo "$COMMIT" > "$SRC/BUILT_FROM_COMMIT"
LOG=$ESIBD_BUILD_DIR/pip.log
CONSTRAINTS=$(winpath "$TOOLS/constraints-windows.txt")
{
    wine "$PY" -m pip install -c "$CONSTRAINTS" --no-deps --force-reinstall "$(winpath "$SRC")"
    # every pinned package, so that pip also moves those already installed to their pinned version
    wine "$PY" -m pip install -c "$CONSTRAINTS" $(sed 's/==.*//' "$TOOLS/constraints-windows.txt")
} > "$LOG" 2>&1
wine "$PY" -m pip freeze 2>/dev/null | tr -d '\r' > "$ESIBD_BUILD_DIR/freeze.txt"
if diff <(grep -v '^esibd-explorer\|^setuptools' "$ESIBD_BUILD_DIR/freeze.txt" | sort -f) <(sort -f "$TOOLS/constraints-windows.txt"); then
    echo "Prepared $COMMIT; the Windows Python has the pinned packages."
else
    echo "The Windows Python differs from constraints-windows.txt (above); see $LOG" >&2
    exit 1
fi

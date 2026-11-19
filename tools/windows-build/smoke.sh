#!/bin/bash
# Start the frozen Explorer under Wine on the Xvfb display for 240 s, with a fresh profile:
# screenshots at 60, 120 and 180 s and the Explorer log go to $ESIBD_BUILD_DIR/smoke*.
# stdout is closed, as for the windowed executable on Windows. With Qt 6.12 the test-only mscms stub
# is loaded (WINEDLLOVERRIDES=mscms=n, see wine-shims/README.md).  Usage: smoke.sh [FOLDER]   (default: the dist)
set -uo pipefail
source "$(dirname "$0")/env.sh"
export WINEDLLOVERRIDES=${WINEDLLOVERRIDES:-mscms=n}
PROFILE="$WINEPREFIX/drive_c/users/$USER/ESIBD Explorer"
[ -d "$PROFILE" ] && mv "$PROFILE" "$PROFILE.$(date +%Y%m%d-%H%M%S)"
rm -f "$ESIBD_BUILD_DIR"/smoke_*.png "$ESIBD_BUILD_DIR/smoke_explorer.log"
cd "${1:-$DIST}" || exit 1
timeout 240 wine "ESIBD Explorer.exe" < /dev/null >&- 2> "$ESIBD_BUILD_DIR/smoke_stderr.log" &
pid=$!
for t in 60 120 180; do
    sleep 60
    import -display "$DISPLAY" -window root "$ESIBD_BUILD_DIR/smoke_$t.png" 2>/dev/null
done
wait $pid
echo "exit $?" >> "$ESIBD_BUILD_DIR/smoke_stderr.log"
wineserver -k 2>/dev/null
cp "$PROFILE/conf/esibd explorer.log" "$ESIBD_BUILD_DIR/smoke_explorer.log" 2>/dev/null
# A run that is still alive at 240 s ends with exit 124; it must have reached Ready.
if grep -q ": Ready\." "$ESIBD_BUILD_DIR/smoke_explorer.log" 2>/dev/null && ! grep -q "Traceback\|❌" "$ESIBD_BUILD_DIR/smoke_explorer.log"; then
    echo "Smoke test OK: Ready, no error in the Explorer log."
else
    echo "Smoke test FAILED: see $ESIBD_BUILD_DIR/smoke_explorer.log, smoke_stderr.log and smoke_*.png" >&2
    exit 1
fi

#!/bin/bash
# Checks of the frozen Explorer: its version and fork code are in the bundle, and the standard-library
# modules the plugins import are there.  Usage: check.sh VERSION [MARKER_IN_ESIBD_CORE ...]
set -euo pipefail
source "$(dirname "$0")/env.sh"
unset DISPLAY
EXE=$(winpath "$DIST/ESIBD Explorer.exe")
wine "$PY" "$(winpath "$TOOLS/check_bundle.py")" "$EXE" "$@" 2>&1 | tr -d '\r'
PLUGINS=${ESIBD_PLUGINS_DIR:-$HOME/Git/esibd-explorer-plugins}
if [ -d "$PLUGINS" ]; then
    python3 "$TOOLS/plugin_imports.py" "$PLUGINS" > "$ESIBD_BUILD_DIR/plugin_imports.txt"
    wine "$PY" "$(winpath "$TOOLS/bundle_mods.py")" "$EXE" "$(winpath "$DIST/_internal")" \
        "$(winpath "$ESIBD_BUILD_DIR/plugin_imports.txt")" 2>&1 | tr -d '\r'
    echo "(built-in modules such as sys, time or msvcrt, and POSIX-only ones such as fcntl, are expected)"
fi

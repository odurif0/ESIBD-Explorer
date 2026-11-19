#!/bin/bash
# PyInstaller onedir build of the prepared sources, with the command of build.bat.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$SRC"
rm -rf pyinstaller_dist pyinstaller_build
wine "$PY" -m PyInstaller tools/windows_entrypoint.py -n "ESIBD Explorer" --noconsole --clean \
  --icon=esibd/media/ESIBD_Explorer.ico --add-data="esibd;esibd" --copy-metadata nidaqmx --copy-metadata nitypes \
  --noconfirm --additional-hooks-dir=./pyinstaller_hooks --distpath ./pyinstaller_dist --workpath ./pyinstaller_build \
  > "$ESIBD_BUILD_DIR/pyinstaller.log" 2>&1
find "$DIST" | sort > "$ESIBD_BUILD_DIR/dist_files.txt"
echo "Built $(wc -l < "$ESIBD_BUILD_DIR/dist_files.txt") files, $(grep -c WARNING "$ESIBD_BUILD_DIR/pyinstaller.log") PyInstaller warnings."
if grep -qi 'icu[a-z]*[0-9]*\.dll\|mscms\.dll' "$ESIBD_BUILD_DIR/dist_files.txt"; then
    echo "A Wine shim was bundled: remove it from the dist (see wine-shims/README.md)" >&2
    exit 1
fi

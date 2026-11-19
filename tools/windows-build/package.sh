#!/bin/bash
# Release files of the built Explorer: zip of the "ESIBD Explorer" folder, requirements-windows.txt and
# SHA256SUMS, in $ESIBD_BUILD_DIR/release-VERSION.  Usage: package.sh VERSION   (e.g. 1.0.2+od.5)
set -euo pipefail
source "$(dirname "$0")/env.sh"
VERSION=$1
OUT=$ESIBD_BUILD_DIR/release-$VERSION
# The smoke test leaves an empty folder of QtWebEngine in the dist: package the build output only.
LOCALES="$DIST/_internal/PyQt6/Qt6/resources/locales"
[ -d "$LOCALES" ] && [ -z "$(ls -A "$LOCALES")" ] && rmdir "$LOCALES"
find "$DIST" | sort | diff -q "$ESIBD_BUILD_DIR/dist_files.txt" - > /dev/null \
    || { echo "The dist differs from the build output (dist_files.txt)" >&2; exit 1; }
rm -rf "$OUT"
mkdir -p "$OUT"
(cd "$DIST/.." && zip -q -r -9 "$OUT/ESIBD-Explorer-$VERSION-win64.zip" "ESIBD Explorer")
sed "s|^esibd-explorer @ .*$|esibd-explorer==$VERSION  # this release, built from tag v$VERSION|" \
    "$ESIBD_BUILD_DIR/freeze.txt" > "$OUT/requirements-windows.txt"
(cd "$OUT" && sha256sum "ESIBD-Explorer-$VERSION-win64.zip" requirements-windows.txt > SHA256SUMS && cat SHA256SUMS)

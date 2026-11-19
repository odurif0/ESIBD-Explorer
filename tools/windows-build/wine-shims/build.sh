#!/bin/bash
# Build the two Wine shims and install them in the system32 of the build prefix (see README.md).
# Needs clang and an lld linker (rust-lld of rustup, or lld-link); downloads the official ICU binaries.
set -euo pipefail
source "$(dirname "$0")/../env.sh"
HERE=$TOOLS/wine-shims
WORK=$ESIBD_BUILD_DIR/wine-shims
mkdir -p "$WORK"
LLD=${LLD:-$(command -v lld-link || ls "$HOME"/.rustup/toolchains/*/lib/rustlib/*/bin/rust-lld 2>/dev/null | head -1)}
case "$LLD" in *rust-lld) LINK=("$LLD" -flavor link) ;; *) LINK=("$LLD") ;; esac
SYSTEM32=$WINEPREFIX/drive_c/windows/system32

# icuuc.dll: Qt 6.12's Qt6Core.dll imports 20 ucnv_* functions of the Windows system ICU, which Wine lacks.
# Each export forwards to the official ICU, whose names carry the version (ucnv_open_79).
ICU=79.1 ICU_ZIP=icu4c-79.1-Win64-MSVC2026.zip
ICU_SHA256=c4ae1cbadb4187007f76f8b1bcf3a10deb699395ab3c74df01362bfdfa0f1ac2
mkdir -p "$WORK/icu-$ICU/download" "$WORK/icu-$ICU/extract"
if [ ! -f "$WORK/icu-$ICU/download/$ICU_ZIP" ]; then
    curl -sSfL -o "$WORK/icu-$ICU/download/$ICU_ZIP" "https://github.com/unicode-org/icu/releases/download/release-$ICU/$ICU_ZIP"
fi
echo "$ICU_SHA256  $WORK/icu-$ICU/download/$ICU_ZIP" | sha256sum -c -
unzip -q -o "$WORK/icu-$ICU/download/$ICU_ZIP" -d "$WORK/icu-$ICU/extract"
MAJOR=${ICU%%.*}
EXPORTS=()
while read -r name; do EXPORTS+=("/export:$name=icuuc$MAJOR.${name}_$MAJOR"); done < "$HERE/icuuc/exports.txt"
echo "" > "$WORK/empty.c"
clang --target=x86_64-pc-windows-msvc -c "$WORK/empty.c" -o "$WORK/empty.obj"
"${LINK[@]}" /dll /noentry /nodefaultlib /machine:x64 "${EXPORTS[@]}" /out:"$WORK/icuuc.dll" "$WORK/empty.obj"
cp "$WORK/icuuc.dll" "$WORK/icu-$ICU/extract/bin64/icuuc$MAJOR.dll" "$WORK/icu-$ICU/extract/bin64/icudt$MAJOR.dll" "$SYSTEM32/"

# mscms.dll (smoke test only): Qt 6.12's qwindows.dll calls WcsCreateIccProfile, which Wine lacks.
# Wine keeps its own mscms unless WINEDLLOVERRIDES=mscms=n, which only smoke.sh sets.
clang --target=x86_64-pc-windows-msvc -O2 -c "$HERE/mscms/mscms_stub.c" -o "$WORK/mscms_stub.obj"
"${LINK[@]}" /dll /noentry /nodefaultlib /machine:x64 /out:"$WORK/mscms.dll" "$WORK/mscms_stub.obj"
[ -f "$SYSTEM32/mscms.dll.wine" ] || cp -p "$SYSTEM32/mscms.dll" "$SYSTEM32/mscms.dll.wine"
cp "$WORK/mscms.dll" "$SYSTEM32/mscms.dll"
echo "Installed icuuc.dll (+ ICU $ICU) and the mscms stub in $SYSTEM32"

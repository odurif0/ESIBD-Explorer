#!/bin/bash
# Windows installer of the built Explorer: compile installer.iss with Inno Setup 6 under Wine, then test it
# in the build prefix: replace a stand-in earlier installation, install silently, start the installed
# Explorer (smoke.sh), uninstall. The setup is added to SHA256SUMS.  Run after package.sh.
# Usage: installer.sh VERSION   (e.g. 1.0.2+od.7)
set -euo pipefail
source "$(dirname "$0")/env.sh"
VERSION=$1
OUT=$ESIBD_BUILD_DIR/release-$VERSION
SETUP=ESIBD-Explorer-$VERSION-setup.exe
ISCC=${ISCC:-'C:\InnoSetup6\ISCC.exe'}
LOG=$ESIBD_BUILD_DIR/installer.log
[[ $VERSION =~ ^([0-9]+\.[0-9]+\.[0-9]+)(\+od\.([0-9]+))?$ ]] || { echo "VERSION like 1.0.2+od.7 expected" >&2; exit 1; }
NUMERIC=${BASH_REMATCH[1]}.${BASH_REMATCH[3]:-0}
[ -f "$OUT/SHA256SUMS" ] || { echo "Run package.sh $VERSION first" >&2; exit 1; }
grep -q "^esibd-explorer==$VERSION " "$OUT/requirements-windows.txt" || { echo "The release folder is not $VERSION" >&2; exit 1; }

# The license and icon come from the exported sources the dist was built from.
wine "$ISCC" /Q "/DAppVersion=$VERSION" "/DNumericVersion=$NUMERIC" "/DDist=$(winpath "$DIST")" \
    "/DRepo=$(winpath "$SRC")" "/DOutputDir=$(winpath "$OUT")" "$(winpath "$TOOLS/installer.iss")" > "$LOG" 2>&1 \
    || { tr -d '\r' < "$LOG" >&2; echo "Inno Setup failed" >&2; exit 1; }
echo "Built $SETUP ($(du -m "$OUT/$SETUP" | cut -f1) MB)."

APP='C:\Program Files\ESIBD Lab\ESIBD Explorer'
APPDIR="$WINEPREFIX/drive_c/Program Files/ESIBD Lab/ESIBD Explorer"
[ -e "$APPDIR" ] && { echo "$APPDIR exists: a test installation was left behind, remove it first" >&2; exit 1; }
# A stand-in for 1.0.2 installed by InstallForge (32-bit uninstall entry): its "uninstaller" removes the entry.
EARLIER='HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\ESIBD Explorer'
wine reg add "$EARLIER" /reg:32 /v DisplayName /d 'ESIBD Explorer' /f > /dev/null 2>&1
wine reg add "$EARLIER" /reg:32 /v UninstallString /d "C:\\windows\\system32\\reg.exe delete \"$EARLIER\" /reg:32 /f" /f > /dev/null 2>&1

wine "$(winpath "$OUT/$SETUP")" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART "/LOG=$(winpath "$ESIBD_BUILD_DIR/installer_install.log")" > /dev/null 2>&1
wineserver -w
if wine reg query "$EARLIER" /reg:32 > /dev/null 2>&1; then
    echo "The setup did not uninstall the earlier installation" >&2; exit 1
fi
diff <(cd "$DIST" && find . -type f | sort) <(cd "$APPDIR" && find . -type f ! -name 'unins000.*' | sort) > /dev/null \
    || { echo "The installed files differ from the dist" >&2; exit 1; }
echo "Installed in $APP, replacing the earlier installation; same files as the dist."

"$TOOLS/smoke.sh" "$APPDIR"

wine "$APP\\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART > /dev/null 2>&1
wineserver -w
if [ -e "$APPDIR" ] || wine reg query 'HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\{CA73038C-FC31-45C1-9CDE-EAD2AF4DF42E}_is1' > /dev/null 2>&1; then
    echo "The uninstaller left the program folder or its entry" >&2; exit 1
fi
echo "Uninstalled: program folder and uninstall entry removed."

(cd "$OUT" && sha256sum "ESIBD-Explorer-$VERSION-win64.zip" requirements-windows.txt "$SETUP" > SHA256SUMS && cat SHA256SUMS)

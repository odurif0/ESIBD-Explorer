# Shared settings of the Windows build under Wine; sourced by the other scripts.
# Override any of them in the environment.
export ESIBD_BUILD_DIR=${ESIBD_BUILD_DIR:-$HOME/.cache/esibd-build}        # sources, logs and release files
export WINEPREFIX=${WINEPREFIX:-$HOME/.wine-esibd-build-314}               # Wine prefix with Windows CPython
export WINEARCH=win64 WINEDEBUG=${WINEDEBUG:--all}
export PY=${PY:-'C:\Python314\python.exe'}                                 # the Windows Python in that prefix
export DISPLAY=${ESIBD_BUILD_DISPLAY:-:97}                                 # an Xvfb display, never the user's
unset WAYLAND_DISPLAY
TOOLS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$TOOLS/../.." && pwd)
SRC=$ESIBD_BUILD_DIR/src
DIST="$SRC/pyinstaller_dist/ESIBD Explorer"
# Windows path of a Linux path (Wine maps / to Z:)
winpath() { printf 'Z:%s' "$(realpath -m "$1" | tr / '\\')"; }
mkdir -p "$ESIBD_BUILD_DIR"

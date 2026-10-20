# source me: macOS environment for the 3ds Max wine prefix (patched Wine 11.0 + DXMT)
export REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
export WINEROOT="$HOME/opt/wine-11.0-patched/Wine Stable.app/Contents/Resources/wine"
export PATH="$WINEROOT/bin:$PATH"
export WINEPREFIX="$HOME/.wine-3dsmax"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all,err+all}"
export MAXSRC="${MAXSRC:-$HOME/Desktop/3dsmax}"
export LOGS="$REPO/logs"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winemenubuilder.exe=d"
mkdir -p "$LOGS"

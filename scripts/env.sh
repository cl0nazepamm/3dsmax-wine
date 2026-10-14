# source me: environment for the 3ds Max wine prefix
export WINEPREFIX="$HOME/.wine-3dsmax"
export WINEROOT="$HOME/opt/wine-11.0-patched/usr/lib/wine-vanilla-11.0"
export PATH="$WINEROOT/bin:$PATH"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all,err+all}"
export MAXSRC="$HOME/3dsmax-setup"
export LOGS="$HOME/3dsmax-wine/logs"
# the MSI's per-language Start Menu shortcuts would be turned into desktop entries that use the
# unpatched system wine; we ship a single launcher instead (scripts/install-launcher.sh)
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winemenubuilder.exe=d"

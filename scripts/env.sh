# source me: environment for the 3ds Max wine prefix
export WINEPREFIX="$HOME/.wine-3dsmax"
export WINEROOT="$HOME/opt/wine-11.0-patched/usr/lib/wine-vanilla-11.0"
export PATH="$WINEROOT/bin:$PATH"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all,err+all}"
export MAXSRC="$HOME/3dsmax-setup"
export LOGS="$HOME/3dsmax-wine/logs"

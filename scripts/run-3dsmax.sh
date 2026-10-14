#!/bin/bash
# launch 3ds Max with a timestamped log in logs/; extra args go to 3dsmax.exe
# WINEDEBUG can be overridden, e.g. WINEDEBUG=+loaddll,+seh scripts/run-3dsmax.sh
source "$HOME/3dsmax-wine/scripts/env.sh"
export DXVK_LOG_PATH="$LOGS" DXVK_LOG_LEVEL="${DXVK_LOG_LEVEL:-info}"
log="$LOGS/run-$(date +%Y%m%d-%H%M%S).log"
echo "logging to $log"
cd "$WINEPREFIX/drive_c/Program Files/Autodesk/3ds Max 2027"
wine ./3dsmax.exe "$@" > "$log" 2>&1
echo "exit $?" | tee -a "$log"

#!/bin/bash
# launch 3ds Max 2027 on the patched wine, with a timestamped log in logs/
#   run-3dsmax.sh [file.max]       (linux paths are converted for 3dsmax.exe)
# WINEDEBUG can be overridden, e.g. WINEDEBUG=+loaddll,+seh scripts/run-3dsmax.sh
source "$HOME/3dsmax-wine/scripts/env.sh"
export DXVK_LOG_PATH="$LOGS" DXVK_LOG_LEVEL="${DXVK_LOG_LEVEL:-info}"
log="$LOGS/run-$(date +%Y%m%d-%H%M%S).log"
args=()
for a in "$@"; do
    [ -e "$a" ] && a=$(winepath -w "$(realpath "$a")" 2>/dev/null)
    args+=("$a")
done
echo "logging to $log"
cd "$WINEPREFIX/drive_c/Program Files/Autodesk/3ds Max 2027"
wine ./3dsmax.exe "${args[@]}" > "$log" 2>&1
echo "exit $?" | tee -a "$log"

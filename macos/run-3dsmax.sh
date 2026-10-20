#!/bin/bash
# launch 3ds Max 2027 on the patched wine with DXMT, with a timestamped log in logs/
#   run-3dsmax.sh [file.max]       (unix paths are converted for 3dsmax.exe)
# WINEDEBUG and DXMT_LOG_LEVEL can be overridden, e.g. WINEDEBUG=+loaddll,+seh macos/run-3dsmax.sh
source "$(dirname "$0")/env.sh"
export DXMT_LOG_PATH="Z:$LOGS" DXMT_LOG_LEVEL="${DXMT_LOG_LEVEL:-info}" DXMT_CONFIG_FILE="Z:$REPO/macos/dxmt.conf"
log="$LOGS/run-$(date +%Y%m%d-%H%M%S).log"
args=()
for a in "$@"; do
    [ -e "$a" ] && a=$(winepath -w "$(realpath "$a")" 2>/dev/null)
    args+=("$a")
done
ini="$WINEPREFIX/drive_c/users/$USER/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini"
[ -f "$ini" ] && python3 -I "$REPO/macos/set-d3d11.py" "$ini"
echo "logging to $log"
cd "$WINEPREFIX/drive_c/Program Files/Autodesk/3ds Max 2027"
wine ./3dsmax.exe "${args[@]}" > "$log" 2>&1
echo "exit $?" | tee -a "$log"

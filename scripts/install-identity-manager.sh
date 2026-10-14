#!/bin/bash
# Autodesk Identity Manager (sign-in component). It isn't on the 3ds Max media; Autodesk publishes
# the installer on its CDN. Its bootstrapper needs ODIS installed, else it hangs (error 3051).
set -e
source "$HOME/3dsmax-wine/scripts/env.sh"
D="$HOME/3dsmax-wine/downloads/idmgr-1.12.0.7"
mkdir -p "$D"
[ -f "$D/AdskIdentityManager-UCT-Installer.exe" ] ||
    curl -fL -o "$D/AdskIdentityManager-UCT-Installer.exe" \
        'https://up1.autodesk.com/IDSDK/Windows/1.12.0.7/AdskIdentityManager-UCT-Installer.exe'
wine "$HOME/3dsmax-wine/tools/sigcheck.exe" "$(winepath -w "$D/AdskIdentityManager-UCT-Installer.exe")"
wine "$(winepath -w "$MAXSRC/ODIS/AdODIS-installer.exe")" --mode unattended --unattendedmodeui none
wine "$(winepath -w "$D/AdskIdentityManager-UCT-Installer.exe")" -q
"$HOME/3dsmax-wine/scripts/install-url-handler.sh"

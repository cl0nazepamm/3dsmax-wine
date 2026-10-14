#!/bin/bash
# Autodesk Identity Manager (sign-in component). It isn't on the 3ds Max media; Autodesk publishes
# the installer on its CDN. Its bootstrapper needs ODIS installed, else it hangs (error 3051).
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
D="$REPO/downloads/idmgr-1.12.0.7"
url='https://up1.autodesk.com/IDSDK/Windows/1.12.0.7/AdskIdentityManager-UCT-Installer.exe'
[ -f "$MAXSRC/ODIS/AdODIS-installer.exe" ] || { echo "$MAXSRC/ODIS/AdODIS-installer.exe not found: set MAXSRC to the unpacked 3ds Max 2027 media" >&2; exit 1; }
mkdir -p "$D"
if [ ! -f "$D/AdskIdentityManager-UCT-Installer.exe" ]; then  # .part first, so a broken download isn't kept
    curl -fL -o "$D/AdskIdentityManager-UCT-Installer.exe.part" "$url" ||
        { echo "download failed: $url (if Autodesk retired 1.12.0.7, put an Identity Manager installer at $D/AdskIdentityManager-UCT-Installer.exe)" >&2; exit 1; }
    mv "$D/AdskIdentityManager-UCT-Installer.exe.part" "$D/AdskIdentityManager-UCT-Installer.exe"
fi
[ -f "$REPO/tools/sigcheck.exe" ] || make -C "$REPO/tools" sigcheck.exe
wine "$REPO/tools/sigcheck.exe" "$(winepath -w "$D/AdskIdentityManager-UCT-Installer.exe")"
wine "$(winepath -w "$MAXSRC/ODIS/AdODIS-installer.exe")" --mode unattended --unattendedmodeui none
wine "$(winepath -w "$D/AdskIdentityManager-UCT-Installer.exe")" -q
"$REPO/scripts/install-url-handler.sh"

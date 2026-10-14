#!/bin/bash
# Autodesk Desktop Licensing (AdskLicensingService). Needs patch 0003, otherwise the
# service start times out with error 1053 and the installer exits 69009748.
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
[ -f "$MAXSRC/x86/Licensing/AdskLicensing-installer.exe" ] || { echo "$MAXSRC/x86/Licensing/AdskLicensing-installer.exe not found: set MAXSRC to the unpacked 3ds Max 2027 media" >&2; exit 1; }
wine "$MAXSRC/x86/Licensing/AdskLicensing-installer.exe" --mode unattended --unattendedmodeui none
grep -E 'Exiting with code' "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Temp/AdskLicensing-install.log" | tail -1
wine sc query AdskLicensingService | grep STATE

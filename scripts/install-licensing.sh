#!/bin/bash
# Autodesk Desktop Licensing (AdskLicensingService). Needs patch 0003, otherwise the
# service start times out with error 1053 and the installer exits 69009748.
set -e
source "$HOME/3dsmax-wine/scripts/env.sh"
wine "$MAXSRC/x86/Licensing/AdskLicensing-installer.exe" --mode unattended --unattendedmodeui none
grep -E 'Exiting with code' "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Temp/AdskLicensing-install.log" | tail -1
wine sc query AdskLicensingService | grep STATE

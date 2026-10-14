#!/bin/bash
# Create the prefix and install the runtimes 3ds Max 2027 depends on, straight from the
# installer media's 3rdParty folder (what ODIS would do, minus ODIS).
set -e
source "$HOME/3dsmax-wine/scripts/env.sh"
R="$MAXSRC/3rdParty"
w() { echo ">> $*"; wine "$@" || echo "   (exit $?)"; }

[ -f "$WINEPREFIX/system.reg" ] || wineboot -i
winetricks -q win10 dxvk

w "$R/x64/VCRedist/2022/VC_redist.x64.exe" /install /quiet /norestart
w "$R/x86/VCRedist/2022/VC_redist.x86.exe" /install /quiet /norestart
w "$R/x64/dotNet/80/windowsdesktop-runtime-8.0.11-win-x64.exe" /install /quiet /norestart
w "$R/x64/aspNetCore/80/aspnetcore-runtime-8.0.11-win-x64.exe" /install /quiet /norestart
w "$R/x64/dotNet/100/windowsdesktop-runtime-10.0.0-win-x64.exe" /install /quiet /norestart
w "$R/x64/aspNetCore/100/aspnetcore-runtime-10.0.0-win-x64.exe" /install /quiet /norestart
w "$R/x64/WebView2/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" /silent /install

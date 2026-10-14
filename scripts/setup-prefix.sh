#!/bin/bash
# Create the prefix and install the runtimes 3ds Max 2027 depends on, straight from the
# installer media's 3rdParty folder (what ODIS would do, minus ODIS).
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
R="$MAXSRC/3rdParty"
w() { echo ">> $*"; wine "$@" || echo "   (exit $?)"; }
# media <dir> <glob>: the .NET installer names carry patch versions (8.0.11, 10.0.0) that differ between media builds
media() { local m=("$R/$1"/$2); [ -f "${m[0]}" ] || { echo "no $2 in $R/$1: set MAXSRC to the unpacked 3ds Max 2027 media" >&2; return 1; }; echo "${m[0]}"; }
vc64=$(media x64/VCRedist/2022 VC_redist.x64.exe)
vc86=$(media x86/VCRedist/2022 VC_redist.x86.exe)
desktop8=$(media x64/dotNet/80 'windowsdesktop-runtime-*-win-x64.exe')
asp8=$(media x64/aspNetCore/80 'aspnetcore-runtime-*-win-x64.exe')
desktop10=$(media x64/dotNet/100 'windowsdesktop-runtime-*-win-x64.exe')
asp10=$(media x64/aspNetCore/100 'aspnetcore-runtime-*-win-x64.exe')
webview2=$(media x64/WebView2 MicrosoftEdgeWebView2RuntimeInstallerX64.exe)

[ -f "$WINEPREFIX/system.reg" ] || wineboot -i
winetricks -q win10 dxvk

w "$vc64" /install /quiet /norestart
w "$vc86" /install /quiet /norestart
w "$desktop8" /install /quiet /norestart
w "$asp8" /install /quiet /norestart
w "$desktop10" /install /quiet /norestart
w "$asp10" /install /quiet /norestart
w "$webview2" /silent /install

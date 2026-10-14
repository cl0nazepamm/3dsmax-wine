#!/bin/bash
# register adsk-url-handler.sh as the desktop handler for Identity Manager's callback schemes
set -e
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"
cat > "$APPS/wine-3dsmax-adskidmgr.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Autodesk Identity Manager (Wine 3ds Max prefix)
Exec=$HOME/3dsmax-wine/scripts/adsk-url-handler.sh %u
MimeType=x-scheme-handler/adskidmgr;x-scheme-handler/adsk.idmgr;
NoDisplay=true
Terminal=false
DESKTOP
xdg-mime default wine-3dsmax-adskidmgr.desktop x-scheme-handler/adskidmgr
xdg-mime default wine-3dsmax-adskidmgr.desktop x-scheme-handler/adsk.idmgr
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true
echo "adskidmgr -> $(xdg-mime query default x-scheme-handler/adskidmgr)"
echo "adsk.idmgr -> $(xdg-mime query default x-scheme-handler/adsk.idmgr)"

#!/bin/bash
# one desktop launcher for 3ds Max 2027 on the patched wine; removes the installer's per-language
# shortcuts (they use the unpatched system wine and all claim the 3dsmax.exe window class)
set -e
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor"

for d in "$ICONS"/*/apps; do
    [ -f "$d/9EE1_3dsmax.0.png" ] && cp "$d/9EE1_3dsmax.0.png" "$d/3dsmax-2027-wine.png"
done

cat > "$APPS/3dsmax-2027-wine.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=3ds Max 2027
GenericName=3D Modeling and Animation
Comment=Autodesk 3ds Max 2027 (patched Wine, ~/3dsmax-wine)
Exec=$HOME/3dsmax-wine/scripts/run-3dsmax.sh %f
Icon=3dsmax-2027-wine
Terminal=false
StartupNotify=true
StartupWMClass=3dsmax.exe
MimeType=application/x-wine-extension-max;
Categories=Graphics;3DGraphics;
DESKTOP

rm -rf "$APPS/wine/Programs/Autodesk/Autodesk 3ds Max 2027" "$APPS/wine/Programs/Autodesk/Autodesk Access"
rm -f "$APPS/wine-extension-max.desktop"
rmdir "$APPS/wine/Programs/Autodesk" "$APPS/wine/Programs" "$APPS/wine" 2>/dev/null || true

xdg-mime default 3dsmax-2027-wine.desktop application/x-wine-extension-max
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t "$ICONS" 2>/dev/null || true
source "$HOME/3dsmax-wine/scripts/env.sh"
wine regedit 'Z:\home\clone\3dsmax-wine\scripts\desktop-integration.reg'
echo "installed $APPS/3dsmax-2027-wine.desktop"

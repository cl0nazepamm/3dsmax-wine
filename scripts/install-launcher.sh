#!/bin/bash
# one desktop launcher for 3ds Max 2027 on the patched wine; removes the installer's per-language
# shortcuts (they use the unpatched system wine and all claim the 3dsmax.exe window class)
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor"
MIME="$HOME/.local/share/mime"
EXE="$WINEPREFIX/drive_c/Program Files/Autodesk/3ds Max 2027/3dsmax.exe"
[ -f "$EXE" ] || { echo "$EXE not found: run install-max-msi.sh first" >&2; exit 1; }
mkdir -p "$APPS" "$MIME/packages"

# the icon and the .max type are what winemenubuilder would have made, but env.sh keeps it disabled
python3 -I "$REPO/scripts/extract-icons.py" "$EXE" "$ICONS" 3dsmax-2027-wine
cat > "$MIME/packages/x-wine-extension-max.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-wine-extension-max">
    <glob pattern="*.max"/>
    <comment>3dsMax scene file</comment>
  </mime-type>
</mime-info>
XML
update-mime-database "$MIME"

cat > "$APPS/3dsmax-2027-wine.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=3ds Max 2027
GenericName=3D Modeling and Animation
Comment=Autodesk 3ds Max 2027 (patched Wine, $REPO)
Exec="$REPO/scripts/run-3dsmax.sh" %f
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
echo "installed $APPS/3dsmax-2027-wine.desktop"

#!/bin/bash
# register an applet as the macOS handler for Identity Manager's callback schemes
set -e
source "$(dirname "$0")/env.sh"
APP="$HOME/Applications/3ds Max Wine Sign-in.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
mkdir -p "$HOME/Applications"
rm -rf "$APP"
osacompile -o "$APP" -e "on open location theURL
	do shell script quoted form of \"$REPO/macos/adsk-url-handler.sh\" & \" \" & quoted form of theURL & \" > /dev/null 2>&1 &\"
end open location"
P="$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string local.3dsmax-wine.signin" \
    -c "Add :LSUIElement bool true" \
    -c "Add :CFBundleURLTypes array" \
    -c "Add :CFBundleURLTypes:0 dict" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLName string Autodesk Identity Manager (Wine 3ds Max prefix)" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string adskidmgr" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string adsk.idmgr" "$P"
codesign --force --sign - "$APP"
"$LSREGISTER" -f "$APP"
for s in adskidmgr adsk.idmgr; do
    echo "$s -> $(osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL(\$.NSURL.URLWithString('$s://check')).path.js")"
done

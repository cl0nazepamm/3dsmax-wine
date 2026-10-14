#!/bin/bash
# Linux handler for Autodesk Identity Manager's sign-in callback (adskidmgr:// / adsk.idmgr://).
# The browser hands us the callback link; pass it to AdskIdentityManager.exe inside the prefix, exactly
# like Windows does via HKCU\Software\Classes\adskidmgr\shell\open\command.
source "$(dirname "$(readlink -f "$0")")/env.sh"
url="$1"
mkdir -p "$LOGS"
echo "$(date '+%F %T') forwarding ${url%%\?*}?<redacted>" >> "$LOGS/url-handler.log"
exec wine 'C:\Program Files\Autodesk\AdskIdentityManager\Current\AdskIdentityManager.exe' "$url" >> "$LOGS/url-handler.log" 2>&1

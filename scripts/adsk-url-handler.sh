#!/bin/bash
# Linux handler for Autodesk Identity Manager's sign-in callback (adskidmgr:// / adsk.idmgr://).
# The browser hands us the callback link; pass it to AdskIdentityManager.exe inside the prefix, exactly
# like Windows does via HKCU\Software\Classes\adskidmgr\shell\open\command.
source "$HOME/3dsmax-wine/scripts/env.sh"
url="$1"
echo "$(date '+%F %T') forwarding ${url%%\?*}?<redacted>" >> "$LOGS/url-handler.log"
exec wine 'C:\Program Files\Autodesk\AdskIdentityManager\Current\AdskIdentityManager.exe' "$url" >> "$LOGS/url-handler.log" 2>&1

#!/bin/bash
# macOS handler for Autodesk Identity Manager's sign-in callback (adskidmgr:// / adsk.idmgr://).
# The browser opens the callback link, LaunchServices hands it to the applet made by
# install-url-handler.sh, and the applet runs this; pass it to AdskIdentityManager.exe in the prefix.
source "$(dirname "$0")/env.sh"
url="$1"
echo "$(date '+%F %T') forwarding ${url%%\?*}?<redacted>" >> "$LOGS/url-handler.log"
exec wine 'C:\Program Files\Autodesk\AdskIdentityManager\Current\AdskIdentityManager.exe' "$url" >> "$LOGS/url-handler.log" 2>&1

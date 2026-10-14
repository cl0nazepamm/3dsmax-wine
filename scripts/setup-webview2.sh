#!/bin/bash
# WebView2 under wine: no Chromium sandbox, no DirectComposition presentation, and wine's own
# dxgi/d3d11 for msedgewebview2.exe (DXVK has no CreateSwapChainForComposition)
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
wine reg add 'HKCU\Environment' /v WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS /t REG_SZ /d '--no-sandbox --disable-direct-composition' /f
wine regedit "$(winepath -w "$REPO/scripts/webview2-overrides.reg")"
wineserver -w

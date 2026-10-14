#!/bin/bash
# WebView2 under wine: no Chromium sandbox, no DirectComposition presentation, and wine's own
# dxgi/d3d11 for msedgewebview2.exe (DXVK has no CreateSwapChainForComposition)
set -e
source "$HOME/3dsmax-wine/scripts/env.sh"
wine reg add 'HKCU\Environment' /v WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS /t REG_SZ /d '--no-sandbox --disable-direct-composition' /f
wine regedit 'Z:\home\clone\3dsmax-wine\scripts\webview2-overrides.reg'
wineserver -w

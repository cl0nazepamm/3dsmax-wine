#!/bin/bash
# preset named-user (Autodesk account) licensing so the WebView2 license-type page is skipped;
# sign-in then happens in the system browser (Identity Manager -> winebrowser -> xdg-open)
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
H='C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\helper\AdskLicensingInstHelper.exe'
wine "$H" change --pk 128S1 --pv 2027.0.0.F --lm USER --fi 3DSMAX

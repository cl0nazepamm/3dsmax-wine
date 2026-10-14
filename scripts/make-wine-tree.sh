#!/bin/bash
# Create the private wine runtime: a copy of Gentoo's wine-vanilla-11.0 that our patched
# modules get layered onto (the system install is never touched).
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
SYS=/usr/lib/wine-vanilla-11.0
if [ -d "$WINEROOT" ]; then echo "$WINEROOT already exists"; exit 0; fi
mkdir -p "$(dirname "$WINEROOT")"
cp -a "$SYS" "$WINEROOT"
echo "created $WINEROOT"

#!/bin/bash
# deploy rebuilt wine modules from build64 into the patched wine tree
# usage: deploy.sh dlls/ntdll/ntdll.so dlls/wintrust/x86_64-windows/wintrust.dll ...
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
B="$WINESRC/build64"
for f in "$@"; do
    base=$(basename "$f")
    case "$f" in
        server/wineserver) dst="$WINEROOT/bin/wineserver" ;;
        *.so) dst="$WINEROOT/wine/x86_64-unix/$base" ;;
        */x86_64-windows/*) dst="$WINEROOT/wine/x86_64-windows/$base" ;;
        */i386-windows/*) dst="$WINEROOT/wine/i386-windows/$base" ;;
        *) echo "don't know where $f goes"; exit 1 ;;
    esac
    [ -e "$dst.orig" ] || cp -a "$dst" "$dst.orig"
    install -m755 "$B/$f" "$dst"
    echo "deployed $f -> $dst"
done

#!/bin/bash
# global GNOME tweak (optional): slimmer title bars on X11/XWayland windows, then restart the frame helper
set -e
CSS="$HOME/.config/gtk-4.0/gtk.css"
SRC="$(dirname "$(readlink -f "$0")")/gtk4-slim-titlebars.css"
mkdir -p "$(dirname "$CSS")"
if ! grep -q 'mutter-x11-frames' "$CSS" 2>/dev/null; then
    { [ -s "$CSS" ] && echo; cat "$SRC"; } >> "$CSS"
fi
# restart the frame helper so it loads the CSS. NOT with SIGTERM/SIGKILL: mutter only respawns it after
# other signals (meta-x11-display.c: on_frames_client_died); start it by hand if it still isn't back
pkill -INT -f '^/usr/libexec/mutter-x11-frame[s]' || true
sleep 2
pgrep -f '^/usr/libexec/mutter-x11-frame[s]' >/dev/null ||
    DISPLAY="${DISPLAY:-:0}" setsid -f /usr/libexec/mutter-x11-frames >/dev/null 2>&1 < /dev/null

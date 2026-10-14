#!/bin/bash
# install the core 3ds Max 2027 MSI directly (skipping ODIS)
source "$(dirname "$(readlink -f "$0")")/env.sh"
msi="$MAXSRC/x64/3dsmax/3dsMax.msi"
[ -f "$msi" ] || { echo "$msi not found: set MAXSRC to the unpacked 3ds Max 2027 media" >&2; exit 1; }
export MAXMSI="$(winepath -w "$msi")"  # wine copies the unix environment, so the .bat sees %MAXMSI%
cd "$MAXSRC/x64/3dsmax"
exec wine cmd /c "$(winepath -w "$REPO/scripts/install-max-msi.bat")"

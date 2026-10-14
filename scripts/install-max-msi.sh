#!/bin/bash
# install the core 3ds Max 2027 MSI directly (skipping ODIS)
source "$HOME/3dsmax-wine/scripts/env.sh"
cd "$MAXSRC/x64/3dsmax"
exec wine cmd /c 'Z:\home\clone\3dsmax-wine\scripts\install-max-msi.bat'

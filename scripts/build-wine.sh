#!/bin/bash
# Apply patches/wine-11.0/*.patch to a wine-11.0 checkout, build the patched modules and deploy them.
#   WINESRC  wine source checkout (default ~/src/wine-11.0, cloned from gitlab.winehq.org if missing)
# Needs flex, bison and mingw64-toolchain (USE=mingw on wine-vanilla pulls them in, but depclean drops them).
# The build dir is configured with Gentoo's install paths on purpose: ntdll.so bakes in absolute
# BINDIR/DATADIR, and with the default /usr/local prefix it can't find l_intl.nls and segfaults.
set -e
source "$(dirname "$(readlink -f "$0")")/env.sh"
P=/usr/lib/wine-vanilla-11.0
D=/usr/share/wine-vanilla-11.0

if [ ! -d "$WINESRC/.git" ]; then
    git clone --branch wine-11.0 --depth 1 https://gitlab.winehq.org/wine/wine.git "$WINESRC"
fi
cd "$WINESRC"
# git am records a committer; don't fail on machines without a git identity
git config user.email >/dev/null || export GIT_COMMITTER_NAME=3dsmax-wine GIT_COMMITTER_EMAIL=3dsmax-wine@localhost
if ! git rev-parse -q --verify 3dsmax >/dev/null; then  # applies everything in patches/wine-11.0, incl. the staging dcomp backport
    git checkout -b 3dsmax wine-11.0
    git am "$REPO"/patches/wine-11.0/*.patch
else
    # pick up patches added to the repo since the branch was created
    for p in "$REPO"/patches/wine-11.0/*.patch; do
        subj=$(sed -n 's/^Subject: \[PATCH[^]]*\] //p' "$p" | head -1)
        git log --format=%s wine-11.0..3dsmax | grep -qxF "$subj" || git am "$p"
    done
fi

mkdir -p build64 && cd build64
if [ ! -f Makefile ]; then
    ../configure --prefix=$P --libdir=$P --datadir=$D --includedir=/usr/include/wine-vanilla-11.0 \
        --mandir=$D/man --enable-archs=x86_64 \
        --without-x --without-freetype --without-wayland --without-gstreamer --without-vulkan --without-opengl
fi
mods=$(grep -v '^#' "$REPO/scripts/patched-modules.txt")
make -j"$(nproc)" $mods
"$REPO/scripts/deploy.sh" $mods

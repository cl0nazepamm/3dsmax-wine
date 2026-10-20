# 3ds Max 2027 on macOS (Apple Silicon): work in progress

Same approach as the Linux setup: Wine 11.0 with this repo's patch series, layered onto a private Wine copy. Direct3D 11 goes to Metal through [DXMT](https://github.com/3Shain/dxmt) instead of DXVK.

**Status (2026-10-19, Apple M4, macOS 27.0.1):**

- **Works:** install, licensing, sign-in and the UI.
- **Viewport:** renders the grid and wireframes. Shaded objects are black. A box isn't drawn, and drawing one interactively hangs the GPU.
- **Cause:** Nitrous does mesh preprocessing with geometry-shader stream output, which DXMT doesn't implement yet.

The investigation and the plan are in [docs/JOURNAL.md](../docs/JOURNAL.md#2026-10-19-macos-apple-silicon-with-dxmt).

## Layout

```
macos/env.sh                     source me: WINEROOT, WINEPREFIX (~/.wine-3dsmax), MAXSRC (~/Desktop/3dsmax), LOGS
macos/run-3dsmax.sh              launch with DXMT logging + dxmt.conf, pins Nitrous to Direct3D 11.0 first
macos/set-d3d11.py               3dsMax.ini: GFXDirect3DVersion=11.0 (3ds Max writes WARP back after a failed init)
macos/dxmt.conf                  report an AMD adapter; Nitrous treats DXMT's Apple adapter as "no GPU"
macos/install-url-handler.sh     ~/Applications/3ds Max Wine Sign-in.app for adskidmgr:// and adsk.idmgr://
macos/adsk-url-handler.sh        what that applet runs: forwards the callback to AdskIdentityManager.exe
macos/patches/0075-*.patch       winemac.drv: macdrv_functions export for DXMT (applies on top of patches/wine-11.0)
macos/patches/dxmt/0001-*.patch  DXMT: vertex stream output to all four SO slots
macos/patches/dxmt/0002-*.patch  DXMT: DEBUG tracing of stream output use + DXMT_SO_DUMP (not for upstream)
macos/tests/*.ms                 viewport repros, run with 3dsmax.exe -U MAXScript <file>
tools/dxbcdis.c                  DXBC disassembler on wine's vkd3d-shader (make -C tools dxbcdis.exe)
```

## Setup as done on 2026-10-19

The paths below are the ones used. Nothing here is scripted end to end yet.

1. **Toolchain**
   ```sh
   softwareupdate --install-rosetta --agree-to-license
   brew install bison mingw-w64 meson ninja
   xcodebuild -downloadComponent MetalToolchain
   ```
2. **Wine runtime:** `wine-stable-11.0_1-osx64.tar.xz` from [Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds/releases/tag/11.0_1), unpacked to `~/opt/wine-11.0-patched/`.
   - Homebrew's `wine-stable` cask has been disabled since 2026-09-01 (Gatekeeper).
   - GStreamer.framework is not installed.
3. **Patched Wine modules**
   - Source: `~/src/wine-11.0`, branch `3dsmax` = `wine-11.0` + `patches/wine-11.0/*` + `macos/patches/0075-*`.
   - Configure in `build64` under Rosetta. Xcode's clang is arm64-only and targets arm64 even under `arch -x86_64`, so pass `-arch` explicitly:
     ```sh
     arch -x86_64 zsh -c 'PATH=/opt/homebrew/opt/bison/bin:/opt/homebrew/bin:$PATH ../configure \
         CC="clang -arch x86_64" OBJC="clang -arch x86_64" CXX="clang++ -arch x86_64" \
         --prefix=/opt/wine --enable-archs=i386,x86_64 --disable-tests --without-x --without-wayland \
         --without-gstreamer --without-sdl --without-cups --without-sane --without-krb5 --without-gssapi \
         --without-netapi --without-capi --without-pcap --without-usb --without-v4l2 --without-inotify \
         --without-freetype --without-gnutls'
     ```
     There are no x86_64 FreeType/GnuTLS libraries, and none of the modules we deploy need them.
   - Build and copy into `Wine Stable.app/Contents/Resources/wine/lib/wine/{x86_64-unix,x86_64-windows}`. The originals are kept as `*.orig`.
     - Unix side: `ntdll.so`, `winemac.so`.
     - Windows side: `ntdll.dll`, `wintrust.dll`, `kernelbase.dll`, `dcomp.dll`.
   - Not deployed:
     - `dxgi.dll`: DXMT replaces it.
     - `wineserver` (patch 0074): the bundled one links libinotify, and the white-flash fix it carries is X11-specific.
4. **DXMT:** `main` at `50102f9` plus `macos/patches/dxmt/*`, cloned to `downloads/dxmt-main` (gitignored).
   - Prerequisites:
     - Prebuilt LLVM 15.0.7 for x86_64 (`clang+llvm-15.0.7-x86_64-apple-darwin21.0` from the LLVM release) in `~/src/toolchains/llvm-15-x86_64`.
     - Move its `libc++*`, `libc++abi*` and `libunwind*` (`.a` and `.dylib`) out of `lib/`. Otherwise `winemetal.so` links `@rpath/libc++.1.dylib`, fails to load, and every process dies with c0000142.
     - Build the import libraries DXMT links against, in the Wine tree: `make dlls/dbghelp/x86_64-windows/libdbghelp.a dlls/winecrt0/x86_64-windows/libwinecrt0.a`.
   - Configure and build:
     ```sh
     # native-x86_64.txt: [binaries] c/cpp/objc/objcpp = clang(++) -arch x86_64
     arch -x86_64 zsh -c 'meson setup --cross-file build-win64.txt --native-file native-x86_64.txt \
         -Dnative_llvm_path=$HOME/src/toolchains/llvm-15-x86_64 -Dwine_build_path=$HOME/src/wine-11.0/build64 \
         --buildtype release build && meson compile -C build'
     ```
   - Install as Wine builtins:
     - `winemetal.so` goes to `x86_64-unix/`.
     - `winemetal.dll`, `d3d11.dll`, `dxgi.dll` and `d3d10core.dll` go to `x86_64-windows/`.
     - `winemetal.dll` also goes to the prefix's `system32`.
   - The DXMT v0.80 release and the CI build of `50102f9` (both under `downloads/`, gitignored) hang the same way.
5. **Prefix:** `macos/env.sh` and the same steps as the Linux scripts:
   - `wineboot -i` and `winecfg /v win10`.
   - Runtimes from `3rdParty/` (VC++ 2022 x64/x86, .NET 8.0.11 and 10.0.0 desktop + ASP.NET, WebView2).
   - AdskLicensing, then `3dsMax.msi` through `scripts/install-max-msi.bat`.
   - ODIS + Identity Manager 1.12.0.7.
   - `AdskLicensingInstHelper change ... --lm USER`.
   - `scripts/set-privacy-consent.sh`, which works on macOS unchanged.
   - Every installer passed `tools/sigcheck.exe`.
   - WebView2 gets `--no-sandbox --disable-direct-composition --disable-gpu`. DXMT's dxgi has no `CreateSwapChainForComposition`, and the per-app builtin override doesn't help because DXMT *is* the builtin dxgi.
   - The MSI puts a `3ds Max 2027.lnk` on `~/Desktop`, because the prefix's Desktop is a symlink to it. Delete it.
6. **Sign-in:** run `macos/install-url-handler.sh`, then launch with `macos/run-3dsmax.sh`. Log in in the browser and allow the `adskidmgr:` link.

## Debugging

- **Logs:**
  - DXMT writes `logs/3dsmax_d3d11.log`. It's buffered and loses its tail when the process is killed; the same lines are also in the run log.
  - `DXMT_LOG_LEVEL=debug` gives more detail.
  - `MTL_SHADER_VALIDATION=1` turns on Metal's shader validation layer.
- **Shader dumps:** `DXMT_SO_DUMP=Z:/path/dir` (debug patch) dumps stream-output shaders and shaders created with a class linkage. Disassemble them with `wine tools/dxbcdis.exe file.dxbc`.
- **Repros:** `3dsmax.exe -U MAXScript macos/tests/objects.ms` runs a repro without input. MAXScript `format` goes to the Listener, not to stdout.
- **Nitrous's own view:** `%LOCALAPPDATA%\Autodesk\3dsMax\2027 - 64bit\ENU\Network\Max.log` records which graphics device it actually created, and why it fell back.

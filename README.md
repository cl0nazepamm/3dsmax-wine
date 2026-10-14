# 3ds Max 2027 on Linux (Wine)

Getting Autodesk 3ds Max 2027 (29.2.0.20588) to run on Linux under a patched Wine 11.0, one failure at a time.
Each blocker gets traced to a root cause. When the cause is in Wine, it gets fixed in Wine's source rather than worked around in the app.

Licensing goes through a normal Autodesk account sign-in. Nothing here touches or bypasses Autodesk licensing.

## Status

| # | Stage | State |
|---|-------|-------|
| 0 | Installer media verified (Authenticode, all Autodesk-signed) | ✅ |
| 1 | Prefix + runtimes (VC++ 2022, .NET 8/10 desktop + ASP.NET, WebView2, DXVK) | ✅ |
| 2 | Autodesk Desktop Licensing service installed and **running** | ✅ (patch 0003) |
| 3 | `3dsMax.msi` installed, product 128S1 registered with licensing | ✅ |
| 4 | `3dsmax.exe` starts (no loader errors) | ⏳ |
| 5 | Splash → sign-in (Autodesk Identity / WebView2) | ⏳ |
| 6 | Main UI (Qt) | ⏳ |
| 7 | Nitrous viewport (D3D11 via DXVK) | ⏳ |

Skipped on purpose: the Material Library packages (MSIX/AdIX, ODIS error 4005), Arnold, USD, Substance, and the other optional plugins.

The full investigation log, with symptom, root cause and fix for each step, is in [docs/JOURNAL.md](docs/JOURNAL.md).

## Wine patches

Against `wine-11.0`, in [`patches/wine-11.0/`](patches/wine-11.0):

| Patch | Module | Fixes |
|-------|--------|-------|
| 0001 | ntdll (actctx) | `<exe>.config` `<probing privatePath>` ignored. ODIS `Setup.exe` couldn't find its side-by-side assemblies in `ODIS\`. |
| 0002 | wintrust | No `WTD_CHOICE_BLOB` support and no AppX P7X SIP. ODIS couldn't verify MSIX signatures. |
| 0003 | ntdll (unix) | Go and .NET services never reach the SCM: they check that the parent `services.exe` is in **session 0**, and Wine reports session 1. `AdskLicensingService` failed with error 1053. |

## Layout

```
README.md
docs/JOURNAL.md                      hill-climb log
patches/wine-11.0/*.patch            wine patches (git format-patch)
scripts/env.sh                       source me: WINEPREFIX, patched wine on PATH, log dir
scripts/make-wine-tree.sh            copy Gentoo's wine-vanilla-11.0 to ~/opt/wine-11.0-patched
scripts/build-wine.sh                apply patches, build patched modules, deploy them
scripts/deploy.sh                    copy built modules into the private wine tree (keeps .orig)
scripts/patched-modules.txt          which modules build-wine.sh builds and deploys
scripts/setup-prefix.sh              prefix + runtimes from the media's 3rdParty folder
scripts/install-licensing.sh         AdskLicensing (needs patch 0003)
scripts/install-max-msi.{sh,bat}     core 3dsMax.msi, without ODIS
scripts/run-3dsmax.sh                launch with logging
tools/sigcheck.c                     WinVerifyTrust-based signature checker (make -C tools)
logs/ snapshots/                     local only (gitignored)
```

## Reproducing

This assumes Gentoo with `app-emulation/wine-vanilla-11.0` (USE `wow64 vulkan opengl X wayland mingw`), winetricks, mingw-w64,
and the 3ds Max 2027 installer media unpacked to `~/3dsmax-setup`.

```sh
scripts/make-wine-tree.sh            # private wine runtime, system wine stays untouched
scripts/build-wine.sh                # patch + build + deploy (ntdll, wintrust)
make -C tools && source scripts/env.sh
wine tools/sigcheck.exe 'Z:\path\to\Setup.exe' ...   # optional: verify the media
scripts/setup-prefix.sh
scripts/install-licensing.sh         # expect "STATE : 4 RUNNING"
scripts/install-max-msi.sh           # writes C:\3dsmax-msi.log, ~1 min
scripts/run-3dsmax.sh
```

Why not just run `Setup.exe`? ODIS works under these patches up to the Material Library (MSIX) packages. Those fail, and because they're "core" dependencies, ODIS then rolls back the whole bundle. Installing the pieces directly is simpler to control and to debug.

## Gotchas

- **The build dir must use Gentoo's install paths.** `ntdll.so` compiles in absolute `BINDIR`/`DATADIR`. Build it with the default `/usr/local` prefix and it can't load `l_intl.nls`, so `ntdll_towupper` dereferences a NULL table and segfaults. `build-wine.sh` handles this.
- **`Current?` directories are fine.** Wine 11 stores junctions on disk as `name?` with the target in the `user.WINEREPARSE` xattr. AdskLicensing's `Current` junction works inside Wine.
- **msiexec quoting.** Wine's msiexec turns the argv `"PROP=C:\a b"` into `"PROP="C:\a b""`, which is invalid (exit 1639). That's why the MSI is run from a `.bat` file.

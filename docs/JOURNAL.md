# Hill-climb journal

Each entry records how far things got, what broke, why, and what fixed it. Newest entries go at the bottom.

Environment: Gentoo, kernel 6.18, i5-10210U with Intel UHD (CometLake GT2, Mesa ANV Vulkan), 16 GB RAM, Wayland session with XWayland.
Wine is a private copy of Gentoo's `wine-vanilla-11.0` with patched modules layered on top. The prefix is `~/.wine-3dsmax`.

---

## 2026-10-14

### Starting point (from an earlier session)

- Prefix with `win10` and DXVK set up through winetricks.
- ODIS `Setup.exe` ran far enough to install VC++ 2022 x86/x64, .NET 8.0.11 and 10.0.0 (desktop and ASP.NET), and WebView2. It needed patches **0001** (app.config `privatePath`) and **0002** (wintrust blob/AppX SIP).
- ODIS then failed on the Material Library packages with **error 4005**. The AdIX/MSIX handler failed in `PopulatePackageInfo`, HRESULT `0x8bad0042`. These are core dependencies of the 3ds Max package, so ODIS rolled back everything: no 3ds Max, no AdskLicensing.
- Decision: skip the Material Library and ODIS. Install the pieces directly.

### Media integrity

Authenticity was checked before running anything. I built `tools/sigcheck.exe`, which runs `WinVerifyTrust` through Wine's wintrust and checks the Authenticode hash and the chain against the host CA store. It passed for Setup.exe, AdskLicensing-installer.exe, 3dsMax.msi, cer.msi, adsk-hive-host.msi, InstallCustomAction.exe, AdODIS-installer.exe and AdAccess-installer.exe. All are signed by *Autodesk, Inc.* under *DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1*.

### AdskLicensing: `Current?` directory

- **Symptom:** `AdskLicensing-installer.exe --mode unattended` exited 84 and left a directory literally named `Current?`.
- **Investigation:** `+file` trace of `AdskLicensingInstHelper.exe makelink` shows `CreateDirectoryW(...\Current)`, then `CreateFileW(FILE_FLAG_BACKUP_SEMANTICS)`, then `NtFsControlFile(FSCTL_SET_REPARSE_POINT, 0x154 bytes)`.
- **Root cause:** none. This is Wine 11's on-disk format for reparse points: `name?` plus the `user.WINEREPARSE` xattr (see `dlls/ntdll/unix/file.c`, `resolve_reparse_point`). `cmd /c dir ...\Current\AdskLicensingService\AdskLicensingService.exe` resolves correctly.

### AdskLicensing: service start error 1053 → patch 0003

- **Symptom:** the installer log shows `servicectl start` failing with `Calling system API failed, (error code 1053)` and the installer exits `69009748`. `sc start AdskLicensingService` also returns 1053 (ERROR_SERVICE_REQUEST_TIMEOUT).
- **Investigation:** the service's own log (`C:\ProgramData\Autodesk\AdskLicensingService\Log\AdskLicensingService.log`) shows it starting fine and serving HTTP on 127.0.0.1:46201. So the process runs but never reports to the SCM. Lines like `map[]` hint at Go. `strings` confirms Go 1.25.3 with `golang.org/x/sys/windows/svc.IsWindowsService` and `svc.Run`.
- **Root cause:** `svc.IsWindowsService()` walks `SystemProcessInformation`, finds the parent, and requires `SessionId == 0 && ImageName == "services.exe"`. .NET's `WindowsServiceHelpers.IsWindowsService()` does the same check. Wine hardcodes `default_session_id = 1` (`server/process.h`) for every process, services.exe included. The service therefore thinks it's interactive, runs as a console app, never calls `StartServiceCtrlDispatcher`, and the SCM times out.
- **Fix considered and rejected:** actually putting services.exe and its children in session 0. Wine does separate sessions for real: unprefixed named objects live in `\Sessions\N\BaseNamedObjects`, and window stations live in `\Sessions\N\Windows\WindowStations`. Moving services there would break the unprefixed `__wine_SvcctlStarted` handshake with wineboot and split window stations.
- **Fix (patch 0003):** `get_system_process_info()` reports `SessionId = 0` for `...\system32\services.exe`. Nothing else changes.
- **Result:** `sc query AdskLicensingService` gives `STATE : 4 RUNNING`. Re-running the licensing installer gives `Exiting with code 0`.

### Building ntdll.so: segfault on startup

- **Symptom:** after deploying the rebuilt `ntdll.so`, every wine process segfaulted: `segfault at 0 ... in ntdll.so[14aa0]`.
- **Root cause:** the faulting code is `ntdll_towupper()` reading `uctable`, which was NULL. `init_environment()` loads it from `l_intl.nls` under the compiled-in `DATADIR`. `build64` had been configured with the default `/usr/local` prefix, while the runtime is Gentoo's `/usr/lib/wine-vanilla-11.0`.
- **Fix:** configure the build dir with `--prefix=/usr/lib/wine-vanilla-11.0 --libdir=/usr/lib/wine-vanilla-11.0 --datadir=/usr/share/wine-vanilla-11.0`, now baked into `scripts/build-wine.sh`.

### 3dsMax.msi

- Direct install with `msiexec /i 3dsMax.msi /qn INSTALLDIR=... ADLM_PRODKEY=128S1 ADLM_EULA_COUNTRY=US`.
- **Wine msiexec quirk:** with bash quoting, Wine passes `"INSTALLDIR=C:\Program Files\..."` as one argv. msiexec's `build_properties` rewrites it as `"INSTALLDIR="C:\...""` and the install fails with 1639 (exit 103). A trailing `\` before the closing quote breaks it the same way. Workaround: run msiexec from a `.bat` (`scripts/install-max-msi.bat`).
- **Result:** `INSTALL. Return value 1`, about 40 s for 17.7k files and 3.5 GB. The licensing custom actions (`licMarkInstall`, `licIsSvcUpgraded`, `licRegister`) all succeeded. The last one ran `AdskLicensingInstHelper register -pk 128S1 -pv 2027.0.0.F ...`.
- Minor issue: the `RegisterInventorServerHost` custom action (type 34, async, return ignored) failed with `unable to execute command 2`. Wine resolves the bare `MaxInventorServerHost.exe` against the caller's directory, not `lpCurrentDirectory`. It only matters for Inventor import. TODO: run `MaxInventorServerHost.exe /regserver` by hand.

### First launch: no Identity Manager

- **Symptom:** `3dsmax.exe` exits with code 244. The log says `AdskIdentityManager installation could not be located. Error Code: 3202`.
- **Root cause:** Autodesk Identity Manager, the sign-in component, isn't on the media. ODIS fetches it from Autodesk at install time. The SDK looks it up under `HKLM\SOFTWARE\Autodesk\AdskIdentityManager`.
- **Fix:** Autodesk publishes the installer at `up1.autodesk.com/IDSDK/Windows/1.12.0.7/AdskIdentityManager-UCT-Installer.exe` (signature verified). Its compatibility file accepts any SDK version.
- **Gotcha:** the UCT installer is an ODIS LauncherApp. Without ODIS installed it shows a hidden error and hangs forever (`ODIS installer is either missing or corrupted. ErrorCode: 3051`). Install `ODIS/AdODIS-installer.exe` first. Afterwards ODIS uninstalls itself, because no ODIS products are registered, and takes Autodesk Access with it. That's harmless.

### Splash shows "/2027 - 64bit", empty product info → patch 0004

- **Symptom:** after the startup-failure dialog (Continue Without Restore) and the privacy dialog, 3ds Max exits. CER logs `Error accessing UPI repository`, with an empty product line, release and AppName. The splash title is `/2027 - 64bit`.
- **Investigation:** UPI reads string resources 8700/8702/8704 from `res10.dll`. `inspect_pe_resources` (REA) shows `res10.dll` has only `MUI`/`VERSION`/`MANIFEST`. The `RT_STRING` blocks live in `en-US\res10.dll.mui`.
- **Root cause:** Wine has no MUI satellite fallback in `FindResource`/`LoadResource`, so `LoadString` returns empty for every language-neutral module.
- **Fix (0004):** kernelbase loads `<dir>\<lang>\<name>.mui` as a datafile when a resource is missing from an LN module. Languages are tried in this order: UI language, neutral parent, the module's fallback language, en-US. Results are cached per module. `LoadResource` resolves HRSRCs that point into a satellite against that satellite. `muitest res10.dll 8700 8702 8704` → `3DSMAX / 2027 / Win64`.

### WebView2 license page blank

The licensing agent (`AdskLicensingAgent.exe`) asks "how do you want to license" in a WebView2 window. It stayed gray.

1. **GPU process crash loop.** Chromium logging (`--enable-logging --log-file`) shows `GPU process exited unexpectedly: exit_code=-2147483645` (STATUS_BREAKPOINT) six times, then `GPU process isn't usable. Goodbye.` The cause is `DCompositionCreateDevice failed: Not implemented`, because Wine's dcomp.dll is a 47-line stub (upstream too). → Backported wine-staging's dcomp series (65 patches, minus the test-only `0065` and the server-protocol `0062`), plus `dcomp.idl`/`d2d1effects.idl` from master.
2. **`IDXGIFactory2::CreateSwapChainForComposition failed: Not implemented`.** That's DXVK's dxgi. → staging's dxgi hack, and per-app overrides so `msedgewebview2.exe` uses Wine's dxgi/d3d11. This has to use `*d3d11` keys, because the global `*d3d11=native` (DXVK) otherwise wins.
3. **Still blank.** The window tree (`winlist tree`) shows WebView2's child windows are owned by three different processes (host → browser → GPU) and are hidden. Force-showing them gives black. Wine's `update_visible_region` gives no window surface to windows whose top-level is in another process, and offscreen GL/Vulkan child surfaces present through GDI as well. So cross-process child drawing gets overwritten by the owner's surface flushes. **Not fixed.** It needs cross-process client surfaces in win32u/winex11.

### Sign-in through the system browser

- Identity Manager 1.12's config has `bringDefaultWebBrowserToFront`, and its OAuth redirect is `https://accounts.autodesk.com/idmgr/callback`. The actual login already happens in the default browser.
- Skip the WebView2 license page with Autodesk's documented `AdskLicensingInstHelper change --pk 128S1 --pv 2027.0.0.F --lm USER --fi 3DSMAX`.
- After that, Identity Manager calls `winebrowser.exe "https://developer.api.autodesk.com/authentication/v2/authorize?..."`, which opens in the Linux browser.
- After login, the callback page opens `adskidmgr:/login?...`. Identity Manager registers `adskidmgr` and `adsk.idmgr` only in Wine's registry, so Linux had no handler. → `scripts/adsk-url-handler.sh` plus an `x-scheme-handler` desktop entry that forwards the link to `AdskIdentityManager.exe` in the prefix. The log then shows `Found valid http route:/login`, and the session is restored.
- **Result:** the main UI and the Nitrous viewport come up. The title shows the education license. Creating a box works.

### White flashes on anything that redraws → patch 0074

- **Symptom:** brief white flashes on hover, orbit, menus and moving floaters, worst in the viewport.
- **Measurement:** recorded the window with `ffmpeg -f x11grab -window_id` while `winlist redraw` invalidated it 15 times. The viewport was ≥30% white in **158/180** frames, and stayed white until the next Nitrous present. The command panel was white in 0/180.
- **Root cause:** the Nitrous viewport is a `Label` child window with `WS_EX_TRANSPARENT` (ex-style 0x20) that presents through DXVK (Vulkan client surface, `clip_clients`). `server/window.c:clip_pixel_format_children()` skips transparent children entirely, so the viewport was never subtracted from the top-level window surface. Surfaces are initialized to 0xff (`win32u/dce.c`), and 3ds Max never GDI-paints that area. So every surface flush overlapping the viewport put white over the last presented frame.
- **Fix (0074):** transparent children still don't cover siblings, but their pixel-format client area is subtracted. **Result: 0/180** white frames under the same test, and the viewport stays intact.

### Launcher

- **Symptom:** GNOME showed "Brazilian Portuguese is not responding" spam. The user had started 3ds Max from the installer's menu entries. Those use the **system** `wine` (unpatched: splash back to `/2027 - 64bit`), there's one per language, and all of them claim `StartupWMClass=3dsmax.exe`. GNOME named the window after one of them and pinged a hung window.
- **Fix:** `scripts/install-launcher.sh` creates a single `3ds Max 2027` entry running `run-3dsmax.sh` (also the `.max` handler), removes the installer's entries, and `env.sh` disables winemenubuilder so they aren't regenerated. Launching from the app grid takes about 30 s to the main window. The patched ntdll is confirmed loaded.

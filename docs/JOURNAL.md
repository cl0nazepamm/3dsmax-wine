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

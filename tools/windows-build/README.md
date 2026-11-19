# Windows build under Wine

The fork's Windows executable is built on Linux: Windows CPython runs under Wine and PyInstaller
freezes Explorer with the command of `build.bat`. Sources, logs and release files go to
`$ESIBD_BUILD_DIR` (default `~/.cache/esibd-build`); `env.sh` holds the other settings.

## Once per machine

1. Wine (11 or later), Xvfb, `zip`, ImageMagick `import`, `clang` and an lld linker (rust-lld of rustup).
2. A Wine prefix with the official Windows CPython (checksum from python.org):

   ```bash
   export WINEPREFIX=~/.wine-esibd-build-314 WINEARCH=win64
   wineboot -i
   wine python-3.14.10-amd64.exe /quiet InstallAllUsers=1 'TargetDir=C:\Python314' Include_launcher=0 Include_test=0 PrependPath=0 Shortcuts=0
   ```

   First keep Wine from adding the shortcuts of what is installed there to the Linux menus:
   `wine reg add 'HKCU\Software\Wine\DllOverrides' /v winemenubuilder.exe /t REG_SZ /d '' /f`.

3. An X server for the smoke test: `Xvfb :97 -screen 0 1600x1000x24 -nolisten tcp &`
4. The Wine shims of Qt 6.12: `wine-shims/build.sh` (see below).
5. Inno Setup 6 for the installer, in the same prefix (release `is-6_7_4` of jrsoftware/issrc on GitHub,
   checked against the SHA-256 GitHub lists for it):
   `wine innosetup-6.7.4.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- '/DIR=C:\InnoSetup6'`.

## Each release

```bash
tools/windows-build/prepare.sh v1.0.2+od.5     # export the tag, install it with constraints-windows.txt
tools/windows-build/build_exe.sh               # PyInstaller
tools/windows-build/check.sh 1.0.2+od.5        # fork code and version in the bundle, plugin imports
tools/windows-build/smoke.sh                   # start it on Xvfb: must reach Ready
tools/windows-build/package.sh 1.0.2+od.5      # zip, requirements-windows.txt, SHA256SUMS
tools/windows-build/installer.sh 1.0.2+od.5    # setup.exe (installer.iss), tested: install, start, uninstall
```

The setup installs for all users in `Program Files\ESIBD Lab\ESIBD Explorer` (administrator rights), with
Start menu and desktop shortcuts. It first removes the `_internal` folder of an earlier version, and
uninstalls an ESIBD Explorer installed by another installer (InstallForge, as 1.0.2) after confirmation.
Settings, configuration and data are kept: they are stored outside the program folder. The test installs it
in the build prefix over a stand-in for such an earlier installation, starts the installed Explorer until
Ready and uninstalls it.

`constraints-windows.txt` pins every package of the executable. Keep it in step with the plugins'
test environment (`esibd-explorer-plugins/requirements-dev.txt`), which installs this fork: the
plugins are then tested with the packages the lab runs.

## Wine shims

Two DLLs make Qt 6.12 work under Wine 11. They are installed in the build prefix only; PyInstaller
treats them as system DLLs and never bundles them (`build_exe.sh` checks it). On Windows 10 and 11
the system provides the real ones.

- `icuuc.dll`: Qt 6.12's `Qt6Core.dll` imports 20 `ucnv_*` functions of the Windows system ICU.
  The shim forwards each to the official ICU 79.1 (`icuuc79.dll`, versioned names). Without it,
  PyQt6 does not import and PyInstaller silently builds an Explorer without Qt (about 1 950 files
  instead of about 4 600).
- `mscms.dll`: Qt 6.12's `qwindows.dll` calls `WcsCreateIccProfile`, which Wine lacks; the stub
  reports that no colour profile exists. Wine keeps its own `mscms` unless
  `WINEDLLOVERRIDES=mscms=n`, which only `smoke.sh` sets.

## Notes

- Under Wine the frozen Explorer gets a cp1252 stdout; since 1.0.2+od.4 the Logger replaces what it
  cannot encode, so the smoke test shows the GUI and the log.
- The smoke test leaves an empty `PyQt6/Qt6/resources/locales` folder in the dist; `package.sh`
  removes it and checks that the dist is the build output.

# Ardour Windows Build - Lessons Learned

## Project Overview
Successfully built Ardour 9.0-rc1 natively on Windows 11 using MSYS2/MinGW-w64.

## Key Insights

### 1. Build Approach: Native MSYS2 vs Cross-Compilation
- Ardour's official Windows builds use cross-compilation from Linux
- Native MSYS2 build is viable and simpler for local development
- Use MinGW64 shell (`msys2_shell.cmd -mingw64`) for all build operations

### 2. WAF Build System Configuration
The critical configure options for Windows:
```bash
./waf configure \
    --dist-target=mingw \
    --optimize \
    --no-phone-home \
    --with-backends=dummy,portaudio
```

**Important flags:**
- `--dist-target=mingw` - Essential for Windows target
- `--with-backends=dummy,portaudio` - PortAudio is the primary Windows audio backend (not JACK)
- `--no-phone-home` - Disable telemetry for self-builds

### 3. Windows Path Detection (No Environment Variables!)
**Critical Discovery:** On Windows, Ardour does NOT use `ARDOUR_DLL_PATH`, `ARDOUR_DATA_PATH`, etc.

Instead, it uses:
```cpp
g_win32_get_package_installation_directory_of_module()
```

This automatically detects paths based on the executable location. The expected directory structure:
```
<root>/
├── bin/ardour-X.X.X.exe
├── lib/ardour9/          <- DLLs, backends, panners, surfaces
├── lib/gtk-2.0/2.10.0/engines/  <- GTK theme engines
└── share/ardour9/        <- Resources, themes, fonts
```

### 4. DLL Dependencies
Ardour builds 33+ DLLs that must be collected:
- Main libs: `libardour.dll`, `libpbd.dll`, etc.
- Control protocols: `ardourcp.dll`, `ardour_midisurface.dll`
- LV2 plugins: `a-comp.dll`, `a-delay.dll`, etc.
- GTK toolkit: `ytk.dll`, `ydk.dll`, `ztk.dll`
- Plugin support: `suil.dll`, `suil_win_in_gtk2.dll`

**Gotcha:** DLLs are in nested directories under `libs/`. Use recursive find:
```bash
find build/libs -name "*.dll"
```

### 5. Launcher Script Requirements
The launcher must set:
```batch
set PATH=C:\msys64\mingw64\bin;%ARDOUR_ROOT%\lib\ardour9;%PATH%
set GTK_PATH=%ARDOUR_ROOT%\lib
```

- `PATH` - For MinGW runtime DLLs and Ardour DLLs
- `GTK_PATH` - For GTK theme engines (clearlooks)

### 6. GTK Theme Engine (Clearlooks)
- Ardour uses a custom clearlooks theme engine (`clearlooks.dll`)
- Must be placed in `lib/gtk-2.0/2.10.0/engines/`
- Copy as both `clearlooks.dll` AND `libclearlooks.dll` for compatibility
- Set `GTK_PATH` to point to `lib/` directory

### 7. Fonts
- Custom fonts: `ArdourMono.ttf`, `ArdourSans.ttf`
- Place in `share/ardour9/`
- Loaded via FontConfig at runtime by `load_custom_fonts()`
- The "Sans Ultra-Light Ultra-Condensed" warning is cosmetic (system font fallback)

### 8. VST Scanner Executables
- `ardour-vst-scanner.exe` and `ardour-vst3-scanner.exe`
- Must be in `lib/ardour9/fst/`
- Built from `libs/fst/` directory

### 9. Build Dependencies (MSYS2 packages)
Key packages needed:
```bash
pacman -S mingw-w64-x86_64-{gtk2,gtkmm,boost,libxml2,libxslt,curl,fftw}
pacman -S mingw-w64-x86_64-{libsndfile,libsamplerate,rubberband,portaudio}
pacman -S mingw-w64-x86_64-{lv2,serd,sord,sratom,lilv,suil}
pacman -S mingw-w64-x86_64-{liblo,aubio,taglib,cppunit}
```

### 10. Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `ardourcp.dll not found` | DLLs in nested dirs not copied | Use recursive find for DLLs |
| `clearlooks theme engine not found` | GTK_PATH not set | Set GTK_PATH in launcher |
| `Cannot find ArdourMono font` | Fonts not in data path | Copy TTFs to share/ardour9/ |
| Build fails with symbol errors | Large object files | Use `--optimize` flag |

### 11. Package Structure
Final working structure:
```
Ardour-9.0-rc1-6-g8ca808346a-win64/
├── bin/
│   └── ardour-9.0.rc1.6.exe
├── lib/
│   ├── ardour9/
│   │   ├── *.dll (33 files)
│   │   ├── backends/
│   │   ├── panners/
│   │   ├── surfaces/
│   │   └── fst/
│   │       ├── ardour-vst-scanner.exe
│   │       └── ardour-vst3-scanner.exe
│   └── gtk-2.0/2.10.0/engines/
│       ├── clearlooks.dll
│       └── libclearlooks.dll
├── share/
│   └── ardour9/
│       ├── ArdourMono.ttf
│       ├── ArdourSans.ttf
│       ├── themes/
│       ├── scripts/
│       └── ... (resources)
├── Ardour.bat
├── Ardour-debug.bat
└── run-test.bat
```

## Warnings That Can Be Ignored
- `ARDOUR_DATA_PATH not set in environment` - Expected on Windows
- `ARDOUR_CONFIG_PATH not set in environment` - Expected on Windows
- `Sans Ultra-Light Ultra-Condensed` font warning - Cosmetic, no fix needed
- `lilv_world_load_directory()` LV2 path warnings - Environment variable expansion issue

## Future Improvements
1. Create NSIS installer script for distribution
2. Bundle MinGW runtime DLLs for standalone operation
3. Add code signing for Windows security
4. Consider static linking to reduce DLL count

## Build Time
- First build with dependencies: ~1-2 hours
- Incremental rebuilds: ~20-40 minutes
- Packaging: ~5 minutes

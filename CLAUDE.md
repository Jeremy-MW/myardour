# Ardour Windows Build Project

## Project Overview
This project builds Ardour DAW natively on Windows using MSYS2/MinGW-w64.

## Directory Structure
- `ardour/` - Ardour source code (git submodule)
- `windows-build/` - Build scripts for MSYS2
- `Export/` - Output directory for packaged builds

## Build Commands

### Full Build (from MSYS2 MinGW64 shell)
```bash
cd /c/dev/myardour/windows-build
bash install-deps.sh   # First time only
bash configure.sh
JOBS=4 bash build.sh
```

### Incremental Build
```bash
cd /c/dev/myardour/ardour
./waf -j4
```

### Package Build
After building, copy files to Export directory following structure in LESSONS_LEARNED.md.

## Critical Build Notes

### Windows Path Detection
Ardour on Windows does NOT use environment variables like `ARDOUR_DLL_PATH`. It uses `g_win32_get_package_installation_directory_of_module()` to detect paths from the executable location.

### Required Package Structure
```
<root>/
├── bin/ardour-X.X.X.exe
├── lib/ardour9/           <- All Ardour DLLs
├── lib/gtk-2.0/2.10.0/engines/  <- clearlooks.dll
└── share/ardour9/         <- Resources
```

### DLL Collection
DLLs are scattered in nested directories. Use:
```bash
find build/libs -name "*.dll"
```

### Launcher Requirements
Must set in launcher script:
- `PATH` to include `C:\msys64\mingw64\bin` and `lib\ardour9`
- `GTK_PATH` to `lib` directory for theme engines

## WAF Configure Options
```bash
./waf configure \
    --dist-target=mingw \
    --optimize \
    --no-phone-home \
    --with-backends=dummy,portaudio
```

## Testing
Run from Export directory:
```
.\run-test.bat      # Debug output
.\Ardour.bat        # Normal launch
```

## Files Reference
- `LESSONS_LEARNED.md` - Detailed build lessons and troubleshooting
- `windows-build/README.md` - Build script documentation

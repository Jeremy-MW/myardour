# Ardour Windows Build System

This directory contains scripts for building Ardour DAW on Windows 11 using MSYS2/MinGW-w64.

## Prerequisites

- **Windows 10/11** (64-bit)
- **~20 GB free disk space** for MSYS2, dependencies, and build files
- **Internet connection** for downloading packages
- **PowerShell 5.0+** (included with Windows 10/11)

## Quick Start

### Option 1: Automated Setup (Recommended)

1. Open PowerShell as Administrator
2. Run the setup script:
   ```powershell
   cd C:\dev\myardour\windows-build
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\setup-msys2.ps1
   ```
3. After setup completes, run the build:
   ```batch
   build.bat
   ```

### Option 2: Manual Setup

1. **Install MSYS2** from https://www.msys2.org/
   - Download and run the installer
   - Install to `C:\msys64` (default location)

2. **Update MSYS2** packages:
   ```bash
   # Open MSYS2 MinGW64 shell and run:
   pacman -Syu
   pacman -Su
   ```

3. **Install dependencies**:
   ```bash
   # In MSYS2 MinGW64 shell:
   cd /c/dev/myardour/windows-build
   bash install-deps.sh
   ```

4. **Build Ardour**:
   ```bash
   bash build-all.sh
   ```

## Build Scripts

| Script | Purpose |
|--------|---------|
| `setup-msys2.ps1` | PowerShell script to install/configure MSYS2 |
| `install-deps.sh` | Install all required MSYS2 packages |
| `configure.sh` | Configure Ardour build with waf |
| `build.sh` | Compile Ardour |
| `package.sh` | Create distributable package |
| `build-all.sh` | Master script running all steps |
| `build.bat` | Windows launcher for the build |

## Build Options

### Full Build
```bash
./build-all.sh
```

### Debug Build
```bash
./build-all.sh --debug
```

### Clean Rebuild
```bash
./build-all.sh --clean
```

### Skip Steps
```bash
# Skip dependency installation (if already installed)
./build-all.sh --skip-deps

# Only rebuild (after making changes)
./build-all.sh --build-only

# Skip packaging
./build-all.sh --skip-package
```

### Individual Steps
```bash
# Install dependencies only
./install-deps.sh

# Configure only
./configure.sh

# Build only
./build.sh

# Package only
./package.sh
```

## Build Output

After a successful build, you'll find:

- **Package directory**: `../Export/Ardour-<version>-win64/`
- **ZIP archive**: `../Export/Ardour-<version>-win64.zip`

The package contains:
- Ardour executable (`bin/ardour.exe`)
- Required DLLs
- GTK themes and configuration
- Launcher script (`Ardour.bat`)

## Troubleshooting

### MSYS2 Shell Issues

**Problem**: Scripts fail with "must be run from MinGW64 shell"

**Solution**: Make sure you're using the correct shell:
- Use `C:\msys64\msys2_shell.cmd -mingw64` to start MinGW64 shell
- Or run `build.bat` which handles this automatically

### Missing Dependencies

**Problem**: Configuration fails with missing library errors

**Solution**: Re-run dependency installation:
```bash
bash install-deps.sh
```

### pkg-config Not Finding Libraries

**Problem**: `pkg-config --exists <lib>` fails

**Solution**: Ensure PKG_CONFIG_PATH is set:
```bash
export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:/mingw64/share/pkgconfig"
```

### Build Failures

**Problem**: Compilation errors

**Solution**:
1. Check you have all dependencies installed
2. Try a clean build: `./build-all.sh --clean`
3. Check the build log in `ardour/build/config.log`

### Out of Memory

**Problem**: Compiler crashes during build

**Solution**: Reduce parallel jobs:
```bash
JOBS=2 ./build.sh
```

## Dependencies

The build requires approximately 100+ packages from MSYS2. Key dependencies include:

### Build Tools
- MinGW-w64 toolchain (GCC, G++, etc.)
- Python 3
- CMake, Meson, Ninja
- pkg-config

### Core Libraries
- Boost
- GLib 2 / GLibmm
- libxml2 / libxslt
- FFTW3

### GUI (GTK2 Stack)
- GTK+ 2.24
- GTKmm 2.4
- Cairo / Cairomm
- Pango / Pangomm
- ATK / ATKmm

### Audio
- libsndfile
- libsamplerate
- Rubberband
- PortAudio
- FLAC, Vorbis, Opus, LAME

### Plugins
- LV2, Lilv, Serd, Sord, Sratom, Suil
- VAMP SDK
- Aubio

## Notes

### Audio Backend

This build uses **PortAudio** as the primary audio backend. JACK support is disabled by default as JACK on Windows requires separate installation and configuration.

To enable JACK support (requires JACK2 installed):
```bash
WITH_JACK=yes ./configure.sh
```

### GTK Theming

The build includes basic GTK theming. For better appearance, you may want to copy GTK themes from an official Ardour installation.

### Performance

- First build with dependencies: 1-2 hours
- Subsequent builds: 20-40 minutes
- Clean rebuild: 30-60 minutes

Build time depends on your CPU and disk speed. Using an SSD significantly improves build times.

## License

Ardour is licensed under GPL-2.0. See the Ardour source code for full license details.

## References

- [Ardour Official Site](https://ardour.org)
- [Ardour GitHub](https://github.com/Ardour/ardour)
- [MSYS2](https://www.msys2.org)
- [Ardour Development](https://ardour.org/development.html)

# Ardour Windows Build Guide

This directory contains all the necessary scripts and documentation to build Ardour for Windows 11 using cross-compilation from Linux.

## Overview

Building Ardour for Windows is a multi-step process:

1. **Build the dependency stack** - All required libraries (GTK+, audio libraries, etc.)
2. **Build Ardour** - The main application
3. **Package** - Create a Windows installer

## Quick Start

### Using GitHub Actions (Recommended)

The easiest way to build Ardour for Windows is using GitHub Actions. This repository includes workflows that automate the entire process.

1. Go to the "Actions" tab in this repository
2. Select "Build Ardour for Windows"
3. Click "Run workflow"
4. Download the artifact when complete

### Manual Build (Advanced)

For manual builds, see the detailed instructions below.

## System Requirements

### For Cross-Compilation (Linux)
- Ubuntu 20.04+ or Debian Buster+
- At least 16GB RAM
- At least 50GB free disk space
- Internet connection for downloading dependencies

### Target System (Windows)
- Windows 10 or Windows 11 (64-bit recommended)
- At least 4GB RAM
- Audio interface with ASIO or WASAPI support

## Dependencies Overview

The Windows build requires approximately 50+ libraries to be cross-compiled:

### Core Libraries
- GTK+ 2.24 (GUI toolkit)
- GLib 2.64 (Core library)
- Pango 1.42 (Text rendering)
- Cairo 1.16 (2D graphics)

### Audio Libraries
- PortAudio (Audio I/O with ASIO/WASAPI support)
- libsndfile (Audio file I/O)
- libsamplerate (Sample rate conversion)
- JACK (Audio connection kit)
- FLAC, Vorbis, OGG (Audio codecs)

### Plugin Support
- LV2 (lilv, sord, serd, sratom, suil)
- LADSPA
- VAMP (Audio analysis plugins)
- VST2/VST3 (Windows native plugins)

### Other Dependencies
- Boost 1.68
- FFTw3 (Fast Fourier Transform)
- RubberBand (Time stretching)
- taglib (Audio metadata)
- curl (Network support)
- And many more...

## Build Process Details

### Step 1: Set Up Build Environment

```bash
# Install required packages (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y \
    mingw-w64 g++-mingw-w64 gcc-mingw-w64 \
    build-essential autoconf automake libtool pkg-config \
    yasm nasm git cmake nsis wget curl ca-certificates \
    rsync zip unzip gettext meson python3

# Configure MinGW for POSIX threads (required for C++11)
sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
```

### Step 2: Build Dependency Stack

The dependency stack takes several hours to build. Use the provided script:

```bash
sudo ./build-deps.sh x86_64
```

This creates a complete Windows development environment in `/home/ardour/win-stack-w64/`.

### Step 3: Compile Ardour

```bash
./compile.sh
```

This configures and builds Ardour using the waf build system.

### Step 4: Create Windows Installer

```bash
./package.sh
```

This creates an NSIS installer: `Ardour-X.X.X-w64-Setup.exe`

## Build Scripts

| Script | Description |
|--------|-------------|
| `build-deps.sh` | Builds all required dependencies |
| `compile.sh` | Compiles Ardour itself |
| `package.sh` | Creates Windows installer |
| `build-all.sh` | Complete build in one command |

## Build Times

Typical build times on a modern system:

| Step | Time (approx) |
|------|---------------|
| Dependency stack | 4-8 hours |
| Ardour compilation | 30-60 minutes |
| Packaging | 10-20 minutes |

## Troubleshooting

### Common Issues

1. **Missing ASIO SDK**: Download from Steinberg's website and place in the correct location
2. **Out of memory**: Reduce parallel jobs with `MAKEFLAGS=-j2`
3. **Network timeouts**: Re-run the script; downloads are cached

### Getting Help

- [Ardour Forums](https://discourse.ardour.org/)
- [Ardour Development Docs](https://ardour.org/development.html)

## Files in This Directory

- `README.md` - This file
- `build-deps.sh` - Dependency build script
- `compile.sh` - Ardour compilation script  
- `package.sh` - Packaging script
- `build-all.sh` - Complete automated build
- `.github/workflows/` - GitHub Actions workflows

## Version Information

- **Ardour Version**: 9.0-rc1
- **Target Platform**: Windows 10/11 (64-bit)
- **Build Architecture**: x86_64-w64-mingw32
- **Last Updated**: December 2025

## License

Ardour is licensed under the GNU General Public License v2 (GPLv2).
See the main Ardour repository for complete license information.

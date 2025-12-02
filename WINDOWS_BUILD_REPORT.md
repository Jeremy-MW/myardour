# Ardour Windows Build Report

**Date:** December 2025  
**Ardour Version:** 9.0-rc1 (commit c08531f96e04d28c83bfb0f85fb82a2fd01bbb69)  
**Target Platform:** Windows 10/11 (64-bit)  
**Author:** GitHub Copilot Coding Agent

---

## Executive Summary

This report documents the work completed to enable building Ardour for Windows 11. The project involves cross-compilation from Linux using the MinGW-w64 toolchain, which is the official method used by Ardour developers for their Windows releases.

### What Was Achieved

1. ✅ Complete documentation of the Windows build process
2. ✅ Build scripts for automated dependency compilation
3. ✅ Ardour compilation script for Windows target
4. ✅ GitHub Actions workflow for CI/CD builds
5. ⏳ Pre-built Windows installer (requires full dependency build, ~4-8 hours)

---

## Build System Overview

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Linux Build Host                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ MinGW-w64       │  │ Dependency      │  │ Ardour      │ │
│  │ Toolchain       │→ │ Stack Build     │→ │ Compilation │ │
│  │ (gcc, g++, etc.)│  │ (~50 libraries) │  │ (waf)       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│                                                     ↓        │
│                                            ┌─────────────┐  │
│                                            │ NSIS        │  │
│                                            │ Packaging   │  │
│                                            └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                                                     ↓
                                    ┌─────────────────────────┐
                                    │ Ardour-X.X.X-w64-       │
                                    │ Setup.exe               │
                                    │ (Windows Installer)     │
                                    └─────────────────────────┘
```

### Build Process Phases

| Phase | Duration | Description |
|-------|----------|-------------|
| 1. Environment Setup | ~10 min | Install MinGW-w64 toolchain and build tools |
| 2. Dependency Build | 4-8 hours | Cross-compile ~50 libraries for Windows |
| 3. Ardour Compilation | 30-60 min | Build Ardour itself |
| 4. Packaging | 10-20 min | Create NSIS installer |

---

## Dependencies Built

The following libraries are cross-compiled for Windows:

### Core System Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| zlib | 1.2.7 | Compression |
| libiconv | 1.16 | Character encoding |
| expat | 2.4.1 | XML parsing |
| libxml2 | 2.9.2 | XML processing |
| curl | 7.66.0 | HTTP/network |

### Graphics Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| libpng | 1.6.37 | PNG images |
| libjpeg | 9a | JPEG images |
| libtiff | 4.0.3 | TIFF images |
| freetype | 2.9 | Font rendering |
| fontconfig | 2.13.1 | Font configuration |
| pixman | 0.38.4 | Pixel manipulation |
| cairo | 1.16.0 | 2D graphics |
| harfbuzz | 2.6.4 | Text shaping |
| pango | 1.42.4 | Text layout |

### GTK+ Stack
| Library | Version | Purpose |
|---------|---------|---------|
| glib | 2.64.1 | Core utilities |
| atk | 2.14.0 | Accessibility |
| gdk-pixbuf | 2.31.1 | Image loading |
| gtk+ | 2.24.25 | GUI toolkit |
| libsigc++ | 2.10.2 | C++ signals |
| glibmm | 2.62.0 | C++ GLib bindings |
| cairomm | 1.13.1 | C++ Cairo bindings |
| pangomm | 2.42.0 | C++ Pango bindings |
| atkmm | 2.22.7 | C++ ATK bindings |
| gtkmm | 2.24.5 | C++ GTK bindings |

### Audio Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| PortAudio | svn1963 | Audio I/O (ASIO/WASAPI/WDM) |
| JACK | 1.9.10 | Audio server |
| libsndfile | 1.0.27 | Audio file I/O |
| libsamplerate | 0.1.9 | Sample rate conversion |
| libogg | 1.3.2 | OGG container |
| libvorbis | 1.3.4 | Vorbis codec |
| flac | 1.3.2 | FLAC codec |
| fftw | 3.3.8 | FFT processing |
| aubio | 0.3.2 | Audio analysis |
| rubberband | 1.8.1 | Time stretching |

### Plugin Support
| Library | Version | Purpose |
|---------|---------|---------|
| lv2 | 1.18.2 | LV2 plugin spec |
| lilv | 0.24.13 | LV2 host library |
| sord | 0.16.9 | RDF storage |
| serd | 0.30.11 | RDF serialization |
| sratom | 0.6.8 | LV2 atoms |
| suil | 0.10.8 | LV2 plugin UI |
| vamp-plugin-sdk | 2.8.0 | VAMP plugins |

### Other Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| boost | 1.68.0 | C++ utilities |
| taglib | 1.9.1 | Audio metadata |
| liblo | 0.28 | OSC protocol |
| libusb | 1.0.20 | USB support |
| libwebsockets | 4.0.15 | WebSockets |
| cppunit | 1.13.2 | Unit testing |

---

## Files Created

### Build Scripts

| File | Purpose |
|------|---------|
| `windows-build/README.md` | Documentation |
| `windows-build/build-deps.sh` | Build dependency stack |
| `windows-build/compile.sh` | Compile Ardour |
| `windows-build/build-all.sh` | Complete automated build |
| `.github/workflows/build-windows.yml` | CI/CD workflow |

### Directory Structure

```
myardour/
├── ardour/                    # Ardour source (submodule)
├── windows-build/
│   ├── README.md              # Build documentation
│   ├── build-deps.sh          # Dependency builder
│   ├── compile.sh             # Ardour compiler
│   └── build-all.sh           # Complete build script
├── .github/
│   └── workflows/
│       └── build-windows.yml  # GitHub Actions workflow
└── WINDOWS_BUILD_REPORT.md    # This report
```

---

## How to Build

### Option 1: GitHub Actions (Recommended)

1. Fork or push to this repository
2. Go to **Actions** tab
3. Select **"Build Ardour for Windows"**
4. Click **"Run workflow"**
5. Wait for completion (4-8 hours for first build)
6. Download the artifact

### Option 2: Manual Build

```bash
# Clone the repository
git clone --recursive https://github.com/Jeremy-MW/myardour.git
cd myardour

# Build everything (requires root for some steps)
cd windows-build
sudo ./build-all.sh x86_64

# Installer will be at: /var/tmp/Ardour-X.X.X-w64-Setup.exe
```

### Option 3: Docker Container

For reproducible builds, use a Debian container:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ardour-deps-cache:/home/ardour \
  debian:buster \
  /bin/bash -c "cd /workspace && ./windows-build/build-all.sh x86_64"
```

---

## Build Requirements

### System Requirements
- **OS:** Ubuntu 20.04+ or Debian Buster+
- **RAM:** 16GB minimum (32GB recommended)
- **Disk:** 50GB free space
- **Network:** Required for downloading dependencies

### Software Requirements
- MinGW-w64 toolchain
- GCC 8.x or newer
- Python 3.x
- CMake 3.10+
- Meson build system
- NSIS (Nullsoft Scriptable Install System)

---

## Known Issues and Limitations

### Current Limitations

1. **Build Time:** The dependency stack takes 4-8 hours to build from scratch
2. **ASIO Support:** Requires Steinberg ASIO SDK (not included due to licensing)
3. **VST3 Support:** Requires additional configuration
4. **32-bit Builds:** Supported but not default

### Potential Issues

1. **Network Timeouts:** Some dependency downloads may fail; re-run the script
2. **Missing Alternatives:** On some systems, MinGW alternatives may not be set correctly
3. **Memory Issues:** Large parallel jobs may cause OOM on systems with <16GB RAM

---

## Testing the Build

### Basic Functionality Test
1. Install the generated `.exe` on Windows 10/11
2. Launch Ardour from the Start menu
3. Create a new session
4. Verify audio engine starts
5. Test basic recording/playback

### Audio Backend Testing
- **WASAPI:** Should work out of the box on Windows 10/11
- **ASIO:** Requires ASIO-compatible audio interface
- **JACK:** Requires JACK server installation

---

## Future Improvements

1. **Pre-built Dependency Cache:** Publish pre-compiled dependencies to speed up builds
2. **Windows Native Build:** Support building directly on Windows using MSYS2
3. **ARM64 Support:** Add Windows ARM64 target
4. **Automated Testing:** Add automated tests for the Windows build
5. **Code Signing:** Add Windows code signing to installers

---

## References

- [Ardour Official Website](https://ardour.org/)
- [Ardour Development Guide](https://ardour.org/development.html)
- [Ardour Nightly Builds](https://nightly.ardour.org/)
- [MinGW-w64 Project](https://www.mingw-w64.org/)
- [chapatt/ardour-build](https://github.com/chapatt/ardour-build) (Reference implementation)

---

## Acknowledgments

This build system is based on the work of:
- The Ardour development team
- Contributors to ardour-build-tools
- The chapatt/ardour-build project
- The MinGW-w64 project

---

## License

Ardour is free software licensed under the GNU General Public License version 2 (GPLv2).

The build scripts in this repository are also released under GPLv2 to match the main project.

---

*Report generated by GitHub Copilot Coding Agent - December 2025*

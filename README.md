# Ardour Windows Build

Native Windows build of [Ardour](https://ardour.org/) DAW using MSYS2/MinGW-w64.

## About Ardour

Ardour is a professional digital audio workstation (DAW) for recording, editing, and mixing audio. It's free, open-source software that runs on Linux, macOS, and Windows.

## Build Status

- **Version:** 9.0-rc1
- **Platform:** Windows 11 x64
- **Toolchain:** MSYS2 MinGW-w64 (GCC 15.2.0)

## Prerequisites

- [MSYS2](https://www.msys2.org/) installed to `C:\msys64`
- Git
- ~10GB disk space for build

## Quick Start

### 1. Clone Repository
```bash
git clone --recursive https://github.com/yourusername/myardour.git
cd myardour
```

### 2. Install Dependencies
Open MSYS2 MinGW64 shell and run:
```bash
cd /c/dev/myardour/windows-build
bash install-deps.sh
```

### 3. Configure
```bash
bash configure.sh
```

### 4. Build
```bash
JOBS=4 bash build.sh
```

### 5. Package
See `windows-build/package.sh` for packaging instructions.

## Project Structure

```
myardour/
├── ardour/              # Ardour source (submodule)
├── windows-build/       # Build scripts
│   ├── install-deps.sh  # Dependency installer
│   ├── configure.sh     # Configure script
│   ├── build.sh         # Build script
│   └── package.sh       # Packaging script
├── Export/              # Packaged builds
├── CLAUDE.md            # AI assistant instructions
├── LESSONS_LEARNED.md   # Build insights
└── README.md            # This file
```

## Package Structure

The built package follows this structure:
```
Ardour-9.0-rc1-win64/
├── bin/
│   └── ardour-9.0.rc1.6.exe
├── lib/
│   ├── ardour9/
│   │   ├── *.dll
│   │   ├── backends/
│   │   ├── panners/
│   │   ├── surfaces/
│   │   └── fst/
│   └── gtk-2.0/2.10.0/engines/
│       └── clearlooks.dll
├── share/
│   └── ardour9/
│       ├── themes/
│       ├── scripts/
│       └── ...
├── Ardour.bat
└── Ardour-debug.bat
```

## Running

Use the launcher scripts in the Export directory:
- `Ardour.bat` - Normal launch
- `Ardour-debug.bat` - Launch with debug output
- `run-test.bat` - Launch with full console output

## Build Options

### WAF Configure Flags
| Flag | Description |
|------|-------------|
| `--dist-target=mingw` | Target Windows/MinGW |
| `--optimize` | Optimized release build |
| `--no-phone-home` | Disable telemetry |
| `--with-backends=dummy,portaudio` | Audio backends |

### Parallel Builds
Set `JOBS` environment variable:
```bash
JOBS=8 bash build.sh
```

## Troubleshooting

### Missing DLLs
Ensure `PATH` includes:
- `C:\msys64\mingw64\bin`
- `<install>\lib\ardour9`

### Theme Engine Errors
Set `GTK_PATH` to `<install>\lib`

### Font Warnings
"Sans Ultra-Light Ultra-Condensed" warning is cosmetic and can be ignored.

See `LESSONS_LEARNED.md` for detailed troubleshooting.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Ardour is licensed under the [GNU General Public License v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html).

## Acknowledgments

- [Ardour Team](https://ardour.org/) for the amazing DAW
- [MSYS2 Project](https://www.msys2.org/) for the Windows build environment
- All contributors to the open-source audio ecosystem

## Links

- [Ardour Official Site](https://ardour.org/)
- [Ardour GitHub](https://github.com/Ardour/ardour)
- [Ardour Manual](https://manual.ardour.org/)
- [MSYS2](https://www.msys2.org/)

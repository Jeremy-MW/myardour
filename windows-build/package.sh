#!/bin/bash
# Ardour Windows Build - Package Script
# This script creates a distributable package of Ardour for Windows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_status() {
    echo -e "${CYAN}[PACKAGE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARDOUR_DIR="$(cd "$SCRIPT_DIR/../ardour" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../Export}"

# Package options
CREATE_INSTALLER="${CREATE_INSTALLER:-no}"
STRIP_BINARIES="${STRIP_BINARIES:-yes}"

# Check environment
check_environment() {
    if [[ "$MSYSTEM" != "MINGW64" ]]; then
        log_error "This script must be run from MSYS2 MinGW64 shell"
        exit 1
    fi

    if [[ ! -d "$ARDOUR_DIR/build" ]]; then
        log_error "Ardour build not found. Run ./build.sh first"
        exit 1
    fi

    log_success "Environment check passed"
}

# Get Ardour version from source
get_version() {
    local version_file="$ARDOUR_DIR/libs/ardour/revision.cc"

    if [[ -f "$version_file" ]]; then
        # Try to extract version from revision.cc
        grep -oP 'revision = "\K[^"]+' "$version_file" 2>/dev/null || echo "unknown"
    else
        # Fall back to git
        cd "$ARDOUR_DIR"
        git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "dev"
    fi
}

# Create output directory structure
create_output_dirs() {
    local version=$(get_version)
    local pkg_name="Ardour-$version-win64"

    PACKAGE_DIR="$OUTPUT_DIR/$pkg_name"

    log_status "Creating package directory: $PACKAGE_DIR"

    rm -rf "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR/bin"
    mkdir -p "$PACKAGE_DIR/lib"
    mkdir -p "$PACKAGE_DIR/share"
    mkdir -p "$PACKAGE_DIR/etc"

    log_success "Output directories created"
}

# Copy Ardour executables and libraries
copy_ardour_files() {
    log_status "Copying Ardour files..."

    # Find and copy executables
    find "$ARDOUR_DIR/build" -name "*.exe" -type f | while read exe; do
        log_status "  Copying $(basename $exe)"
        cp "$exe" "$PACKAGE_DIR/bin/"
    done

    # Copy built libraries
    find "$ARDOUR_DIR/build/libs" -name "*.dll" -type f 2>/dev/null | while read dll; do
        cp "$dll" "$PACKAGE_DIR/lib/"
    done

    # Copy shared data
    if [[ -d "$ARDOUR_DIR/build/share" ]]; then
        cp -r "$ARDOUR_DIR/build/share/"* "$PACKAGE_DIR/share/" 2>/dev/null || true
    fi

    # Copy resource files from source
    if [[ -d "$ARDOUR_DIR/share" ]]; then
        cp -r "$ARDOUR_DIR/share/"* "$PACKAGE_DIR/share/" 2>/dev/null || true
    fi

    log_success "Ardour files copied"
}

# Copy required MinGW DLLs
copy_mingw_dlls() {
    log_status "Copying MinGW runtime DLLs..."

    local mingw_bin="/mingw64/bin"

    # Core runtime DLLs
    local core_dlls=(
        "libgcc_s_seh-1.dll"
        "libstdc++-6.dll"
        "libwinpthread-1.dll"
    )

    # GTK and GUI DLLs
    local gtk_dlls=(
        "libgtk-win32-2.0-0.dll"
        "libgdk-win32-2.0-0.dll"
        "libgdk_pixbuf-2.0-0.dll"
        "libglib-2.0-0.dll"
        "libgmodule-2.0-0.dll"
        "libgobject-2.0-0.dll"
        "libgio-2.0-0.dll"
        "libgthread-2.0-0.dll"
        "libpango-1.0-0.dll"
        "libpangocairo-1.0-0.dll"
        "libpangoft2-1.0-0.dll"
        "libpangowin32-1.0-0.dll"
        "libcairo-2.dll"
        "libcairo-gobject-2.dll"
        "libatk-1.0-0.dll"
        "libfontconfig-1.dll"
        "libfreetype-6.dll"
        "libharfbuzz-0.dll"
        "libpixman-1-0.dll"
        "libpng16-16.dll"
        "zlib1.dll"
        "libbz2-1.dll"
        "libbrotlidec.dll"
        "libbrotlicommon.dll"
        "libintl-8.dll"
        "libiconv-2.dll"
        "libffi-8.dll"
        "libpcre2-8-0.dll"
        "libexpat-1.dll"
    )

    # GTKmm C++ bindings
    local gtkmm_dlls=(
        "libgtkmm-2.4-1.dll"
        "libgdkmm-2.4-1.dll"
        "libglibmm-2.4-1.dll"
        "libgiomm-2.4-1.dll"
        "libcairomm-1.0-1.dll"
        "libpangomm-1.4-1.dll"
        "libatkmm-1.6-1.dll"
        "libsigc-2.0-0.dll"
    )

    # Audio libraries
    local audio_dlls=(
        "libsndfile-1.dll"
        "libsamplerate-0.dll"
        "librubberband-2.dll"
        "libportaudio.dll"
        "libFLAC.dll"
        "libogg-0.dll"
        "libvorbis-0.dll"
        "libvorbisenc-2.dll"
        "libvorbisfile-3.dll"
        "libopus-0.dll"
        "libmp3lame-0.dll"
        "libmad-0.dll"
        "libfftw3f-3.dll"
        "libfftw3-3.dll"
        "libSoundTouch-1.dll"
    )

    # LV2 plugin libraries
    local lv2_dlls=(
        "liblilv-0-0.dll"
        "libserd-0-0.dll"
        "libsord-0-0.dll"
        "libsratom-0-0.dll"
        "libsuil-0-0.dll"
    )

    # Additional libraries
    local other_dlls=(
        "libboost_filesystem-mt.dll"
        "libboost_system-mt.dll"
        "libboost_thread-mt.dll"
        "libboost_date_time-mt.dll"
        "libboost_regex-mt.dll"
        "libboost_atomic-mt.dll"
        "libcurl-4.dll"
        "libxml2-2.dll"
        "libxslt-1.dll"
        "liblo-7.dll"
        "libtag.dll"
        "libvamp-sdk-2.dll"
        "libvamp-hostsdk-3.dll"
        "libaubio-5.dll"
        "libreadline8.dll"
        "libtermcap-0.dll"
        "liblzma-5.dll"
        "libzstd.dll"
        "libnghttp2-14.dll"
        "libssh2-1.dll"
        "libssl-3-x64.dll"
        "libcrypto-3-x64.dll"
        "libidn2-0.dll"
        "libunistring-5.dll"
        "libpsl-5.dll"
    )

    # Combine all DLL lists
    local all_dlls=(
        "${core_dlls[@]}"
        "${gtk_dlls[@]}"
        "${gtkmm_dlls[@]}"
        "${audio_dlls[@]}"
        "${lv2_dlls[@]}"
        "${other_dlls[@]}"
    )

    # Copy each DLL if it exists
    local copied=0
    local missing=0

    for dll in "${all_dlls[@]}"; do
        if [[ -f "$mingw_bin/$dll" ]]; then
            cp "$mingw_bin/$dll" "$PACKAGE_DIR/bin/"
            ((copied++))
        else
            # Try alternative names (version variations)
            local found=false
            for alt in "$mingw_bin/${dll%.dll}"*.dll; do
                if [[ -f "$alt" ]]; then
                    cp "$alt" "$PACKAGE_DIR/bin/"
                    ((copied++))
                    found=true
                    break
                fi
            done
            if [[ "$found" == "false" ]]; then
                log_warning "  Missing: $dll"
                ((missing++))
            fi
        fi
    done

    log_success "Copied $copied DLLs ($missing missing)"
}

# Copy GTK configuration and themes
copy_gtk_config() {
    log_status "Copying GTK configuration..."

    # GTK engines
    if [[ -d "/mingw64/lib/gtk-2.0" ]]; then
        mkdir -p "$PACKAGE_DIR/lib/gtk-2.0"
        cp -r /mingw64/lib/gtk-2.0/* "$PACKAGE_DIR/lib/gtk-2.0/" 2>/dev/null || true
    fi

    # GDK pixbuf loaders
    if [[ -d "/mingw64/lib/gdk-pixbuf-2.0" ]]; then
        mkdir -p "$PACKAGE_DIR/lib/gdk-pixbuf-2.0"
        cp -r /mingw64/lib/gdk-pixbuf-2.0/* "$PACKAGE_DIR/lib/gdk-pixbuf-2.0/" 2>/dev/null || true
    fi

    # Pango modules
    if [[ -d "/mingw64/lib/pango" ]]; then
        mkdir -p "$PACKAGE_DIR/lib/pango"
        cp -r /mingw64/lib/pango/* "$PACKAGE_DIR/lib/pango/" 2>/dev/null || true
    fi

    # GTK themes and icons
    if [[ -d "/mingw64/share/themes" ]]; then
        mkdir -p "$PACKAGE_DIR/share/themes"
        cp -r /mingw64/share/themes/* "$PACKAGE_DIR/share/themes/" 2>/dev/null || true
    fi

    if [[ -d "/mingw64/share/icons" ]]; then
        mkdir -p "$PACKAGE_DIR/share/icons"
        # Copy essential icon themes
        for theme in hicolor Adwaita; do
            if [[ -d "/mingw64/share/icons/$theme" ]]; then
                cp -r "/mingw64/share/icons/$theme" "$PACKAGE_DIR/share/icons/" 2>/dev/null || true
            fi
        done
    fi

    # Fontconfig
    if [[ -d "/mingw64/etc/fonts" ]]; then
        mkdir -p "$PACKAGE_DIR/etc/fonts"
        cp -r /mingw64/etc/fonts/* "$PACKAGE_DIR/etc/fonts/" 2>/dev/null || true
    fi

    # GTK settings
    mkdir -p "$PACKAGE_DIR/etc/gtk-2.0"
    cat > "$PACKAGE_DIR/etc/gtk-2.0/gtkrc" << 'EOF'
gtk-theme-name = "MS-Windows"
gtk-icon-theme-name = "hicolor"
gtk-font-name = "Segoe UI 9"
gtk-button-images = 0
gtk-menu-images = 0
EOF

    log_success "GTK configuration copied"
}

# Strip debug symbols from binaries
strip_binaries() {
    if [[ "$STRIP_BINARIES" != "yes" ]]; then
        log_status "Skipping binary stripping (STRIP_BINARIES=no)"
        return
    fi

    log_status "Stripping debug symbols..."

    find "$PACKAGE_DIR" -name "*.exe" -o -name "*.dll" | while read binary; do
        strip --strip-unneeded "$binary" 2>/dev/null || true
    done

    log_success "Binaries stripped"
}

# Create launcher script
create_launcher() {
    log_status "Creating launcher..."

    cat > "$PACKAGE_DIR/Ardour.bat" << 'EOF'
@echo off
setlocal

rem Set up paths
set "ARDOUR_DIR=%~dp0"
set "PATH=%ARDOUR_DIR%bin;%PATH%"
set "GTK_PATH=%ARDOUR_DIR%lib\gtk-2.0"
set "GDK_PIXBUF_MODULE_FILE=%ARDOUR_DIR%lib\gdk-pixbuf-2.0\2.10.0\loaders.cache"
set "FONTCONFIG_FILE=%ARDOUR_DIR%etc\fonts\fonts.conf"

rem Launch Ardour
start "" "%ARDOUR_DIR%bin\ardour.exe" %*
EOF

    log_success "Launcher created"
}

# Create NSIS installer (optional)
create_installer() {
    if [[ "$CREATE_INSTALLER" != "yes" ]]; then
        log_status "Skipping installer creation (CREATE_INSTALLER=no)"
        return
    fi

    if ! command -v makensis &>/dev/null; then
        log_warning "NSIS not found, skipping installer creation"
        return
    fi

    log_status "Creating NSIS installer..."

    local version=$(get_version)

    # Use Ardour's NSIS scripts if available
    if [[ -d "$ARDOUR_DIR/tools/x-win/nsis" ]]; then
        log_status "Using Ardour's NSIS configuration"
        # This would require adaptation of the official NSIS scripts
        log_warning "NSIS installer creation requires manual configuration"
    else
        log_warning "NSIS scripts not found"
    fi
}

# Create ZIP archive
create_archive() {
    log_status "Creating ZIP archive..."

    local version=$(get_version)
    local archive_name="Ardour-$version-win64.zip"

    cd "$OUTPUT_DIR"

    if command -v 7z &>/dev/null; then
        7z a -tzip "$archive_name" "$(basename $PACKAGE_DIR)" -mx=9
    else
        zip -r "$archive_name" "$(basename $PACKAGE_DIR)"
    fi

    log_success "Created: $OUTPUT_DIR/$archive_name"
}

# Show package summary
show_summary() {
    echo ""
    echo "========================================"
    echo "  Package Summary                      "
    echo "========================================"
    echo ""

    local version=$(get_version)

    log_success "Package created: $PACKAGE_DIR"
    echo ""
    echo "Contents:"
    echo "  - Ardour executable and libraries"
    echo "  - MinGW runtime DLLs"
    echo "  - GTK themes and configuration"
    echo "  - Launcher script (Ardour.bat)"
    echo ""

    # Show package size
    local size=$(du -sh "$PACKAGE_DIR" 2>/dev/null | cut -f1)
    echo "Total size: $size"
    echo ""

    echo "To run Ardour:"
    echo "  1. Extract to desired location"
    echo "  2. Run Ardour.bat"
    echo ""
}

# Show help
show_help() {
    echo "Ardour Windows Build - Package Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -o, --output DIR   Output directory (default: ../Export)"
    echo "  -i, --installer    Create NSIS installer"
    echo "  --no-strip         Don't strip debug symbols"
    echo "  --no-archive       Don't create ZIP archive"
    echo ""
    echo "Environment variables:"
    echo "  OUTPUT_DIR         Output directory"
    echo "  CREATE_INSTALLER   Set to 'yes' to create installer"
    echo "  STRIP_BINARIES     Set to 'no' to keep debug symbols"
    echo ""
}

# Parse command line arguments
CREATE_ARCHIVE="yes"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -i|--installer)
                CREATE_INSTALLER="yes"
                shift
                ;;
            --no-strip)
                STRIP_BINARIES="no"
                shift
                ;;
            --no-archive)
                CREATE_ARCHIVE="no"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main
main() {
    echo ""
    echo "========================================"
    echo "  Ardour Windows Build - Package       "
    echo "========================================"
    echo ""

    parse_args "$@"
    check_environment
    create_output_dirs
    copy_ardour_files
    copy_mingw_dlls
    copy_gtk_config
    strip_binaries
    create_launcher
    create_installer

    if [[ "$CREATE_ARCHIVE" == "yes" ]]; then
        create_archive
    fi

    show_summary
}

main "$@"

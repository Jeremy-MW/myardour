#!/bin/bash
# Ardour Windows Build - Dependency Installation Script
# This script installs all required packages for building Ardour on MSYS2/MinGW64

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_status() {
    echo -e "${CYAN}[DEPS]${NC} $1"
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

# Check we're running in MinGW64 environment
check_environment() {
    if [[ "$MSYSTEM" != "MINGW64" ]]; then
        log_error "This script must be run from MSYS2 MinGW64 shell"
        log_error "Current MSYSTEM: $MSYSTEM"
        log_error "Please run: C:\\msys64\\msys2_shell.cmd -mingw64"
        exit 1
    fi
    log_success "Running in MinGW64 environment"
}

# Update package database
update_packages() {
    log_status "Updating package database..."
    pacman -Sy --noconfirm
    log_success "Package database updated"
}

# Install a package group
install_packages() {
    local group_name="$1"
    shift
    local packages=("$@")

    log_status "Installing $group_name..."

    for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "  - $pkg (already installed)"
        else
            echo "  - Installing $pkg..."
            pacman -S --noconfirm --needed "$pkg" || {
                log_warning "Failed to install $pkg, continuing..."
            }
        fi
    done

    log_success "$group_name installed"
}

# Main installation
main() {
    echo ""
    echo "========================================"
    echo "  Ardour Windows Build - Dependencies  "
    echo "========================================"
    echo ""

    check_environment
    update_packages

    # ====================
    # Build Tools
    # ====================
    install_packages "Build Tools" \
        mingw-w64-x86_64-toolchain \
        mingw-w64-x86_64-cmake \
        mingw-w64-x86_64-meson \
        mingw-w64-x86_64-ninja \
        mingw-w64-x86_64-pkg-config \
        base-devel \
        autoconf \
        automake \
        libtool \
        make \
        patch \
        git \
        wget \
        tar \
        gzip \
        unzip

    # ====================
    # Python (required for waf)
    # ====================
    install_packages "Python" \
        mingw-w64-x86_64-python \
        mingw-w64-x86_64-python-pip \
        mingw-w64-x86_64-python-setuptools

    # ====================
    # Core Libraries
    # ====================
    install_packages "Core Libraries" \
        mingw-w64-x86_64-boost \
        mingw-w64-x86_64-glib2 \
        mingw-w64-x86_64-glibmm \
        mingw-w64-x86_64-libsigc++ \
        mingw-w64-x86_64-libxml2 \
        mingw-w64-x86_64-libxslt \
        mingw-w64-x86_64-curl \
        mingw-w64-x86_64-fftw \
        mingw-w64-x86_64-zlib \
        mingw-w64-x86_64-readline \
        mingw-w64-x86_64-dlfcn \
        mingw-w64-x86_64-icu

    # ====================
    # GTK2 Stack
    # ====================
    install_packages "GTK2 Stack" \
        mingw-w64-x86_64-gtk2 \
        mingw-w64-x86_64-gtkmm \
        mingw-w64-x86_64-cairo \
        mingw-w64-x86_64-cairomm \
        mingw-w64-x86_64-pango \
        mingw-w64-x86_64-pangomm \
        mingw-w64-x86_64-atk \
        mingw-w64-x86_64-atkmm \
        mingw-w64-x86_64-gdk-pixbuf2 \
        mingw-w64-x86_64-harfbuzz \
        mingw-w64-x86_64-freetype \
        mingw-w64-x86_64-fontconfig \
        mingw-w64-x86_64-pixman \
        mingw-w64-x86_64-shared-mime-info \
        mingw-w64-x86_64-gtk-engines \
        mingw-w64-x86_64-adwaita-icon-theme

    # ====================
    # Audio Libraries
    # ====================
    install_packages "Audio Libraries" \
        mingw-w64-x86_64-libsndfile \
        mingw-w64-x86_64-libsamplerate \
        mingw-w64-x86_64-rubberband \
        mingw-w64-x86_64-portaudio \
        mingw-w64-x86_64-flac \
        mingw-w64-x86_64-libogg \
        mingw-w64-x86_64-libvorbis \
        mingw-w64-x86_64-opus \
        mingw-w64-x86_64-lame \
        mingw-w64-x86_64-libmad \
        mingw-w64-x86_64-soundtouch \
        mingw-w64-x86_64-libusb

    # ====================
    # LV2 Plugin Stack
    # ====================
    install_packages "LV2 Plugin Stack" \
        mingw-w64-x86_64-lv2 \
        mingw-w64-x86_64-serd \
        mingw-w64-x86_64-sord \
        mingw-w64-x86_64-sratom \
        mingw-w64-x86_64-lilv \
        mingw-w64-x86_64-suil

    # ====================
    # Additional Audio Tools
    # ====================
    install_packages "Additional Audio Tools" \
        mingw-w64-x86_64-vamp-plugin-sdk \
        mingw-w64-x86_64-aubio \
        mingw-w64-x86_64-liblo \
        mingw-w64-x86_64-taglib

    # ====================
    # Optional: Testing
    # ====================
    install_packages "Testing Tools" \
        mingw-w64-x86_64-cppunit

    # ====================
    # Windows-specific libraries
    # ====================
    install_packages "Windows Support" \
        mingw-w64-x86_64-drmingw

    # ====================
    # Optional: NSIS for installers
    # ====================
    install_packages "NSIS Installer Tools" \
        mingw-w64-x86_64-nsis

    # ====================
    # Optional: JACK (unsupported on Windows but can be built)
    # ====================
    # Note: JACK on Windows requires separate installation of JACK2
    # We'll use PortAudio as the primary backend instead

    echo ""
    log_success "All dependencies installed!"
    echo ""

    # Verify critical packages
    log_status "Verifying critical packages..."

    local missing_packages=()

    # Check for essential packages
    for pkg in gcc g++ pkg-config python3; do
        if ! command -v $pkg &>/dev/null; then
            missing_packages+=("$pkg")
        fi
    done

    # Check for pkg-config libraries
    local required_libs=(
        "gtk+-2.0"
        "gtkmm-2.4"
        "glib-2.0"
        "glibmm-2.4"
        "cairo"
        "cairomm-1.0"
        "sndfile"
        "samplerate"
        "fftw3f"
        "lilv-0"
        "rubberband"
        "portaudio-2.0"
    )

    for lib in "${required_libs[@]}"; do
        if ! pkg-config --exists "$lib" 2>/dev/null; then
            missing_packages+=("$lib (pkg-config)")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warning "Some packages may be missing:"
        for pkg in "${missing_packages[@]}"; do
            echo "  - $pkg"
        done
        echo ""
        log_warning "The build may still succeed, but check for errors"
    else
        log_success "All critical packages verified"
    fi

    echo ""
    echo "========================================"
    echo "  Dependency installation complete!    "
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "  1. Run ./configure.sh to configure Ardour"
    echo "  2. Run ./build.sh to compile Ardour"
    echo "  3. Run ./package.sh to create distribution"
    echo ""
    echo "Or run ./build-all.sh to do everything at once"
    echo ""
}

# Run main function
main "$@"

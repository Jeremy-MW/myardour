#!/bin/bash
# Ardour Windows Build - Configure Script
# This script configures Ardour for building on MSYS2/MinGW64

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_status() {
    echo -e "${CYAN}[CONFIG]${NC} $1"
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

# Configuration options
BUILD_TYPE="${BUILD_TYPE:-release}"  # release or debug
WITH_JACK="${WITH_JACK:-no}"         # Enable JACK backend (requires JACK2 installed)
WITH_TESTS="${WITH_TESTS:-no}"       # Build unit tests

# Check environment
check_environment() {
    if [[ "$MSYSTEM" != "MINGW64" ]]; then
        log_error "This script must be run from MSYS2 MinGW64 shell"
        exit 1
    fi

    if [[ ! -f "$ARDOUR_DIR/wscript" ]]; then
        log_error "Ardour source not found at $ARDOUR_DIR"
        log_error "Make sure the ardour submodule is initialized:"
        log_error "  git submodule update --init --recursive"
        exit 1
    fi

    log_success "Environment check passed"
}

# Build configuration flags
build_config_flags() {
    local flags=""

    # Force GCC/G++ compiler (not MSVC) - must come first
    flags+=" --check-c-compiler=gcc"
    flags+=" --check-cxx-compiler=g++"

    # Target platform
    flags+=" --dist-target=mingw"

    # Installation prefix
    flags+=" --prefix=/mingw64"
    flags+=" --configdir=/mingw64/share"

    # Audio backends
    if [[ "$WITH_JACK" == "yes" ]]; then
        flags+=" --with-backends=jack,dummy,portaudio"
    else
        flags+=" --with-backends=dummy,portaudio"
    fi

    # Build type
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        flags+=" --debug"
        log_status "Building DEBUG configuration"
    else
        flags+=" --optimize"
        log_status "Building RELEASE configuration"
    fi

    # Tests
    if [[ "$WITH_TESTS" == "yes" ]]; then
        flags+=" --test"
    fi

    # Disable phone home for self-builds
    flags+=" --no-phone-home"

    # Skip freedesktop on Windows (Linux desktop integration, needs itstool)
    # flags+=" --freedesktop"

    # Keep existing flags from environment
    flags+=" --keepflags"

    # Program name (use Ardour for official builds)
    flags+=" --program-name=Ardour"

    echo "$flags"
}

# Generate revision.cc from git info
generate_revision() {
    log_status "Generating revision.cc..."

    cd "$ARDOUR_DIR"

    local rev=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    local date_str=$(git log -1 --format='%Y-%m-%d')

    # Format must match what wscript's fetch_tarball_revision_date() expects:
    # Line 1: #include "ardour/revision.h"
    # Line 2: namespace ARDOUR { const char* revision = "REV"; const char* date = "DATE"; }
    cat > libs/ardour/revision.cc << EOF
#include "ardour/revision.h"
namespace ARDOUR { const char* revision = "$rev"; const char* date = "$date_str"; }
EOF

    log_success "Generated revision.cc: $rev"
}

# Run waf configure
run_configure() {
    log_status "Configuring Ardour..."

    cd "$ARDOUR_DIR"

    # Generate revision.cc first (needed for proper version detection)
    generate_revision

    # Force MinGW GCC/G++ (not MSVC) - use full path with .exe extension
    export CC="/mingw64/bin/gcc.exe"
    export CXX="/mingw64/bin/g++.exe"
    export AR="/mingw64/bin/ar.exe"
    export RANLIB="/mingw64/bin/ranlib.exe"

    # Set up compiler flags for MinGW
    # -mstackrealign is needed for SSE on Windows
    export CFLAGS="${CFLAGS:--mstackrealign -O2}"
    export CXXFLAGS="${CXXFLAGS:--mstackrealign -O2}"
    export LDFLAGS="${LDFLAGS:-}"

    # Ensure pkg-config finds our libraries
    export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:/mingw64/share/pkgconfig:$PKG_CONFIG_PATH"

    # Clean any previous build config that might have cached MSVC
    rm -f build/c4che/_cache.py 2>/dev/null || true

    # Get configuration flags
    local config_flags=$(build_config_flags)

    log_status "Running: python waf configure $config_flags"
    echo ""

    # Run waf configure
    python waf configure $config_flags

    if [[ $? -eq 0 ]]; then
        echo ""
        log_success "Configuration complete!"
        log_status "Build directory: $ARDOUR_DIR/build"
        log_status "Run ./build.sh to compile Ardour"
    else
        log_error "Configuration failed"
        exit 1
    fi
}

# Show help
show_help() {
    echo "Ardour Windows Build - Configure Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -d, --debug     Build debug configuration"
    echo "  -r, --release   Build release configuration (default)"
    echo "  --with-jack     Enable JACK audio backend"
    echo "  --with-tests    Build unit tests"
    echo ""
    echo "Environment variables:"
    echo "  BUILD_TYPE      Set to 'debug' or 'release'"
    echo "  WITH_JACK       Set to 'yes' to enable JACK"
    echo "  WITH_TESTS      Set to 'yes' to build tests"
    echo "  CFLAGS          Additional C compiler flags"
    echo "  CXXFLAGS        Additional C++ compiler flags"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--debug)
                BUILD_TYPE="debug"
                shift
                ;;
            -r|--release)
                BUILD_TYPE="release"
                shift
                ;;
            --with-jack)
                WITH_JACK="yes"
                shift
                ;;
            --with-tests)
                WITH_TESTS="yes"
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
    echo "  Ardour Windows Build - Configure     "
    echo "========================================"
    echo ""

    parse_args "$@"
    check_environment
    run_configure
}

main "$@"

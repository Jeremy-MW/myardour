#!/bin/bash
# Ardour Windows Build - Build Script
# This script compiles Ardour on MSYS2/MinGW64

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_status() {
    echo -e "${CYAN}[BUILD]${NC} $1"
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

# Build options
JOBS="${JOBS:-$(nproc)}"
VERBOSE="${VERBOSE:-no}"
BUILD_I18N="${BUILD_I18N:-yes}"

# Check environment
check_environment() {
    if [[ "$MSYSTEM" != "MINGW64" ]]; then
        log_error "This script must be run from MSYS2 MinGW64 shell"
        exit 1
    fi

    if [[ ! -f "$ARDOUR_DIR/wscript" ]]; then
        log_error "Ardour source not found at $ARDOUR_DIR"
        exit 1
    fi

    # Check if configured
    if [[ ! -d "$ARDOUR_DIR/build" ]]; then
        log_error "Ardour is not configured. Run ./configure.sh first"
        exit 1
    fi

    log_success "Environment check passed"
}

# Run the build
run_build() {
    log_status "Building Ardour with $JOBS parallel jobs..."

    cd "$ARDOUR_DIR"

    # Build arguments
    local build_args="-j$JOBS"

    if [[ "$VERBOSE" == "yes" ]]; then
        build_args+=" -v"
    fi

    # Measure build time
    local start_time=$(date +%s)

    # Run waf build
    log_status "Running: python waf $build_args"
    echo ""

    python waf $build_args

    local build_result=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ $build_result -eq 0 ]]; then
        echo ""
        log_success "Build completed in $((duration / 60))m $((duration % 60))s"
    else
        log_error "Build failed after $((duration / 60))m $((duration % 60))s"
        exit 1
    fi
}

# Build translations
build_i18n() {
    if [[ "$BUILD_I18N" != "yes" ]]; then
        log_status "Skipping translations (BUILD_I18N=no)"
        return
    fi

    log_status "Building translations..."

    cd "$ARDOUR_DIR"

    python waf i18n

    if [[ $? -eq 0 ]]; then
        log_success "Translations built"
    else
        log_warning "Failed to build translations, continuing..."
    fi
}

# Show build summary
show_summary() {
    echo ""
    echo "========================================"
    echo "  Build Summary                        "
    echo "========================================"
    echo ""

    cd "$ARDOUR_DIR"

    # Check for built executables
    local exe_dir="$ARDOUR_DIR/build/gtk2_ardour"

    if [[ -f "$exe_dir/ardour.exe" ]] || [[ -f "$exe_dir/ardour-*.exe" ]]; then
        log_success "Ardour executable built successfully"

        # List built executables
        echo ""
        echo "Built executables:"
        find "$ARDOUR_DIR/build" -name "*.exe" -type f 2>/dev/null | while read exe; do
            echo "  - $exe"
        done
    else
        log_warning "Ardour executable not found in expected location"
        log_status "Check $ARDOUR_DIR/build for build outputs"
    fi

    echo ""
    echo "Next steps:"
    echo "  - Run ./package.sh to create a distribution"
    echo "  - Or run Ardour directly from the build directory"
    echo ""
}

# Clean build
clean_build() {
    log_status "Cleaning build directory..."

    cd "$ARDOUR_DIR"

    python waf clean

    log_success "Build directory cleaned"
}

# Show help
show_help() {
    echo "Ardour Windows Build - Build Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -c, --clean     Clean build directory before building"
    echo "  -v, --verbose   Enable verbose build output"
    echo "  -j JOBS         Number of parallel jobs (default: auto)"
    echo "  --no-i18n       Skip building translations"
    echo ""
    echo "Environment variables:"
    echo "  JOBS            Number of parallel jobs"
    echo "  VERBOSE         Set to 'yes' for verbose output"
    echo "  BUILD_I18N      Set to 'no' to skip translations"
    echo ""
}

# Parse command line arguments
DO_CLEAN="no"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                DO_CLEAN="yes"
                shift
                ;;
            -v|--verbose)
                VERBOSE="yes"
                shift
                ;;
            -j)
                JOBS="$2"
                shift 2
                ;;
            --no-i18n)
                BUILD_I18N="no"
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
    echo "  Ardour Windows Build - Compile       "
    echo "========================================"
    echo ""

    parse_args "$@"
    check_environment

    if [[ "$DO_CLEAN" == "yes" ]]; then
        clean_build
    fi

    run_build
    build_i18n
    show_summary
}

main "$@"

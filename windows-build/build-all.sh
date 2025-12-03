#!/bin/bash
# Ardour Windows Build - Master Build Script
# This script orchestrates the complete build process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_status() {
    echo -e "${CYAN}[MAIN]${NC} $1"
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

log_header() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build options
SKIP_DEPS="${SKIP_DEPS:-no}"
SKIP_CONFIGURE="${SKIP_CONFIGURE:-no}"
SKIP_BUILD="${SKIP_BUILD:-no}"
SKIP_PACKAGE="${SKIP_PACKAGE:-no}"
BUILD_TYPE="${BUILD_TYPE:-release}"
CLEAN_BUILD="${CLEAN_BUILD:-no}"

# Timing
TOTAL_START_TIME=$(date +%s)

# Check environment
check_environment() {
    log_header "Environment Check"

    if [[ "$MSYSTEM" != "MINGW64" ]]; then
        log_error "This script must be run from MSYS2 MinGW64 shell"
        log_error "Current MSYSTEM: $MSYSTEM"
        echo ""
        log_status "To start MinGW64 shell:"
        log_status "  C:\\msys64\\msys2_shell.cmd -mingw64"
        exit 1
    fi

    log_success "Running in MinGW64 environment"

    # Check for git submodule
    if [[ ! -f "$SCRIPT_DIR/../ardour/wscript" ]]; then
        log_error "Ardour source not found!"
        log_status "Initialize the submodule:"
        log_status "  git submodule update --init --recursive"
        exit 1
    fi

    log_success "Ardour source found"

    # Check for required tools
    local required_tools=(gcc g++ python3 pkg-config)
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warning "Missing tools: ${missing_tools[*]}"
        log_status "Run dependency installation first"
    else
        log_success "Required tools available"
    fi

    echo ""
}

# Install dependencies
install_dependencies() {
    if [[ "$SKIP_DEPS" == "yes" ]]; then
        log_status "Skipping dependency installation (SKIP_DEPS=yes)"
        return
    fi

    log_header "Installing Dependencies"

    local start_time=$(date +%s)

    bash "$SCRIPT_DIR/install-deps.sh"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Dependencies installed in $((duration / 60))m $((duration % 60))s"
}

# Configure Ardour
configure_ardour() {
    if [[ "$SKIP_CONFIGURE" == "yes" ]]; then
        log_status "Skipping configuration (SKIP_CONFIGURE=yes)"
        return
    fi

    log_header "Configuring Ardour"

    local start_time=$(date +%s)

    local config_args=""
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        config_args="--debug"
    fi

    bash "$SCRIPT_DIR/configure.sh" $config_args

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Configuration completed in $((duration / 60))m $((duration % 60))s"
}

# Build Ardour
build_ardour() {
    if [[ "$SKIP_BUILD" == "yes" ]]; then
        log_status "Skipping build (SKIP_BUILD=yes)"
        return
    fi

    log_header "Building Ardour"

    local start_time=$(date +%s)

    local build_args=""
    if [[ "$CLEAN_BUILD" == "yes" ]]; then
        build_args="--clean"
    fi

    bash "$SCRIPT_DIR/build.sh" $build_args

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Build completed in $((duration / 60))m $((duration % 60))s"
}

# Package Ardour
package_ardour() {
    if [[ "$SKIP_PACKAGE" == "yes" ]]; then
        log_status "Skipping packaging (SKIP_PACKAGE=yes)"
        return
    fi

    log_header "Packaging Ardour"

    local start_time=$(date +%s)

    bash "$SCRIPT_DIR/package.sh"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Packaging completed in $((duration / 60))m $((duration % 60))s"
}

# Show final summary
show_summary() {
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - TOTAL_START_TIME))

    log_header "Build Complete!"

    echo "Total build time: $((total_duration / 60))m $((total_duration % 60))s"
    echo ""

    # Check for output
    local output_dir="$SCRIPT_DIR/../Export"
    if [[ -d "$output_dir" ]]; then
        echo "Output location: $output_dir"
        echo ""
        echo "Contents:"
        ls -la "$output_dir" 2>/dev/null || true
    fi

    echo ""
    log_success "Ardour Windows build completed successfully!"
    echo ""
}

# Show help
show_help() {
    echo "Ardour Windows Build - Master Build Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -c, --clean       Clean build (rebuild from scratch)"
    echo "  -d, --debug       Build debug configuration"
    echo "  -r, --release     Build release configuration (default)"
    echo "  --skip-deps       Skip dependency installation"
    echo "  --skip-configure  Skip configuration step"
    echo "  --skip-build      Skip build step"
    echo "  --skip-package    Skip packaging step"
    echo "  --deps-only       Only install dependencies"
    echo "  --configure-only  Only run configuration"
    echo "  --build-only      Only run build (skip deps, configure, package)"
    echo ""
    echo "Environment variables:"
    echo "  BUILD_TYPE        'debug' or 'release'"
    echo "  SKIP_DEPS         'yes' to skip dependency installation"
    echo "  SKIP_CONFIGURE    'yes' to skip configuration"
    echo "  SKIP_BUILD        'yes' to skip build"
    echo "  SKIP_PACKAGE      'yes' to skip packaging"
    echo "  CLEAN_BUILD       'yes' to clean before building"
    echo "  JOBS              Number of parallel build jobs"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full build"
    echo "  $0 --debug            # Debug build"
    echo "  $0 --clean            # Clean rebuild"
    echo "  $0 --skip-deps        # Skip deps if already installed"
    echo "  $0 --build-only       # Just rebuild (after changes)"
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
            -c|--clean)
                CLEAN_BUILD="yes"
                shift
                ;;
            -d|--debug)
                BUILD_TYPE="debug"
                shift
                ;;
            -r|--release)
                BUILD_TYPE="release"
                shift
                ;;
            --skip-deps)
                SKIP_DEPS="yes"
                shift
                ;;
            --skip-configure)
                SKIP_CONFIGURE="yes"
                shift
                ;;
            --skip-build)
                SKIP_BUILD="yes"
                shift
                ;;
            --skip-package)
                SKIP_PACKAGE="yes"
                shift
                ;;
            --deps-only)
                SKIP_CONFIGURE="yes"
                SKIP_BUILD="yes"
                SKIP_PACKAGE="yes"
                shift
                ;;
            --configure-only)
                SKIP_DEPS="yes"
                SKIP_BUILD="yes"
                SKIP_PACKAGE="yes"
                shift
                ;;
            --build-only)
                SKIP_DEPS="yes"
                SKIP_CONFIGURE="yes"
                SKIP_PACKAGE="yes"
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
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                                        ║${NC}"
    echo -e "${MAGENTA}║   Ardour Windows Build System          ║${NC}"
    echo -e "${MAGENTA}║   MSYS2/MinGW64 Native Build           ║${NC}"
    echo -e "${MAGENTA}║                                        ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""

    parse_args "$@"

    log_status "Build type: $BUILD_TYPE"
    if [[ "$CLEAN_BUILD" == "yes" ]]; then
        log_status "Clean build: enabled"
    fi
    echo ""

    check_environment
    install_dependencies
    configure_ardour
    build_ardour
    package_ardour
    show_summary
}

main "$@"

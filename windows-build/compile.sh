#!/bin/bash
#
# Compile Ardour for Windows using the pre-built dependency stack
#
# Usage: ./compile.sh [x86_64|i686]
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARDOUR_SRC="$SCRIPT_DIR/../ardour"

# Check Ardour source exists
if [ ! -f "$ARDOUR_SRC/gtk2_ardour/wscript" ]; then
    echo "Error: Ardour source not found at $ARDOUR_SRC"
    exit 1
fi

cd "$ARDOUR_SRC"

# Default to 64-bit
XARCH=${1:-x86_64}
: ${ROOT=/home/ardour}
: ${MAKEFLAGS=-j$(nproc)}

if test "$XARCH" = "x86_64" -o "$XARCH" = "amd64"; then
    echo "Target: 64-bit Windows (x86_64)"
    XPREFIX=x86_64-w64-mingw32
    WARCH=w64
else
    echo "Target: 32-bit Windows (i686)"
    XPREFIX=i686-w64-mingw32
    WARCH=w32
fi

PREFIX=${ROOT}/win-stack-$WARCH

# Check dependency stack
if [ ! -d "$PREFIX" ]; then
    echo "Error: Dependency stack not found at $PREFIX"
    echo "Please run build-deps.sh first"
    exit 1
fi

# Configure build options
# Remove --optimize for debug builds
# Add --freebie for free/demo version
if test -z "${ARDOURCFG}"; then
    if test -f ${PREFIX}/include/pa_asio.h; then
        ARDOURCFG="--windows-vst --ptformat --with-backends=jack,portaudio,dummy --optimize"
    else
        ARDOURCFG="--windows-vst --ptformat --with-backends=jack,dummy --optimize"
    fi
fi

echo "============================================="
echo "Compiling Ardour for Windows"
echo "============================================="
echo "Architecture: $XARCH"
echo "Prefix: $PREFIX"
echo "Config: $ARDOURCFG"
echo "============================================="

# Set up environment
unset PKG_CONFIG_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

export CC=${XPREFIX}-gcc
export CXX=${XPREFIX}-g++
export CPP=${XPREFIX}-cpp
export AR=${XPREFIX}-ar
export LD=${XPREFIX}-ld
export NM=${XPREFIX}-nm
export AS=${XPREFIX}-as
export STRIP=${XPREFIX}-strip
export WINRC=${XPREFIX}-windres
export RANLIB=${XPREFIX}-ranlib
export DLLTOOL=${XPREFIX}-dlltool

# Set optimization flags
if echo "$ARDOURCFG" | grep -q optimize; then
    OPT=""
else
    OPT=" -Og"
fi

echo "Configuring Ardour..."
CFLAGS="-mstackrealign$OPT" \
CXXFLAGS="-mstackrealign$OPT" \
LDFLAGS="-L${PREFIX}/lib" \
DEPSTACK_ROOT="$PREFIX" \
./waf configure \
    --keepflags \
    --dist-target=mingw \
    --also-include=${PREFIX}/include \
    $ARDOURCFG \
    --prefix=${PREFIX} \
    --libdir=${PREFIX}/lib

echo "Building Ardour..."
./waf ${MAKEFLAGS}

echo "Creating translations..."
./waf i18n

echo "============================================="
echo "Build complete!"
echo "============================================="

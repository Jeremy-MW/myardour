#!/bin/bash
#
# Build Ardour for Windows - Complete automated build
#
# This script performs the full build process:
# 1. Build dependency stack (if not already built)
# 2. Compile Ardour
# 3. Create Windows installer
#
# Usage: sudo ./build-all.sh [x86_64|i686]
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default to 64-bit
XARCH=${1:-x86_64}
: ${ROOT=/home/ardour}

if test "$XARCH" = "x86_64" -o "$XARCH" = "amd64"; then
    WARCH=w64
else
    WARCH=w32
fi

PREFIX=${ROOT}/win-stack-$WARCH

echo "============================================="
echo "Ardour Windows Build - Complete Process"
echo "============================================="
echo "Architecture: $XARCH"
echo "Prefix: $PREFIX"
echo "============================================="

START_TIME=$(date +%s)

# Step 1: Build dependencies (if needed)
if [ ! -d "$PREFIX" ]; then
    echo ""
    echo "[Step 1/3] Building dependency stack..."
    echo "This will take several hours..."
    echo ""
    cd "$SCRIPT_DIR"
    sudo bash build-deps.sh $XARCH
else
    echo ""
    echo "[Step 1/3] Dependency stack already exists, skipping..."
    echo ""
fi

# Step 2: Compile Ardour
echo ""
echo "[Step 2/3] Compiling Ardour..."
echo ""
cd "$SCRIPT_DIR"
bash compile.sh $XARCH

# Step 3: Package
echo ""
echo "[Step 3/3] Creating Windows installer..."
echo ""
cd "$SCRIPT_DIR/../ardour"
XARCH=$XARCH ROOT=$ROOT bash tools/x-win/package.sh

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "============================================="
echo "Build Complete!"
echo "============================================="
echo "Total time: $((DURATION / 3600))h $((DURATION % 3600 / 60))m $((DURATION % 60))s"
echo ""
echo "Installer location: /var/tmp/Ardour-*-${WARCH}-Setup.exe"
echo "============================================="

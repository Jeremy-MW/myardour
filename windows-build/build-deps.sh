#!/bin/bash
#
# Build all dependencies for Ardour Windows cross-compilation
# This script creates a Windows build environment on Linux
#
# Usage: sudo ./build-deps.sh [x86_64|i686]
#
# Based on: https://github.com/chapatt/ardour-build
# Original: ardour-build-tools/x-mingw.sh
#

set -e

# Default to 64-bit
XARCH=${1:-x86_64}

# Configuration
: ${MAKEFLAGS=-j$(nproc)}
: ${STACKCFLAGS="-O2 -g"}
: ${SRCDIR=/var/tmp/winsrc}
: ${TMPDIR=/var/tmp}
: ${ROOT=/home/ardour}

# Check for root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root (or with sudo)" 1>&2
    exit 1
fi

# Set architecture-specific variables
if test "$XARCH" = "x86_64" -o "$XARCH" = "amd64"; then
    echo "Target: 64-bit Windows (x86_64)"
    XPREFIX=x86_64-w64-mingw32
    HPREFIX=x86_64
    MFAMILY=x86_64
    MCPU=x86_64
    WARCH=w64
    BOOST_ADDRESS_MODEL=64
    DEBIANPKGS="mingw-w64"
else
    echo "Target: 32-bit Windows (i686)"
    XPREFIX=i686-w64-mingw32
    HPREFIX=i386
    WARCH=w32
    MFAMILY=x86
    MCPU=i686
    BOOST_ADDRESS_MODEL=32
    DEBIANPKGS="mingw-w64"
fi

PREFIX=${ROOT}/win-stack-$WARCH
BUILDD=${ROOT}/win-build-$WARCH

echo "============================================="
echo "Ardour Windows Dependency Builder"
echo "============================================="
echo "Architecture: $XARCH"
echo "Prefix: $PREFIX"
echo "Build dir: $BUILDD"
echo "Source cache: $SRCDIR"
echo "============================================="

# Install system dependencies
echo "[1/5] Installing system packages..."
apt-get -y update
apt-get -y install build-essential \
    ${DEBIANPKGS} \
    git autoconf automake libtool pkg-config \
    curl wget unzip ed yasm cmake ca-certificates \
    nsis subversion ocaml-nox gperf meson python3 python-is-python3 \
    libglib2.0-dev

# Configure MinGW alternatives for POSIX threads
echo "[2/5] Configuring MinGW toolchain..."
update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix 2>/dev/null || true
update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix 2>/dev/null || true
update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix 2>/dev/null || true
update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix 2>/dev/null || true

# Set up ccache if available
if test -d /usr/lib/ccache -a -f /usr/bin/ccache; then
    export PATH="/usr/lib/ccache:${PATH}"
    cd /usr/lib/ccache
    test -L ${XPREFIX}-gcc || ln -s ../../bin/ccache ${XPREFIX}-gcc
    test -L ${XPREFIX}-g++ || ln -s ../../bin/ccache ${XPREFIX}-g++
    cd -
fi

# Clean and create directories
echo "[3/5] Setting up directories..."
rm -rf ${PREFIX}
rm -rf ${BUILDD}
mkdir -p ${SRCDIR}
mkdir -p ${BUILDD}
mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/include

# Set up environment
unset PKG_CONFIG_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export XPREFIX
export PREFIX
export SRCDIR
export PKG_CONFIG=/usr/bin/pkg-config

# Helper functions
download() {
    echo "--- Downloading: $2"
    test -f "${SRCDIR}/${1}" || curl -k -L -o "${SRCDIR}/${1}" $2
}

src() {
    download "${1}${4}.${2}" $3
    cd ${BUILDD}
    rm -rf $1
    tar xf "${SRCDIR}/${1}${4}.${2}"
    cd $1
}

autoconfconf() {
    set -e
    echo "======= $(pwd) ======="
    CPPFLAGS="-I${PREFIX}/include$CPPFLAGS" \
    CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -mstackrealign$CFLAGS" \
    CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -std=gnu++11 -mstackrealign$CXXFLAGS" \
    LDFLAGS="-L${PREFIX}/lib$LDFLAGS" \
    ./configure --host=${XPREFIX} --build=${HPREFIX}-linux \
    --prefix=$PREFIX "$@"
}

autoconfbuild() {
    set -e
    autoconfconf "$@"
    make $MAKEFLAGS && make install
}

wafbuild() {
    set -e
    echo "======= $(pwd) ======="
    CC=${XPREFIX}-gcc \
    CXX=${XPREFIX}-g++ \
    CPP=${XPREFIX}-cpp \
    AR=${XPREFIX}-ar \
    LD=${XPREFIX}-ld \
    NM=${XPREFIX}-nm \
    AS=${XPREFIX}-as \
    STRIP=${XPREFIX}-strip \
    RANLIB=${XPREFIX}-ranlib \
    DLLTOOL=${XPREFIX}-dlltool \
    CPPFLAGS="-I${PREFIX}/include$CPPFLAGS" \
    CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -mstackrealign$CFLAGS" \
    CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -std=gnu++11 -mstackrealign$CXXFLAGS" \
    LDFLAGS="-L${PREFIX}/lib$LDFLAGS" \
    ./waf configure --prefix=$PREFIX "$@" \
    && ./waf && ./waf install
}

# Create meson cross file
cat > ${BUILDD}/meson-cross.txt << EOF
[binaries]
c = '/usr/bin/${XPREFIX}-gcc'
cpp = '/usr/bin/${XPREFIX}-g++'
ld = '/usr/bin/${XPREFIX}-ld'
ar = '/usr/bin/${XPREFIX}-ar'
strip = '/usr/bin/${XPREFIX}-strip'
windres = '/usr/bin/${XPREFIX}-windres'
pkgconfig = '/usr/bin/pkg-config'

[properties]
c_args = ['-I${PREFIX}/include', '-O2', '-mstackrealign', '-Werror=format=0']
cpp_args = ['-I${PREFIX}/include', '-O2', '-mstackrealign', '-std=gnu++11']
c_link_args = ['-L${PREFIX}/lib']
cpp_link_args = ['-L${PREFIX}/lib']
sys_root = '$PREFIX'

[paths]
prefix = '$PREFIX'

[host_machine]
system = 'windows'
cpu_family = '$MFAMILY'
cpu = '$MCPU'
endian = 'little'
EOF

mesonbuild() {
    set -e
    meson build/ --cross-file ${BUILDD}/meson-cross.txt --prefix=$PREFIX --libdir=lib "$@"
    ninja -C build install ${CONCURRENCY}
}

echo "[4/5] Building dependencies (this will take several hours)..."

###############################################################################
# BUILD DEPENDENCIES
###############################################################################

# JACK headers and libraries
echo "Building: JACK..."
download jack_win3264.tar.xz http://ardour.org/files/deps/jack_win3264.tar.xz
cd "$PREFIX"
tar xf ${SRCDIR}/jack_win3264.tar.xz
"$PREFIX"/update_pc_prefix.sh ${WARCH} || true

# Dr. MinGW for crash reporting
download drmingw.tar.xz http://ardour.org/files/deps/drmingw.tar.xz
cd ${BUILDD}
rm -rf drmingw
tar xf ${SRCDIR}/drmingw.tar.xz
cp -av drmingw/$WARCH/* "$PREFIX"/ || true

# XZ Utils
echo "Building: xz..."
src xz-5.2.2 tar.bz2 http://tukaani.org/xz/xz-5.2.2.tar.bz2
autoconfbuild

# zlib
echo "Building: zlib..."
src zlib-1.2.7 tar.gz ftp://ftp.simplesystems.org/pub/libpng/png/src/history/zlib/zlib-1.2.7.tar.gz
make -fwin32/Makefile.gcc PREFIX=${XPREFIX}-
make install -fwin32/Makefile.gcc SHARED_MODE=1 \
    INCLUDE_PATH=${PREFIX}/include \
    LIBRARY_PATH=${PREFIX}/lib \
    BINARY_PATH=${PREFIX}/bin

# libtiff
echo "Building: libtiff..."
src tiff-4.0.3 tar.gz http://download.osgeo.org/libtiff/old/tiff-4.0.3.tar.gz
autoconfbuild

# libjpeg
echo "Building: libjpeg..."
download jpegsrc.v9a.tar.gz http://www.ijg.org/files/jpegsrc.v9a.tar.gz
cd ${BUILDD}
rm -rf jpeg-9a
tar xzf ${SRCDIR}/jpegsrc.v9a.tar.gz
cd jpeg-9a
autoconfbuild

# libogg
echo "Building: libogg..."
src libogg-1.3.2 tar.gz http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
autoconfbuild

# libvorbis
echo "Building: libvorbis..."
src libvorbis-1.3.4 tar.gz http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
autoconfbuild --disable-examples --with-ogg=${PREFIX}

# FLAC
echo "Building: FLAC..."
src flac-1.3.2 tar.xz http://downloads.xiph.org/releases/flac/flac-1.3.2.tar.xz
ed Makefile.in << EOF
%s/examples / /
wq
EOF
autoconfbuild

# libsndfile
echo "Building: libsndfile..."
src libsndfile-1.0.27 tar.gz http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz
sed -i 's/12292/24584/' src/common.h
ed Makefile.in << EOF
%s/ examples regtest tests programs//
wq
EOF
LDFLAGS=" -lFLAC -lwsock32 -lvorbis -logg -lwsock32" \
autoconfbuild
ed $PREFIX/lib/pkgconfig/sndfile.pc << EOF
%s/ -lsndfile/ -lsndfile -lvorbis -lvorbisenc -lFLAC -logg -lwsock32/
wq
EOF

# libsamplerate
echo "Building: libsamplerate..."
src libsamplerate-0.1.9 tar.gz http://www.mega-nerd.com/SRC/libsamplerate-0.1.9.tar.gz
ed Makefile.in << EOF
%s/ examples tests//
wq
EOF
autoconfbuild

# expat
echo "Building: expat..."
src expat-2.4.1 tar.gz https://sourceforge.net/projects/expat/files/expat/2.4.1/expat-2.4.1.tar.gz
autoconfbuild

# libiconv
echo "Building: libiconv..."
src libiconv-1.16 tar.gz http://ftpmirror.gnu.org/libiconv/libiconv-1.16.tar.gz
autoconfbuild --with-included-gettext --with-libiconv-prefix=$PREFIX

# libxml2
echo "Building: libxml2..."
src libxml2-2.9.2 tar.gz ftp://xmlsoft.org/libxslt/libxml2-2.9.2.tar.gz
CFLAGS=" -O0" CXXFLAGS=" -O0" \
autoconfbuild --with-threads=no --with-zlib=$PREFIX --without-python

# libpng
echo "Building: libpng..."
src libpng-1.6.37 tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz
autoconfbuild

# freetype
echo "Building: freetype..."
src freetype-2.9 tar.gz http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz
autoconfbuild -with-harfbuzz=no

# fontconfig
echo "Building: fontconfig..."
src fontconfig-2.13.1 tar.bz2 http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2
ed Makefile.in << EOF
%s/po-conf test/po-conf/
wq
EOF
autoconfbuild --enable-libxml2

# pixman
echo "Building: pixman..."
src pixman-0.38.4 tar.gz https://www.cairographics.org/releases/pixman-0.38.4.tar.gz
autoconfbuild

# cairo
echo "Building: cairo..."
src cairo-1.16.0 tar.xz http://cairographics.org/releases/cairo-1.16.0.tar.xz
ed Makefile.in << EOF
%s/ test perf//
wq
EOF
ax_cv_c_float_words_bigendian=no \
autoconfbuild --disable-gtk-doc-html --enable-gobject=no --disable-valgrind \
    --enable-interpreter=no --enable-script=no

# libffi
echo "Building: libffi..."
src libffi-3.1 tar.gz ftp://sourceware.org/pub/libffi/libffi-3.1.tar.gz
autoconfbuild

# gettext
echo "Building: gettext..."
src gettext-0.19.3 tar.gz http://ftpmirror.gnu.org/gettext/gettext-0.19.3.tar.gz
CFLAGS="-O2 -mstackrealign" CXXFLAGS="-O2 -mstackrealign" \
    ./configure --host=${XPREFIX} --build=${HPREFIX}-linux --prefix=$PREFIX "$@"
make $MAKEFLAGS && make install

# glib
echo "Building: glib..."
src glib-2.64.1 tar.xz http://ftp.gnome.org/pub/gnome/sources/glib/2.64/glib-2.64.1.tar.xz
mesonbuild -Dinternal_pcre=true

# harfbuzz
echo "Building: harfbuzz..."
src harfbuzz-2.6.4 tar.xz https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-2.6.4.tar.xz
autoconfbuild -without-icu --with-uniscribe

# fribidi
echo "Building: fribidi..."
src fribidi-1.0.9 tar.xz https://github.com/fribidi/fribidi/releases/download/v1.0.9/fribidi-1.0.9.tar.xz
mesonbuild -Ddocs=false

# pango
echo "Building: pango..."
src pango-1.42.4 tar.xz http://ftp.gnome.org/pub/GNOME/sources/pango/1.42/pango-1.42.4.tar.xz
mesonbuild -Dgir=false

# atk
echo "Building: atk..."
src atk-2.14.0 tar.bz2 http://ftp.gnome.org/pub/GNOME/sources/atk/2.14/atk-2.14.0.tar.xz
autoconfbuild --disable-rebuilds

# gdk-pixbuf
echo "Building: gdk-pixbuf..."
src gdk-pixbuf-2.31.1 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gdk-pixbuf/2.31/gdk-pixbuf-2.31.1.tar.xz
autoconfbuild --disable-modules --without-gdiplus --with-included-loaders=yes

# GTK+ 2.24
echo "Building: GTK+ 2.24..."
src gtk+-2.24.25 tar.xz http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.25.tar.xz
ed Makefile.in << EOF
%s/demos / /
wq
EOF
CFLAGS=" -Wno-deprecated-declarations" \
autoconfconf --disable-rebuilds
make && make install

# Clean up glib dev package to avoid conflicts
dpkg -P libglib2.0-dev libpcre3-dev 2>/dev/null || true

# LV2
echo "Building: LV2 stack..."
src lv2-1.18.2 tar.bz2 http://ardour.org/files/deps/lv2-1.18.2-g611759d.tar.bz2 -g611759d
wafbuild --no-plugins --copy-headers --lv2dir=$PREFIX/lib/lv2

export COMMONPROGRAMFILES="%COMMONPROGRAMFILES%"

src serd-0.30.11 tar.bz2 http://ardour.org/files/deps/serd-0.30.11-g36f1cecc.tar.bz2 -g36f1cecc
wafbuild

src sord-0.16.9 tar.bz2 http://ardour.org/files/deps/sord-0.16.9-gd2efdb2.tar.bz2 -gd2efdb2
wafbuild --no-utils

src sratom-0.6.8 tar.bz2 http://ardour.org/files/deps/sratom-0.6.8-gc46452c.tar.bz2 -gc46452c
wafbuild

src lilv-0.24.13 tar.bz2 http://ardour.org/files/deps/lilv-0.24.13-g71a2ff5.tar.bz2 -g71a2ff5
wafbuild --no-utils

src suil-0.10.8 tar.bz2 http://ardour.org/files/deps/suil-0.10.8-g05c2afb.tar.bz2 -g05c2afb
wafbuild

unset COMMONPROGRAMFILES

# curl
echo "Building: curl..."
src curl-7.66.0 tar.bz2 http://curl.haxx.se/download/curl-7.66.0.tar.bz2
autoconfbuild --with-winssl

# libsigc++
echo "Building: libsigc++..."
src libsigc++-2.10.2 tar.xz http://ftp.gnome.org/pub/GNOME/sources/libsigc++/2.10/libsigc++-2.10.2.tar.xz
autoconfbuild

# glibmm
echo "Building: glibmm..."
src glibmm-2.62.0 tar.xz http://ftp.gnome.org/pub/GNOME/sources/glibmm/2.62/glibmm-2.62.0.tar.xz
autoconfbuild

# cairomm
echo "Building: cairomm..."
src cairomm-1.13.1 tar.gz http://cairographics.org/releases/cairomm-1.13.1.tar.gz
autoconfbuild

# pangomm
echo "Building: pangomm..."
src pangomm-2.42.0 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/pangomm/2.42/pangomm-2.42.0.tar.xz
autoconfbuild

# atkmm
echo "Building: atkmm..."
src atkmm-2.22.7 tar.xz http://ftp.gnome.org/pub/GNOME/sources/atkmm/2.22/atkmm-2.22.7.tar.xz
autoconfbuild

# gtkmm
echo "Building: gtkmm..."
src gtkmm-2.24.5 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gtkmm/2.24/gtkmm-2.24.5.tar.xz
CXXFLAGS=" -Wno-deprecated-declarations -Wno-parentheses" \
autoconfbuild

# FFTW
echo "Building: FFTW..."
src fftw-3.3.8 tar.gz http://fftw.org/fftw-3.3.8.tar.gz
autoconfbuild --enable-single --enable-float --enable-sse --with-our-malloc --enable-avx --disable-mpi --enable-threads --with-combined-threads --disable-static --enable-shared
make clean
autoconfbuild --enable-type-prefix --with-our-malloc --enable-avx --disable-mpi --enable-threads --with-combined-threads --disable-static --enable-shared

# Boost
echo "Building: Boost..."
src boost_1_68_0 tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.68.0/boost_1_68_0.tar.bz2
./bootstrap.sh --prefix=$PREFIX

echo "using gcc : 8.2 : ${XPREFIX}-g++ :
<rc>${XPREFIX}-windres
<archiver>${XPREFIX}-ar
;" > user-config.jam

./b2 --prefix=$PREFIX \
    toolset=gcc \
    target-os=windows \
    architecture=x86 \
    address-model=$BOOST_ADDRESS_MODEL \
    variant=release \
    threading=multi \
    threadapi=win32 \
    link=shared \
    runtime-link=shared \
    cxxstd=11 \
    --with-exception \
    --with-regex \
    --with-atomic \
    --layout=tagged \
    --user-config=user-config.jam \
    $MAKEFLAGS install

# LADSPA header
echo "Installing: LADSPA header..."
download ladspa.h http://community.ardour.org/files/ladspa.h
cp ${SRCDIR}/ladspa.h $PREFIX/include/ladspa.h

# VAMP SDK
echo "Building: VAMP SDK..."
src vamp-plugin-sdk-2.8.0 tar.gz https://code.soundsoftware.ac.uk/attachments/download/2450/vamp-plugin-sdk-2.8.0.tar.gz
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
%s/= ranlib/= ${XPREFIX}-ranlib/
%s/vamp-simple-host$/vamp-simple-host.exe/
%s/vamp-rdf-template-generator$/vamp-rdf-template-generator.exe/
wq
EOF
ed src/vamp-hostsdk/Window.h << EOF
/cstdlib
+1i
#ifndef M_PI
#  define M_PI 3.14159265358979323846
#endif
.
wq
EOF
MAKEFLAGS="sdk -j4" autoconfbuild
ed $PREFIX/lib/pkgconfig/vamp-hostsdk.pc << EOF
%s/-ldl//
wq
EOF

# RubberBand
echo "Building: RubberBand..."
src rubberband-1.8.1 tar.bz2 http://code.breakfastquay.com/attachments/download/34/rubberband-1.8.1.tar.bz2
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
%s|bin/rubberband$|bin/rubberband.exe|
wq
EOF
autoconfbuild
ed $PREFIX/lib/pkgconfig/rubberband.pc << EOF
%s/ -lrubberband/ -lrubberband -lfftw3/
wq
EOF

# aubio
echo "Building: aubio..."
src aubio-0.3.2 tar.gz http://aubio.org/pub/aubio-0.3.2.tar.gz
ed Makefile.in << EOF
%s/examples / /
wq
EOF
autoconfbuild
ed $PREFIX/lib/pkgconfig/aubio.pc << EOF
%s/ -laubio/ -laubio -lfftw3f/
wq
EOF

# taglib
echo "Building: taglib..."
src taglib-1.9.1 tar.gz http://taglib.github.io/releases/taglib-1.9.1.tar.gz
ed CMakeLists.txt << EOF
0i
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_C_COMPILER ${XPREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${XPREFIX}-c++)
set(CMAKE_RC_COMPILER ${XPREFIX}-windres)
.
wq
EOF
sed -i 's/\~ListPrivate/virtual ~ListPrivate/' taglib/toolkit/tlist.tcc
rm -rf build/
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Windows -DZLIB_ROOT=$PREFIX \
    ..
make $MAKEFLAGS && make install

cat > $PREFIX/lib/pkgconfig/taglib.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: TagLib
Description: Audio meta-data library
Requires:
Version: 1.9.1
Libs: -L\${libdir}/lib -ltag
Cflags: -I\${includedir}/include/taglib
EOF

# liblo (OSC)
echo "Building: liblo..."
src liblo-0.28 tar.gz http://downloads.sourceforge.net/liblo/liblo-0.28.tar.gz
autoconfconf --enable-shared
ed src/Makefile << EOF
/noinst_PROGRAMS
.,+3d
wq
EOF
ed Makefile << EOF
%s/examples//
wq
EOF
make $MAKEFLAGS && make install

# libwebsockets
echo "Building: libwebsockets..."
src libwebsockets-4.0.15 tar.gz http://ardour.org/files/deps/libwebsockets-4.0.15.tar.gz
rm -rf build/
sed -i.bak 's%-Werror%%' CMakeLists.txt
mkdir build && cd build
cmake -DLWS_WITH_SSL=off -DLWS_WITH_EXTERNAL_POLL=yes \
    -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=`which ${XPREFIX}-gcc` -DCMAKE_RC_COMPILER=`which ${XPREFIX}-windres` \
    -DCMAKE_C_FLAGS="-isystem ${PREFIX}/include ${STACKCFLAGS} -mstackrealign" \
    -DLWS_WITHOUT_TEST_SERVER=on -DLWS_WITHOUT_TESTAPPS=on \
    -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release \
    ..
make $MAKEFLAGS && make install

cat > $PREFIX/lib/pkgconfig/libwebsockets.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libwebsockets
Description: Websockets server and client library
Version: 4.0.15

Libs: -L\${libdir} -lwebsockets
Cflags: -I\${includedir}
EOF

# libusb
echo "Building: libusb..."
src libusb-1.0.20 tar.bz2 http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.20/libusb-1.0.20.tar.bz2
(
  MAKEFLAGS= \
  autoconfbuild
)

# cppunit
echo "Building: cppunit..."
src cppunit-1.13.2 tar.gz http://dev-www.libreoffice.org/src/cppunit-1.13.2.tar.gz
autoconfbuild

echo "[5/5] Dependency stack complete!"
echo "============================================="
echo "Dependencies installed to: $PREFIX"
echo "============================================="

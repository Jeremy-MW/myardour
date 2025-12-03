#!/bin/bash
# Copy required MinGW DLLs to package directory

PACKAGE_DIR="/c/dev/myardour/Export/Ardour-9.0-rc1-6-g8ca808346a-win64"
MINGW_BIN="/mingw64/bin"

mkdir -p "$PACKAGE_DIR/bin"

# List of required DLLs
DLLS="
libgcc_s_seh-1.dll
libstdc++-6.dll
libwinpthread-1.dll
libgtk-win32-2.0-0.dll
libgdk-win32-2.0-0.dll
libgdk_pixbuf-2.0-0.dll
libglib-2.0-0.dll
libgmodule-2.0-0.dll
libgobject-2.0-0.dll
libgio-2.0-0.dll
libgthread-2.0-0.dll
libpango-1.0-0.dll
libpangocairo-1.0-0.dll
libpangoft2-1.0-0.dll
libpangowin32-1.0-0.dll
libcairo-2.dll
libcairo-gobject-2.dll
libatk-1.0-0.dll
libfontconfig-1.dll
libfreetype-6.dll
libharfbuzz-0.dll
libpixman-1-0.dll
libpng16-16.dll
zlib1.dll
libbz2-1.dll
libbrotlidec.dll
libbrotlicommon.dll
libintl-8.dll
libiconv-2.dll
libffi-8.dll
libpcre2-8-0.dll
libexpat-1.dll
libgtkmm-2.4-1.dll
libgdkmm-2.4-1.dll
libglibmm-2.4-1.dll
libgiomm-2.4-1.dll
libcairomm-1.0-1.dll
libpangomm-1.4-1.dll
libatkmm-1.6-1.dll
libsigc-2.0-0.dll
libsndfile-1.dll
libsamplerate-0.dll
librubberband-2.dll
libportaudio.dll
libFLAC.dll
libogg-0.dll
libvorbis-0.dll
libvorbisenc-2.dll
libvorbisfile-3.dll
libopus-0.dll
libmp3lame-0.dll
libfftw3f-3.dll
libfftw3-3.dll
liblilv-0-0.dll
libserd-0-0.dll
libsord-0-0.dll
libsratom-0-0.dll
libcurl-4.dll
libxml2-2.dll
libxslt-1.dll
liblo-7.dll
libtag.dll
libvamp-sdk-2.dll
libvamp-hostsdk-3.dll
libaubio-5.dll
libreadline8.dll
liblzma-5.dll
libzstd.dll
libnghttp2-14.dll
libssh2-1.dll
libssl-3-x64.dll
libcrypto-3-x64.dll
libidn2-0.dll
libunistring-5.dll
libgraphite2.dll
libdatrie-1.dll
libthai-0.dll
libfribidi-0.dll
libharfbuzz-gobject-0.dll
libharfbuzz-subset-0.dll
libjasper-7.dll
libjpeg-8.dll
libtiff-6.dll
libwebp-7.dll
libwebpmux-3.dll
libdeflate.dll
libjbig-0.dll
libLerc.dll
libsharpyuv-0.dll
liblcms2-2.dll
"

copied=0
missing=0

for dll in $DLLS; do
    if [ -f "$MINGW_BIN/$dll" ]; then
        cp "$MINGW_BIN/$dll" "$PACKAGE_DIR/bin/" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Copied: $dll"
            ((copied++))
        fi
    else
        echo "Missing: $dll"
        ((missing++))
    fi
done

echo ""
echo "Copied $copied DLLs, $missing missing"

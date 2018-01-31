#!/bin/sh
#
# Script to build release tarballs
# --------------------------------
#
# Compiles for three different platforms:
# - For Win32, using the mingw-w64 compiler,
# - For OSX 32 and 64 bits, using osxcross and GCC
# - For Linux 64bit PC, using GCC,
# - For Linux 32bit PC, using GCC.
#
# Uses link-time-optimizations and disable asserts.

set -e

ver="$(git describe --tags --dirty)"
rdir="../releases"
out="$rdir/fastbasic-$ver"

CXX_FLAGS="-DNDEBUG -Os -Wall -flto"
LIN64_FLAGS="$CXX_FLAGS -static-libstdc++"
LIN32_FLAGS="$CXX_FLAGS -m32 -static-libstdc++"
WIN_FLAGS="$CXX_FLAGS -static-libstdc++ -static-libgcc"
OSX32_FLAGS="$CXX_FLAGS -m32 -static-libstdc++"
OSX64_FLAGS="$CXX_FLAGS -static-libstdc++"

echo "----------- Compiling release $ver -------------"
echo ""

compile_lin64() {
    # Full compile for 64bit Linux (and ATR)
    make CROSS= EXT= SHEXT=.sh CXXFLAGS="$LIN64_FLAGS" dist
    mv -f build/fastbasic.zip ${out}-linux64.zip
    mv -f build/fastbasic.atr ${out}.atr
    make CROSS= EXT= SHEXT=.sh clean
}

compile_lin32() {
    # Compile for 32bit Linux - not considered cross-compilation
    make CROSS= EXT= SHEXT=.sh CXXFLAGS="$LIN32_FLAGS" build/fastbasic.zip
    mv build/fastbasic.zip ${out}-linux32.zip
    make CROSS= EXT= SHEXT=.sh clean
}

compile_win32() {
    # Compile with mingw-w64 cross compiler to 32bit:
    make CROSS=i686-w64-mingw32- EXT=.exe SHEXT=.bat CXXFLAGS="$WIN_OPTS" build/fastbasic.zip
    mv build/fastbasic.zip ${out}-win32.zip
    make EXT=.exe SHEXT=.bat clean
}

compile_osx() {
    OPATH="$PATH"
    PATH="$PATH:/opt/osx/bin"
    # Compile FAT binary for OSX.
    # Note that this is simpler with CLANG, but it produces a binary slower and twice the size!
    #  First compile to 64bit:
    make CROSS=x86_64-apple-darwin15- SHEXT=.sh EXT=_m64 CXXFLAGS="$OSX64_FLAGS" \
         compiler/fastbasic-int_m64 compiler/fastbasic-fp_m64
    #  Clean and compile to 32bit:
    make clean
    make CROSS=x86_64-apple-darwin15- SHEXT=.sh EXT=_m32 CXXFLAGS="$OSX32_FLAGS" \
         compiler/fastbasic-int_m32 compiler/fastbasic-fp_m32
    #  Build the fat binary with "LIPO":
    x86_64-apple-darwin15-lipo -create \
        compiler/fastbasic-int_m32 compiler/fastbasic-int_m64 \
        -output compiler/fastbasic-int
    x86_64-apple-darwin15-lipo -create \
        compiler/fastbasic-fp_m32 compiler/fastbasic-fp_m64 \
        -output compiler/fastbasic-fp
    rm -f compiler/fastbasic-int_m64 compiler/fastbasic-fp_m64 \
          compiler/fastbasic-int_m32 compiler/fastbasic-fp_m32
    #  Pack
    make CROSS=x86_64-apple-darwin15- SHEXT=.sh EXT= CFLAGS="$OSX32_FLAGS" build/fastbasic.zip
    mv build/fastbasic.zip ${out}-maxosx.zip
    make CROSS=x86_64-apple-darwin15- SHEXT=.sh EXT= CFLAGS="$OSX32_FLAGS" clean
}

make distclean

compile_lin64
compile_lin32
compile_win32
compile_osx


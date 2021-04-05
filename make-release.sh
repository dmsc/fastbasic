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

ncpu=-j6
ver="$(git describe --tags --dirty)"
rdir="../releases"
out="$rdir/fastbasic-$ver"

LTO_FLAGS="-flto -flto-partition=none"
CXX_FLAGS="-DNDEBUG -Os -Wall"
LIN64_FLAGS="$CXX_FLAGS $LTO_FLAGS -static-libstdc++ -Wl,--gc-sections"
WIN_FLAGS="$CXX_FLAGS -static -Wl,--gc-sections"
OSX64_FLAGS="$CXX_FLAGS $LTO_FLAGS -static-libstdc++"

echo "----------- Compiling release $ver -------------"
echo ""

compile_lin64() {
    # Full compile for 64bit Linux (and ATR)
    make $ncpu CROSS= EXT= SHEXT= OPTFLAGS="$LIN64_FLAGS" dist
    mv -f build/fastbasic.zip "${out}-linux64.zip"
    mv -f build/fastbasic.atr "${out}.atr"
    make CROSS= EXT= SHEXT= distclean
}

compile_win32() {
    # Compile with mingw-w64 cross compiler to 32bit:
    make $ncpu CROSS=i686-w64-mingw32- EXT=.exe SHEXT=.bat TARGET_OPTFLAGS="$WIN_FLAGS" build/fastbasic.zip
    mv build/fastbasic.zip "${out}-win32.zip"
    make EXT=.exe SHEXT=.bat distclean
}

compile_osx() {
    OPATH="$PATH"
    PATH="$PATH:/opt/osx/bin"
    # Compile FAT binary for OSX.
    # Note that this is simpler with CLANG, but it produces a binary slower and twice the size!
    #  First compile to 64bit:
    make $ncpu CROSS=x86_64-apple-darwin15- SHEXT= EXT= TARGET_OPTFLAGS="$OSX64_FLAGS" build/fastbasic.zip
    mv build/fastbasic.zip "${out}-macosx.zip"
    make CROSS=x86_64-apple-darwin15- SHEXT= EXT= TARGET_OPTFLAGS="$OSX32_FLAGS" distclean
    PATH="$OPATH"
}

make distclean

compile_lin64
compile_win32
compile_osx

# Makes PDF using "pandoc"
make build/compiler/MANUAL.md
pandoc build/compiler/MANUAL.md -o "${out}-manual.pdf" \
       --from markdown-raw_tex --template template.tex \
       --listings --toc --number-sections

make build/compiler/USAGE.md
pandoc build/compiler/USAGE.md -o "${out}-cross-compiler.pdf" \
       --from markdown-raw_tex --template ~/eisvogel.tex --listings


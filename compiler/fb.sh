#!/bin/sh
LOC=$(dirname $0)
ASM=${1%.*}.asm
XEX=${1%.*}.xex
if [ -z "$1" ]; then
    echo "Usage: $0 <basic-file>"
    exit 1
fi
if [ "$1" -ef "$ASM" ]; then
    echo "Error, input file same as ASM file"
    exit 1
fi
if [ "$1" -ef "$XEX" ]; then
    echo "Error, input file same as XEX file"
    exit 1
fi
echo "Compiling '$1' to assembler '$ASM'."
$LOC/fastbasic-fp "$1" "$ASM" || exit 1
echo "Assembling '$ASM' to XEX file '$XEX'."
cl65 -tatari -C $LOC/fastbasic.cfg  "$ASM" -o "$XEX" $LOC/fastbasic-fp.lib || exit 1


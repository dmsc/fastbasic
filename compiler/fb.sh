#!/bin/sh
LOC=$(dirname $0)
usage() {
    $LOC/fastbasic-int -h
    exit 1
}

error() {
    echo "$0: error, $@\nTry '$0 -h' for help."
    exit 1
}

# Process options
for i in "$@"; do
    case "$i" in
        -h)
            usage
            ;;
        -*)
            ;;
        *)
            [ -n "$PROG" ] && error "specify only one basic file"
            PROG="$i"
            ;;
    esac
done

ASM=${PROG%.*}.asm
XEX=${PROG%.*}.xex
[ -z "$PROG" ]         && error "no input file"
[ ! -f "$PROG" ]       && error "input file '$PROG' does not exists"
[ "$PROG" -ef "$ASM" ] && error "input file '$PROG' same as ASM file"
[ "$PROG" -ef "$XEX" ] && error "input file '$PROG' same as XEX file"

echo "Compiling '$PROG' to assembler '$ASM'."
$LOC/fastbasic-fp "$@" "$ASM" || exit 1
echo "Assembling '$ASM' to XEX file '$XEX'."
cl65 -tatari -C $LOC/fastbasic.cfg  "$ASM" -o "$XEX" $LOC/fastbasic-fp.lib || exit 1


; This file defines the EXE header and main chunk load header for Atari executables

        .export         __EXEHDR__: absolute = 1
        .import         __MAIN_START__, __DATA_LOAD__, __DATA_SIZE__
        .import         __INTERP_START__,  __INTERP_SIZE__
        .import         start

        .include        "atari.inc"

.segment        "EXEHDR"
        .word   $FFFF

.segment        "MAINHDR"
        .word   __MAIN_START__
        .word   __DATA_LOAD__ + __DATA_SIZE__- 1

        .ifndef FASTBASIC_ASM
.segment        "IHEADER"
        .word   __INTERP_START__
        .word   __INTERP_START__ + __INTERP_SIZE__- 1
        .endif

.segment        "AUTOSTRT"
        .word   RUNAD
        .word   RUNAD+1
        .word   start

; vi:syntax=asm_ca65

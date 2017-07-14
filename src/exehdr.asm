; This file defines the EXE header and main chunk load header for Atari executables

        .export         __EXEHDR__: absolute = 1
        .import         __MAIN_START__, __DATA_LOAD__, __DATA_SIZE__
        .import         __INTERP_START__,  __INTERP_SIZE__

.segment        "EXEHDR"
        .word   $FFFF

.segment        "MAINHDR"
        .word   __MAIN_START__
        .word   __DATA_LOAD__ + __DATA_SIZE__- 1

.segment        "IHEADER"
        .word   __INTERP_START__
        .word   __INTERP_START__ + __INTERP_SIZE__- 1

; vi:syntax=asm_ca65

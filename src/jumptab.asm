;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017,2018 Daniel Serpell
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program.  If not, see <http://www.gnu.org/licenses/>
;

; Interpreter jump table
; ----------------------

        .export OP_JUMP
        ; Import tokens
        .import EXE_END
        .import EXE_NUM, EXE_BYTE, EXE_CSTRING, EXE_CDATA, EXE_VAR_ADDR, EXE_VAR_LOAD
        .import EXE_SHL8, EXE_0, EXE_1
        .import EXE_NEG, EXE_ABS, EXE_SGN, EXE_ADD, EXE_SUB, EXE_MUL, EXE_DIV, EXE_MOD
        .import EXE_BIT_AND, EXE_BIT_OR, EXE_BIT_EXOR
        .import EXE_PEEK, EXE_DPEEK, EXE_TIME, EXE_FRE, EXE_RAND
        .import EXE_L_NOT, EXE_L_OR, EXE_L_AND, EXE_LT, EXE_GT, EXE_NEQ, EXE_EQ
        .import EXE_COMP_0
        .import EXE_POKE, EXE_DPOKE, EXE_MOVE, EXE_NMOVE, EXE_INC, EXE_DEC
        .import EXE_GRAPHICS, EXE_PLOT, EXE_DRAWTO, EXE_FILLTO
        .import EXE_PRINT_NUM, EXE_PRINT_STR, EXE_PRINT_TAB, EXE_PRINT_EOL
        .import EXE_GETKEY, EXE_INPUT_STR, EXE_XIO, EXE_CLOSE, EXE_GET, EXE_PUT
        .import EXE_BPUT, EXE_BGET, EXE_IOCHN0
        .import EXE_JUMP, EXE_CJUMP, EXE_CALL, EXE_RET
        .import EXE_FOR, EXE_FOR_START, EXE_FOR_NEXT, EXE_FOR_EXIT
        .import EXE_DIM, EXE_USHL, EXE_COPY_STR, EXE_VAL, EXE_CMP_STR
        .import EXE_SOUND_OFF, EXE_PAUSE, EXE_USR_ADDR, EXE_USR_PARAM, EXE_USR_CALL

.ifdef FASTBASIC_FP
        .import EXE_PRINT_FP
        .import EXE_INT_FP, EXE_FP_VAL, EXE_FP_SGN, EXE_FP_ABS, EXE_FP_NEG, EXE_FLOAT
        .import EXE_FP_DIV, EXE_FP_MUL, EXE_FP_SUB, EXE_FP_ADD, EXE_FP_STORE, EXE_FP_LOAD
        .import EXE_FP_EXP, EXE_FP_EXP10, EXE_FP_LOG, EXE_FP_LOG10, EXE_FP_INT, EXE_FP_CMP
        .import EXE_FP_IPOW, EXE_FP_RND, EXE_FP_SQRT, EXE_FP_SIN, EXE_FP_COS, EXE_FP_ATN
.endif ; FASTBASIC_FP


        .segment "JUMPTAB"
        .align  256
OP_JUMP:
        ; Copied from basic.syn, must be in the same order:
        .word   EXE_END
        ; Constant and variable loading
        .word   EXE_NUM, EXE_BYTE, EXE_CSTRING, EXE_CDATA, EXE_VAR_ADDR, EXE_VAR_LOAD
        .word   EXE_SHL8, EXE_0, EXE_1
        ; Numeric operators
        .word   EXE_NEG, EXE_ABS, EXE_SGN, EXE_ADD, EXE_SUB, EXE_MUL, EXE_DIV, EXE_MOD
        ; Bitwise operators
        .word   EXE_BIT_AND, EXE_BIT_OR, EXE_BIT_EXOR
        ; Functions
        .word   EXE_PEEK, EXE_DPEEK
        .word   EXE_TIME, EXE_FRE, EXE_RAND
        ; Boolean operators
        .word   EXE_L_NOT, EXE_L_OR, EXE_L_AND
        ; Comparisons
        .word   EXE_LT, EXE_GT, EXE_NEQ, EXE_EQ
        ; Convert from int to bool
        .word   EXE_COMP_0
        ; Low level statements
        .word   EXE_POKE, EXE_DPOKE, EXE_MOVE, EXE_NMOVE, EXE_INC, EXE_DEC
        ; Graphic support statements
        .word   EXE_GRAPHICS, EXE_PLOT, EXE_DRAWTO, EXE_FILLTO
        ; Print statements
        .word   EXE_PRINT_NUM, EXE_PRINT_STR, EXE_PRINT_TAB, EXE_PRINT_EOL
        ; I/O
        .word   EXE_GETKEY, EXE_INPUT_STR, EXE_XIO, EXE_CLOSE, EXE_GET, EXE_PUT
        .word   EXE_BPUT, EXE_BGET
        ; Optimization - set's IO channel to 0
        .word   EXE_IOCHN0
        ; Jumps
        .word   EXE_JUMP, EXE_CJUMP, EXE_CALL, EXE_RET
        ; FOR loop support
        .word   EXE_FOR, EXE_FOR_START, EXE_FOR_NEXT, EXE_FOR_EXIT
        ; Arrays
        .word   EXE_DIM, EXE_USHL
        ; Strings
        .word   EXE_COPY_STR, EXE_VAL, EXE_CMP_STR
        ; Sound off - could be implemented as simple POKE expressions, but it's shorter this way
        .word   EXE_SOUND_OFF
        .word   EXE_PAUSE
        ; USR, calls ML routinr
        .word   EXE_USR_ADDR, EXE_USR_PARAM, EXE_USR_CALL

.ifdef FASTBASIC_FP
        ; Floating point computations
        .word   EXE_PRINT_FP
        .word   EXE_INT_FP, EXE_FP_VAL, EXE_FP_SGN, EXE_FP_ABS, EXE_FP_NEG, EXE_FLOAT
        .word   EXE_FP_DIV, EXE_FP_MUL, EXE_FP_SUB, EXE_FP_ADD, EXE_FP_STORE, EXE_FP_LOAD
        .word   EXE_FP_EXP, EXE_FP_EXP10, EXE_FP_LOG, EXE_FP_LOG10, EXE_FP_INT, EXE_FP_CMP
        .word   EXE_FP_IPOW, EXE_FP_RND, EXE_FP_SQRT, EXE_FP_SIN, EXE_FP_COS, EXE_FP_ATN
.endif ; FASTBASIC_FP

; vi:syntax=asm_ca65

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
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; CIO operations
; --------------

        .export EXE_XIO, CIOV_CMD_POP, CIOV_CMD_POP2, CIOV_POP
        .export CIOV_IOCHN0_POP, CIOV_IOERR_POP

        ; From runtime.asm
        .import         neg_AX
        .importzp       tmp1, tmp2, tmp3, IOCHN, IOERROR

        ; From interpreter.asm
        .import         pop_stack, stack_l, stack_h, get_str_eol
        .importzp       sptr

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_XIO
        jsr     get_str_eol
        ldx     IOCHN
        lda     INBUFF
        sta     ICBAL, x
        lda     #0
        sta     ICBLH, x
        lda     INBUFF+1
        sta     ICBAH, x
        lda     #$FF
        sta     ICBLL, x
        ldy     sptr
        lda     stack_l, y
        sta     ICAX1, x
        lda     stack_h, y
        sta     ICAX2, x
        lda     stack_l+1, y
        inc     sptr
.endproc        ; Fall through
        ; Calls CIO with given command, stores I/O error, resets IOCHN, pops stack twice
CIOV_CMD_POP2:
        inc     sptr
        ; Calls CIO with given command, stores I/O error, resets IOCHN, pops stack
CIOV_CMD_POP:
        sta     ICCOM, x
        ; Calls CIOV, stores I/O error, resets IOCHN and pops stack
CIOV_POP:
        jsr     CIOV
CIOV_IOERR_POP:
        sty     IOERROR
CIOV_IOCHN0_POP:
        ldy     #0
        sty     IOCHN
        jmp     pop_stack

; vi:syntax=asm_ca65

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


; Main Floating Point interpreter
; -------------------------------

        .exportzp       DEGFLAG, FPSTK_SIZE, fptr
        .exportzp       fp_tmp_a, fp_tmp_x
        .export         fp_return_interpreter, check_fp_err
        .export         fpstk_0, fpstk_1, fpstk_2, fpstk_3, fpstk_4, fpstk_5

        .import         save_push_fr0, save_pop_fr1

        ; From runtime.asm
        .importzp       IOERROR

        ; From interpreter.asm
        .import         stack_end
        .importzp       next_instruction, cptr

        .include "atari.inc"

        .zeropage

        ; FP stack pointer
fptr:   .res    1
        ; Temporary store for INT TOS
fp_tmp_a:       .res    1
fp_tmp_x:       .res    1
        ; DEG/RAD flag
DEGFLAG:        .res    1

        ; Floating point stack, 8 * 6 = 48 bytes.
        ; Total stack = 128 bytes
FPSTK_SIZE = 8
fpstk_0 =       stack_end
fpstk_1 =       fpstk_0 + FPSTK_SIZE
fpstk_2 =       fpstk_1 + FPSTK_SIZE
fpstk_3 =       fpstk_2 + FPSTK_SIZE
fpstk_4 =       fpstk_3 + FPSTK_SIZE
fpstk_5 =       fpstk_4 + FPSTK_SIZE

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

.proc   EXE_FLOAT
        jsr     save_push_fr0

        ldy     #5
ldloop: lda     (cptr), y
        sta     FR0,y
        dey
        bpl     ldloop

        lda     cptr
        clc
        adc     #6
        sta     cptr
        bcc     fp_return_interpreter
        inc     cptr+1
        bcs     fp_return_interpreter
.endproc

.proc   EXE_FP_ADD
        jsr     save_pop_fr1
        jsr     FADD
.endproc        ; Fall-through
        ; Checks FP error, restores INT stack
        ; and returns to interpreter
.proc   check_fp_err
        ; Check error from last FP op
        bcc     ok
        lda     #3
        sta     IOERROR
ok:     ; Fall through
.endproc
.proc   fp_return_interpreter
; Restore INT stack
        lda     fp_tmp_a
        ldx     fp_tmp_x
        jmp     next_instruction
.endproc

        .include "../deftok.inc"
        deftoken "FLOAT"
        deftoken "FP_ADD"

; vi:syntax=asm_ca65

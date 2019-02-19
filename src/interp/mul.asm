;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2019 Daniel Serpell
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


; Multiplication
; --------------

        ; From runtime.asm
        .importzp       tmp1, tmp2, tmp3

        ; From interpreter.asm
        .import         stack_l, stack_h
        .importzp       next_ins_incsp

        .segment        "RUNTIME"

.proc   EXE_MUL  ; AX = (SP+) * AX
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        sta     tmp3
        ldx     stack_h, y
        stx     tmp3+1

        ; Multiply  "tmp1 * tmp3"
        lda     #0
        sta     tmp2+1
        ldy     #16             ; Number of bits

        lsr     tmp1+1
        ror     tmp1            ; Get first bit into carry
@L0:    bcc     @L1

        clc
        adc     tmp3
        tax
        lda     tmp3+1
        adc     tmp2+1
        sta     tmp2+1
        txa

@L1:    ror     tmp2+1
        ror
        ror     tmp1+1
        ror     tmp1
        dey
        bne     @L0

        lda     tmp1            ; Load the result
        ldx     tmp1+1
        jmp     next_ins_incsp
.endproc

        .include "../deftok.inc"
        deftoken "MUL"

; vi:syntax=asm_ca65

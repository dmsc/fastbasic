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


; Integer exponentiation
; ----------------------

        .import         check_fp_err, neg_AX, FP_SET_1
        .importzp       tmp1, tmp2, IOERROR, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Computes FR0 ^ (AX)
.proc   EXE_FP_IPOW

        ; Store exponent
        sta     tmp1
        stx     tmp1+1

        ; If negative, get absolute value
        cpx     #$80
        bcc     ax_pos
        jsr     neg_AX
        ; Change mantisa to 1/X
        sta     tmp1
        stx     tmp1+1

        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FDIV

ax_pos:
        ; Skip all hi bits == 0
        ldy     #17
skip:
        dey
        beq     xit_1
        asl     tmp1
        rol     tmp1+1
        bcc     skip

        sty     tmp2
        ; Start with FR0 = X, store to PLYEVL
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FST0R
loop:
        ; Check exit
        dec     tmp2
        beq     xit

        ; Square, FR0 = x^2
        jsr     FMOVE
        jsr     FMUL
        bcs     error

        ; Check next bit
        asl     tmp1
        rol     tmp1+1
        bcc     loop

        ; Multiply, FR0 = FR0 * x
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FLD1R
        jsr     FMUL

        ; Continue loop
        bcc     loop
error:  lda     #3
        sta     IOERROR

xit_1:  jsr     FP_SET_1
xit:    jmp     next_instruction
.endproc

        .include "../deftok.inc"
        deftoken "FP_IPOW"

; vi:syntax=asm_ca65

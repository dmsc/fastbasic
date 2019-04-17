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


; Division and Modulus
; --------------------

        .import         neg_AX
        .importzp       tmp1, tmp2, tmp3, divmod_sign, sptr
        .import         stack_l, stack_h

        .include "toks.inc"

.proc   EXE_DIV  ; AX = (SP+) / AX
        jsr     divmod_sign_adjust
        lda     tmp3
        ldx     tmp3+1
        bit     divmod_sign
        bpl     pos
neg:    jsr     neg_AX
pos:    sub_exit_incsp
.endproc

.proc   EXE_MOD  ; AX = (SP+) % AX
        jsr     divmod_sign_adjust
        ldx     tmp2+1
        bit     divmod_sign
        bvs     EXE_DIV::neg
        sub_exit_incsp
.endproc

; Adjust sign for SIGNED div/mod operations
; INPUT: OP1:    stack, y
;        OP2:    A / X
;
; The signs are stored in divmod_sign:
;        OP1    OP2     divmod_sign     DIV (bit 7)     MOD (bit 8)
;        +      +       00              +       0       +       0
;        +      -       80              -       1       +       0
;        -      +       FF              -       1       .       1
;        -      -       7F              +       0       .       1
.proc   divmod_sign_adjust
        ldy     #0
        cpx     #$80
        bcc     y_pos
        ldy     #$80
        jsr     neg_AX
y_pos:  sta     tmp1
        stx     tmp1+1
        sty     divmod_sign

        ldy     sptr
        lda     stack_l, y
        ldx     stack_h, y
        bpl     x_pos
        jsr     neg_AX
        dec     divmod_sign
x_pos:  sta     tmp3
        stx     tmp3+1
.endproc        ; Fall through

; Divide TMP3 / TMP1, result in TMP3 and remainder in A:TMP2+1
.proc   udiv16
        ldy     #16
        lda     #0
        sta     tmp2+1
        ldx     tmp1+1
        beq     udiv16x8

L0:     asl     tmp3
        rol     tmp3+1
        rol
        rol     tmp2+1

        tax
        cmp     tmp1
        lda     tmp2+1
        sbc     tmp1+1
        bcc     L1

        sta     tmp2+1
        txa
        sbc     tmp1
        tax
        inc     tmp3

L1:     txa
        dey
        bne     L0
        rts

udiv16x8:
        ldx     tmp1
        beq     L0
L2:     asl     tmp3
        rol     tmp3+1
        rol
        bcs     L3

        cmp     tmp1
        bcc     L4
L3:     sbc     tmp1
        inc     tmp3

L4:     dey
        bne     L2
        rts
.endproc

        deftoken "DIV"
        deftoken "MOD"

; vi:syntax=asm_ca65

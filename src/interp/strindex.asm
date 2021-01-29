;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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


; String indexing
; ---------------

        .importzp       tmp1, tmp3
        .import         stack_l, stack_h, next_ins_incsp_2

        .include "atari.inc"

        .segment        "RUNTIME"

; Implement indexing by copying the sub-string to a new string at LBUFF.
; Note that this potentially overwrites from $600 to $67F.

        ; Index at position with given length
.proc   EXE_STR_IDX
        ; AX   = Count
        ; SP   = Position
        ; SP+1 = String address

        cpx     #0
        bmi     zero
        beq     ok1
        lda     #255            ; if Count>255, set to 255
ok1:
        sta     tmp3+1

        ldx     stack_h, y      ; Check Position < 256
        bne     zero            ; Overflow

        ldx     stack_l+1, y    ; Copy Address to tmp1
        stx     tmp1
        ldx     stack_h+1, y
        stx     tmp1+1

        lda     stack_l, y      ; Position
        tay
        dey

        ldx     #$FF
        lda     (tmp1+1,x)      ; Read original length
        sta     tmp3

copy_str:
        inx
        lda     (tmp1), y
        sta     LBUFF-1, x
        cpy     tmp3
        bcs     xit
        iny
        cpx     tmp3+1
        bcc     copy_str

xit:
        stx     LBUFF-1         ; Set string length

        ; Return new string position
        lda     #<(LBUFF-1)
        ldx     #>(LBUFF-1)
        jmp     next_ins_incsp_2

zero:
        ldx     #0
        beq     xit
.endproc

        .include "../deftok.inc"
        deftoken "STR_IDX"

; vi:syntax=asm_ca65

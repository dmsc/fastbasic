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


; String indexing
; ---------------

        ; From runtime.asm
        .importzp       tmp1, tmp2, tmp3, sptr

        ; From interpreter.asm
        .importzp       next_ins_incsp
        .import         stack_l, stack_h

        .include "atari.inc"

        .segment        "RUNTIME"

; Implement indexing by copying the sub-string to a new string at LBUFF.
; Note that this potentially overwrites from $600 to $67F.

        ; Index at position with given length
.proc   EXE_STR_IDX
        ; AX   = Length
        ; SP   = Position
        ; SP+1 = String address

        ; Fix stack pointer
        inc     sptr

        cpx     #0
        beq     ok1
        lda     #255            ; if length>255, set to 255
ok1:    sta     tmp3+1          ; tmp3+1 = Length
        ldx     stack_h, y
        bne     zero    ; Overflow
        ldx     stack_l, y
        dex
        stx     tmp3

        lda     stack_l+1, y
        sta     tmp1
        adc     tmp3
        sta     tmp2
        lda     stack_h+1, y
        sta     tmp1+1
        adc     #0
        sta     tmp2+1
        ; Subtract LEN - POS -> new length
        ldy     #0
        lda     (tmp1), y
        sec
        sbc     tmp3
        bcc     zero    ; Also overflow
        cmp     tmp3+1
        bcc     ok2
        lda     tmp3+1          ; Use given length instead of max
ok2:    tax
        inx

copy_str:
        sta     LBUFF-1, y
        lda     (tmp2), y
        iny
        dex
        bne     copy_str
        ; Return new string position
        lda     #<(LBUFF-1)
        ldx     #>(LBUFF-1)
pop:    jmp     next_ins_incsp

zero:
        lda     #0
        tax
        beq     pop
.endproc

        .include "../deftok.inc"
        deftoken "STR_IDX"

; vi:syntax=asm_ca65

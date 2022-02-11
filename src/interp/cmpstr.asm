;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2022 Daniel Serpell
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


; String comparisons
; ------------------

        .import         stack_l, stack_h, pushXX_set0
        .importzp       tmp1, tmp2, tmp3, sptr

        .segment        "RUNTIME"

.proc   EXE_CMP_STR     ; Compare string in (AX) with (SP), store 0, 1 or -1 in stack,
                        ; then load 0 to perform an integer comparison
        sta     tmp1
        stx     tmp1+1

        lda     stack_l, y
        sta     tmp2
        ldx     stack_h, y
        stx     tmp2+1

        ; X is the return value
        ldx     #1

        ; Get smaller lengths
        ldy     #0
        lda     (tmp1), y
        cmp     (tmp2), y
        beq     l1_equal
        bcc     l1_shorter
        dex             ; S1 larger, return 1 if characters equal
        lda     (tmp2), y
l1_equal:
        dex
l1_shorter:
        sta     tmp3

        ; Compare each byte
next_char:
        cpy     tmp3
        beq     xit

        iny
        lda     (tmp1), y
        cmp     (tmp2), y
        beq     next_char

        ldx     #$01
        bcc     xit

        ldx     #$FF    ; Returns < 0

xit:
        inc     sptr
        jmp     pushXX_set0
.endproc

        .include "deftok.inc"
        deftoken "CMP_STR"

; vi:syntax=asm_ca65

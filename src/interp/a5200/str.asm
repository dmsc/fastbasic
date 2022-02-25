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


; Print 16bit number
; ------------------

        .import         neg_AX, line_buf
        .importzp       next_instruction, tmp1


        .segment        "RUNTIME"


.proc EXE_INT_STR       ; AX = STRING( AX )

        ; Store sign and make positive:
        cpx     #$80
        php                     ; Store sign in C
        bcc     positive
        jsr     neg_AX
positive:
        ; Now, convert into local buffer
        sta     tmp1
        stx     tmp1+1

        ldy     #7
L1:
        lda     #0
        clv
        ldx     #16
L2:
        cmp     #5
        bcc     L3
        sbc     #$85
        sec
L3:
        rol     tmp1
        rol     tmp1+1
        rol
        dex
        bne     L2
        ora     #'0'
        sta     line_buf, y
        dey
        bvs     L1

        ; Ok, see if we need to store sign
        plp
        bcc     ok

        lda     #'-'
        sta     line_buf, y
        dey
ok:
        tya
        eor     #7
        sta     line_buf, y

        ldx     #>line_buf
        tya
        clc
        adc     #<line_buf
        bcc     ret
        inx
ret:
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "INT_STR"

; vi:syntax=asm_ca65

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


; Random integer
; --------------

        .importzp       tmp1, tmp2, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_RAND        ; AX= RANDOM from 0 to AX-1

        ldy     #0
        stx     tmp1+1

get_l:  iny
        cpy     #$10
        rol
        rol     tmp1+1
        bpl     get_l
        sta     tmp1

        ; Now, get a number in the range
retry:  ldx     RANDOM
        cpx     tmp1
        lda     RANDOM
        sta     tmp2
        sbc     tmp1+1
        bcs     retry

        ; And scale back
        txa
scale:  lsr     tmp2
        ror
        dey
        bne     scale
        ldx     tmp2
xit:    jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "RAND"

; vi:syntax=asm_ca65

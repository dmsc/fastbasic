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


; Reads a 16-bit value from an address
; ------------------------------------

        .import         pushAX
        .importzp       tmp1

        .include "toks.inc"

.proc   EXE_PUSH_VAR_LOAD; push AX, load variable
        jsr     pushAX
.endproc        ; Fall through


    .ifndef FASTBASIC_ASM
.proc   EXE_VAR_LOAD  ; AX = value of variable
        get_var
.endproc        ; Fall through:
    .endif
.proc   EXE_DPEEK  ; AX = PEEK(AX) + 256 * PEEK(AX+1)
.ifdef NO_SMCODE
        sta     tmp1
        stx     tmp1+1
        ldy     #1
        lda     (tmp1),y
        tax
        dey
        lda     (tmp1),y
.else
        ; self-modifying code, 4 cycles faster and 1 byte longer than the above
        stx     loadH+2
        stx     loadL+2
        tay
loadH:  ldx     $FF01, y
loadL:  lda     $FF00, y
.endif
        sub_exit
.endproc

        deftoken "DPEEK"
        deftoken "VAR_LOAD"
        deftoken "PUSH_VAR_LOAD"

; vi:syntax=asm_ca65

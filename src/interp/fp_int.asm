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


; Convert FP to integer
; ---------------------

        .importzp       tmp1, IOERROR
        .import         neg_AX, pop_fr0, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_FP_INT      ; Convert FP to INT, with rounding
        lda     FR0
        php             ; Store sign
        jsr     FPI
        bcs     err3
        ldx     FR0+1
        bpl     ok
        ; Store error #3
err3:   lda     #3
        sta     IOERROR
ok:     lda     FR0
        ; Save A, pop FP stack and restore
        pha
        jsr     pop_fr0
        pla

        ; Negate result if original number was negative
        plp
        bpl     pos

        jsr     neg_AX
pos:
        jmp     next_instruction
.endproc

        .include "../deftok.inc"
        deftoken "FP_INT"

; vi:syntax=asm_ca65

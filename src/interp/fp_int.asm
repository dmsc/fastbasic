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


; Natural LOG function
; --------------------

        .importzp       tmp1, IOERROR
        .import         pushAX, neg_AX, save_pop_fr1, fp_return_interpreter

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_FP_INT      ; Convert FP to INT, with rounding
        jsr     pushAX
        asl     FR0
        ror     tmp1    ; Store sign in tmp1
        lsr     FR0
        jsr     FPI
        bcs     err3
        ldx     FR0+1
        bpl     ok
        ; Store error #3
err3:   lda     #3
        sta     IOERROR
        ; Negate result if original number was negative
ok:     lda     FR0
        ldy     tmp1
        bpl     pos
        jsr     neg_AX
        ; Store and pop FP stack
pos:    jsr     save_pop_fr1
        jmp     fp_return_interpreter
.endproc

        .include "../deftok.inc"
        deftoken "FP_INT"

; vi:syntax=asm_ca65

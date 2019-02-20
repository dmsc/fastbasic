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


; Push values to FP stack
; -----------------------

        .export         push_fr0
        .import         fpstk_0, fpstk_1, fpstk_2, fpstk_3, fpstk_4, fpstk_5
        .importzp       fptr

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Push FP stack, FR0 remains unchanged.
.proc   push_fr0
        dec     fptr
        ldy     fptr
        lda     FR0+0
        sta     fpstk_0, y
        lda     FR0+1
        sta     fpstk_1, y
        lda     FR0+2
        sta     fpstk_2, y
        lda     FR0+3
        sta     fpstk_3, y
        lda     FR0+4
        sta     fpstk_4, y
        lda     FR0+5
        sta     fpstk_5, y
        rts
.endproc

; vi:syntax=asm_ca65

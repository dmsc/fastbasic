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


; Pop values from FP stack
; ------------------------

        .export         pop_fr1, pop_fr0
        .import         fpstk_0, fpstk_1, fpstk_2, fpstk_3, fpstk_4, fpstk_5
        .importzp       fptr

        .include "toks.inc"
        .include "atari.inc"

        ; Move FR0 to FR1
        ; and pop stack to FR0
.proc   pop_fr1
        jsr     FMOVE
        ; Fall through
.endproc
        ; Pops FP stack discarding FR0
        ; keeps X intact
.proc   pop_fr0
        ldy     fptr
        inc     fptr
        lda     fpstk_0, y
        sta     FR0
        lda     fpstk_1, y
        sta     FR0+1
        lda     fpstk_2, y
        sta     FR0+2
        lda     fpstk_3, y
        sta     FR0+3
        lda     fpstk_4, y
        sta     FR0+4
        lda     fpstk_5, y
        sta     FR0+5
        rts
.endproc

; vi:syntax=asm_ca65

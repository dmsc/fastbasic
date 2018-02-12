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


; Prepares a string to call CIO functions, appending an EOL at end
; ----------------------------------------------------------------

        .export get_str_eol

        .include "atari.inc"

        .segment        "RUNTIME"

; Copy string to LBUFF storing an EOL at end, allows calling OS routines
; Returns LBUFF in INBUFF
.proc   get_str_eol
INTLBUF = $DA51
        sta     INBUFF
        stx     INBUFF+1
        ; Get length
        ldy     #0
        lda     (INBUFF), y
        tay
        iny
        bpl     ok
        ldy     #$7f    ; String too long, just overwrite last character
ok:     lda     #$9B
        .byte   $2C     ; Skip 2 bytes over LDA (),y
copy:
        lda     (INBUFF), y
        sta     LBUFF-1, y
        dey
        bne     copy
        ; Init CIX and copy LBUFF address to INBUFF
        sty     CIX
        jmp     INTLBUF
.endproc

; vi:syntax=asm_ca65

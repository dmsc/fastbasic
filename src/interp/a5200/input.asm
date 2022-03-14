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


; INPUT string
; ------------

        .importzp       next_instruction, COLCRS
        .import         get_key, putc, line_buf
        .export         INPUT_WIDTH

.data
        ; Limit maximum input characters, can be adjusted from code:
INPUT_WIDTH:
        .byte   30

        .segment        "RUNTIME"

.proc   EXE_INPUT_STR   ; INPUT to string buffer

again:
        ldy     #0

key:
        ; Show a cursor:
        lda     #'_' + 128
        jsr     putc
        dec     COLCRS

        jsr     get_key
        and     #$0F    ; Ignore other controllers
        tax
        lda     trans, x
        beq     ret
        bpl     ok

del:
        dey
        bmi     again
        lda     #' '
        jsr     putc
        dec     COLCRS
        dec     COLCRS
        bpl     key

ok:
        sta     line_buf + 1, y
        jsr     putc
        iny
        bmi     del
        cpy     INPUT_WIDTH
        bne     key
        beq     del

ret:
        sty     line_buf

        lda     #<line_buf
        ldx     #>line_buf
        jmp     next_instruction
.endproc

trans:
        .byte   '0', '1', '2', '3', '4', '5', '6', '7'
        .byte   '8', '9', '*', '#',   0,   0, $80

        .include "deftok.inc"
        deftoken "INPUT_STR"

; vi:syntax=asm_ca65

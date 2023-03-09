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


; Print string
; ------------

        .import         putc, stack_l
        .importzp       tmp1, tmp2, tmp3, next_instruction, sptr
        .importzp       PRINT_COLOR
        .export         print_str_tmp1

        .segment        "RUNTIME"

.proc   EXE_PRINT_STR   ; PRINT string in AX, with color 0
        sta     tmp1
        stx     tmp1+1
ptmp:                   ; Prints string in TMP1
        ldy     #0
        lda     (tmp1), y       ; LENGTH
        beq     nil
        sta     tmp2
loop:   iny
        lda     (tmp1), y
        eor     PRINT_COLOR
        jsr     putc
        cpy     tmp2
        bne     loop
nil:    jmp     next_instruction
.endproc

print_str_tmp1 = EXE_PRINT_STR::ptmp

        .include "deftok.inc"
        deftoken "PRINT_STR"

; vi:syntax=asm_ca65

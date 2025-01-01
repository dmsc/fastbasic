;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2025 Daniel Serpell
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


; Convert string to number
; ------------------------

        .import         neg_AX
        .importzp       IOERROR, tmp1, tmp2, tmp3, tmp4, next_instruction

        .segment        "RUNTIME"

.proc   EXE_VAL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Convert string to integer (word)


        sta     tmp3
        stx     tmp3+1

        ; Store length, clean IOERROR
        ldy     #0
        sty     IOERROR
        lda     (tmp3), y
        sta     tmp4

        ; Skips white space at start
        lda     #' '
skp:
        cpy     tmp4
        bcs     set_err

        iny
        cmp     (tmp3), y
        beq     skp

skp_end:
        ; Reads a '+' or '-'
        lda     (tmp3), y
        cmp     #'-'
        beq     do_minus        ; C=1 if equal
        clc
        eor     #'+'
        bne     convert
do_minus:
        iny
convert:
        php     ; Store C flag for negative numbers

        sty     tmp2+1  ; Store starting Y position - used to check if read any digits
        dey
        ; Clears result
        lda     #0
        tax
loop:
        ; Store A/X
        sta     tmp1
        stx     tmp1+1

        cpy     tmp4
        beq     xit_n
        iny

        ; Reads one character
        lda     (tmp3), y
        eor     #'0'
        cmp     #10
        sta     tmp2    ; save digit
        lda     tmp1    ; and restore A

        bcs     xit_n ; Not a number


        cpx     #26     ; Reject numbers > $1A00 (6656)
        bcs     ebig

        ; Multiply "tmp1" by 10 - uses A,X, keeps Y
        asl
        rol     tmp1+1
        asl
        rol     tmp1+1

        adc     tmp1
        sta     tmp1
        txa
        adc     tmp1+1

        asl     tmp1
        rol     a
        tax
        bcs     ebig

        ; Add new digit
        lda     tmp2
        adc     tmp1
        bcc     loop
        inx
        bne     loop

ebig:
        plp
set_err:
        ldy     #18
        sty     IOERROR
        bne     end

xit_n:  cpy     tmp2+1
        beq     ebig    ; No digits read

        plp
        bcc     end
        jsr     neg_AX
end:
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "VAL"

; vi:syntax=asm_ca65


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


; Convert string to number
; ------------------------

        .export read_word

        ; From runtime.asm
        .importzp       IOERROR, tmp1, tmp2, divmod_sign
        .import         neg_AX

        ; From interpreter.asm
        .import         get_str_eol
        .importzp       next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_VAL
        jsr     get_str_eol
        jsr     read_word
        bcc     :+
        lda     #18
        sta     IOERROR
:       jmp     next_instruction
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Convert string to integer (word)
.proc   read_word
SKBLANK = $DBA1
        ; Skips white space at start
        jsr     SKBLANK

        ; Clears result
        ldx     #0
        stx     tmp1

        ; Reads a '+' or '-'
        lda     (INBUFF), y
        cmp     #'+'
        beq     skip
        cmp     #'-'
        bne     convert

        iny
        jsr     convert
        php
        jsr     neg_AX
        plp
        rts

skip:   iny
convert:
        sty     tmp2+1  ; Store starting Y position - used to check if read any digits
loop:
        ; Reads one character
        lda     (INBUFF), y
        sec
        sbc     #'0'
        cmp     #10
        bcs     xit_n ; Not a number

        iny             ; Accept

        sta     tmp2    ; and save digit

        ; Multiply "tmp1" by 10 - uses A,X, keeps Y
        lda     tmp1
        stx     tmp1+1

        asl
        rol     tmp1+1
        bcs     ebig
        asl
        rol     tmp1+1
        bcs     ebig

        adc     tmp1
        sta     tmp1
        txa
        adc     tmp1+1
        bcs     ebig

        asl     tmp1
        rol     a
        tax
        bcs     ebig

        ; Add new digit
        lda     tmp2
        adc     tmp1
        sta     tmp1
        bcc     loop
        inx
        bne     loop

ebig:
        sec
xit:    rts

xit_n:  cpy     tmp2+1
        beq     ebig    ; No digits read

        lda     tmp1
        clc
        rts
.endproc

        .include "../deftok.inc"
        deftoken "VAL"

; vi:syntax=asm_ca65

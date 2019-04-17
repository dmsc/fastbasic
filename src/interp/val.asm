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


; Convert string to number
; ------------------------

        .export         read_word
        .import         neg_AX, get_str_eol
        .importzp       IOERROR, tmp1, tmp2

        .include "toks.inc"
        .include "atari.inc"

.proc   EXE_VAL
        jsr     get_str_eol
        jsr     read_word
        bcc     :+
        ldy     #18
        sty     IOERROR
:       sub_exit
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Convert string to integer (word)
.proc   read_word
SKBLANK = $DBA1
        ; Skips white space at start
        jsr     SKBLANK

        ; Reads a '+' or '-'
        lda     (INBUFF), y
        cmp     #'+'
        beq     skip
        cmp     #'-'
        bne     convert

        jsr     skip
        php
        jsr     neg_AX
        plp
        rts

skip:   iny
convert:
        sty     tmp2+1  ; Store starting Y position - used to check if read any digits
        ; Clears result
        lda     #0
        tax
loop:
        ; Store A/X
        sta     tmp1
        stx     tmp1+1

        ; Reads one character
        lda     (INBUFF), y
        sec
        sbc     #'0'
        cmp     #10
        sta     tmp2    ; save digit
        lda     tmp1    ; and restore A

        bcs     xit_n ; Not a number

        iny             ; Accept

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
        sec
xit:    rts

xit_n:  cpy     tmp2+1
        beq     xit    ; No digits read

        clc
        rts
.endproc

        deftoken "VAL"

; vi:syntax=asm_ca65

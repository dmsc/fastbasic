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


; Common runtime between interpreter and parser
; ---------------------------------------------

        ; 16bit math
        .export         neg_AX
        ; simple I/O
        .export         print_word
        .export         close_all
        .exportzp       IOCHN, COLOR, IOERROR, tabpos, divmod_sign
        ; Common ZP variables (2 bytes each)
        .exportzp       tmp1, tmp2, tmp3

        .import         putc

.ifdef FASTBASIC_FP
        ; Exported only in Floating Point version
        .export         print_fp, int_to_fp, read_fp
        ; Convert string to floating point
read_fp = AFP
.else
        ; In integer version, the conversion and printing is the same
print_word = int_to_fp
.endif ; FASTBASIC_FP

        .include        "atari.inc"

        .zeropage

tmp1:   .res    2
tmp2:   .res    2
tmp3:   .res    2
divmod_sign:
        .res    1
IOCHN:  .res    1
IOERROR:.res    2
COLOR:  .res    1
tabpos: .res    1

        .segment        "RUNTIME"

; Negate AX value : SHOULD PRESERVE Y
.proc   neg_AX
        clc
        eor     #$FF
        adc     #1
        pha
        txa
        eor     #$FF
        adc     #0
        tax
        pla
        rts
.endproc

.proc   int_to_fp
FR0     = $D4
IFP     = $D9AA
        stx     tmp1
        cpx     #$80
        bcc     positive
        jsr     neg_AX
positive:
        sta     FR0
        stx     FR0+1
        jsr     IFP
        lda     tmp1
        and     #$80
        eor     FR0
        sta     FR0

        ; Minor optimization: in integer version, we don't use
        ; int_to_fp from outside, so fall through to print_fp
.ifdef FASTBASIC_FP
        rts
.endproc

.proc   print_word
FR0     = $D4
        jsr     int_to_fp

.endif ; FASTBASIC_FP

        ; Fall through
.endproc
.proc   print_fp
FASC    = $D8E6
INBUFF  = $F3
        jsr     FASC
        ldy     #$FF
ploop:  iny
        lda     (INBUFF), y
        pha
        and     #$7F
        jsr     putc
        pla
        bpl     ploop
        rts
.endproc

.proc   close_all
        lda     #$70
:       tax
        lda     #CLOSE
        sta     ICCOM, x
        jsr     CIOV
        txa
        sec
        sbc     #$10
        bne     :-
        rts
.endproc

; vi:syntax=asm_ca65

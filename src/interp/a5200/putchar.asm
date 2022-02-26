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


; Put character to screen
; -----------------------

        .export         putc
        .importzp       tmp3, tmp4
        .importzp       DINDEX, COLCRS, ROWCRS, SAVMSC

        .segment        "RUNTIME"

        ; Draws one character / plot one pixel
        ; TODO: implement plot in graphic modes

.proc   putc

        ; Special handling only EOL and CLS
        cmp     #155
        bne     no_eol

        lda     #0
        sta     COLCRS
        ldx     ROWCRS
        inx
        cpx     #24
        bcc     :+
        ldx     #0
:       stx     ROWCRS

exit:
        rts

no_eol:

        ; Convert character from ATASCII to screen codes
        asl
        php
        sbc     #$3F
        bpl     conv_ok
        eor     #$40
conv_ok:
        plp
        ror

        pha             ; Store A

        ; Calculate coordinates - only valid for text modes
        lda     #0
        sta     tmp4+1
        lda     ROWCRS  ; max  =  23
        asl             ; x 2  =  46
        asl             ; x 4  =  92
        adc     ROWCRS  ; x 5  = 115
        asl             ; x 10 = 230
        asl             ; x 20 = 460
        rol     tmp4+1
        bit     DINDEX
        bvs     m20
        asl             ; x 40 = 920
        rol     tmp4+1
m20:
        adc     COLCRS  ; max = 959
        bcc     :+
        inc     tmp4+1
        clc
:
        adc     SAVMSC
        sta     tmp4
        lda     tmp4+1
        adc     SAVMSC+1
        sta     tmp4+1

        ; Write character to screen
        pla
        ldx     #0
        sta     (tmp4, x)

        ; Update cursor position - do not handle screen wrap
        inc     COLCRS
        rts
.endproc

; vi:syntax=asm_ca65

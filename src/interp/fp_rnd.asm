;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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


; Random number from 0.0 to 0.9999999999
; --------------------------------------

        .import         check_fp_err, push_fr0

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Returns a random FP number in the interval 0 <= X < 1
        ; Based on code from Altirra BASIC, (C) 2015 Avery Lee.
.proc   EXE_FP_RND
FPNORM=$DC00
        jsr     push_fr0

        lda     #$3F
        sta     FR0

        ; Get 5 digits
        ldx     #5
loop:
        ; Retries until we get a valid BCD number
get_bcd_digit:
        lda     RANDOM
        cmp     #$A0
        bcs     get_bcd_digit
        sta     FR0, x
        and     #$0F
        cmp     #$0A
        bcs     get_bcd_digit
        dex
        bne     loop

        ; Re-normalize random value (for X < 0.01) and exit
        jsr     FPNORM
        jmp     check_fp_err
.endproc

        .include "../deftok.inc"
        deftoken "FP_RND"

; vi:syntax=asm_ca65

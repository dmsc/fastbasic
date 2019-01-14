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


; Floating Point coefficients
; ---------------------------

        .export         fp_sin_coef, fp_pi1_2, fp_180pi, fp_90

        .segment        "RUNTIME"

        ; Coefficients of SIN function, pi/2, 90 and 180/pi.
fp_sin_coef:
        .byte $3E,$01,$51,$58,$00,$00
        .byte $BE,$46,$74,$16,$00,$00
        .byte $3F,$07,$96,$90,$12,$54
        .byte $BF,$64,$59,$63,$88,$21
fp_pi1_2:
        .byte $40,$01,$57,$07,$96,$33
fp_90:
        .byte $40,$90,$00,$00,$00,$00
fp_180pi:
        .byte $40,$57,$29,$57,$79,$51

; vi:syntax=asm_ca65

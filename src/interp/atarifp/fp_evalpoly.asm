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


; Evaluate ATN / SIN / COS polynomials
; ------------------------------------

        .export         eval_atn_poly, eval_poly_x2

        .include "atari.inc"

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

        ; Evaluates ATAN polynomial
.proc   eval_atn_poly
ATNCOEF     = $DFAE
        lda     #11
        ldx     #<ATNCOEF
        ldy     #>ATNCOEF
.endproc        ; Fall through
        ; Evaluates a polynomial in *odd* powers of X, as:
        ;  z = x^2
        ;  y = x * P(z)
        ;
        ; On input, X:Y points to the coefficient table,
        ; A is the number of coefficients.
.proc   eval_poly_x2
        ; Store arguments
        pha
        txa
        pha
        tya
        pha

        ; Store X (=FR0) into FPSCR
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FST0R

        ; Compute X^2
        jsr     FMOVE
        jsr     FMUL

        ; Compute P(X^2) with our coefficients
        pla
        tay
        pla
        tax
        pla
        jsr     PLYEVL

        ; Compute X * P(X^2)
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FLD1R
        jmp     FMUL
.endproc

; vi:syntax=asm_ca65

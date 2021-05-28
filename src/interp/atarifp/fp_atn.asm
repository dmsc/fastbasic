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


; ATN (arc-tangent) function
; --------------------------

        .import         eval_atn_poly, check_fp_err
        .import         fp_180pi, fp_pi1_2, FP_SET_1
        .importzp       DEGFLAG, tmp2

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Compute arc-tangent of FR0
        ; Uses table of coefficients on ROM, shorter code,
        ; reduced as:  ATN(x) = PI/2 - ATN(1/x)  if |x|>1.0
        ;
.proc EXE_FP_ATN
        lda     FR0
        asl
        ror     tmp2
        lsr
        sta     FR0
        asl
        bpl     small_arg

        ; Get 1/X
        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FDIV
        jsr     eval_atn_poly
        ldx     #<fp_pi1_2
        ldy     #>fp_pi1_2
        jsr     FLD1R
        jsr     FSUB
        bcc     test_deg

small_arg:

        jsr     eval_atn_poly
test_deg:
        ; Convert to degrees if needed:
        lda     DEGFLAG
        beq     not_deg

        ldx     #<fp_180pi
        ldy     #>fp_180pi
        jsr     FLD1R
        jsr     FMUL
not_deg:
        ; Adds SIGN
        asl     FR0
        asl     tmp2
        ror     FR0
exit:
        jmp     check_fp_err

.endproc

        .include "deftok.inc"
        deftoken "FP_ATN"

; vi:syntax=asm_ca65

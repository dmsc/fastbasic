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


; SIN / COS functions
; -------------------

        .import         fp_sin_coef, fp_pi1_2, fp_90
        .import         eval_poly_x2, check_fp_err, FP_SET_1
        .importzp       DEGFLAG, tmp2

        .include "atari.inc"

        .segment        "RUNTIME"

        ; SIN function, using a minimax 5 degree polynomial:
        ;    SIN(π/2 x) = ((((s[4] * x² + s[3]) * x² + s[2]) * x² + s[1]) * x² + s[0]) * x
        ;
        ; We use the polynomial:
        ;  S() = 1.57079633  -0.6459638821  0.0796901254  -0.00467416  0.00015158
        ;
        ; Maximum relative error 1.23e-08, this is better than the 6 degree
        ; poly in Atari BASIC, and 2 times worst than the 6 degree poly in
        ; Altirra BASIC.
        ;
        ; The polynomial was found with a minimax approximation in [-1:1], and
        ; then optimized by brute-force search to keep the total error bellow
        ; 1.23E-8 and ensuring that the approximation is always <= 1.0, so no
        ; adjustments are needed after calculation.
        ;
        ; As we expand the polynomial about SIN(π/2 x), we also don't need to
        ; take the modulus, we only divide the argument by π/2 (or 90 if we are
        ; in DEG mode), and this is exactly the first coefficient.
        ;
.proc   EXE_FP_SIN
        ldy     #2      ; Negative SIN: quadrant #2
        bit     FR0
        bmi     SINCOS
        ldy     #0      ; Positive SIN: quadrant #0
        .byte   $2C     ; Skip 2 bytes over next "LDY"
.endproc        ; Fall through

.proc   EXE_FP_COS
        ldy     #1      ; Positve/Negative COS: quadrant #1
.endproc        ; Fall trough

.proc   SINCOS
FPNORM=$DC00

        sty     tmp2    ; Store quadrant into tmp2

        ldy     #>fp_pi1_2
        ldx     #<fp_pi1_2

        ; Divide by 90° or PI/2
        lda     DEGFLAG
        beq     do_rad
        ldx     #<fp_90
        ; TODO: in the case of the assert bellow, you could add an "INY"
        .assert (>fp_pi1_2) = (>fp_90), error, "PI/2 and 90 fp constants in different pages"
do_rad:

        jsr     FLD1R
        jsr     FDIV
        bcs     exit

        ; Get ABS of FR0
        lda     FR0
        and     #$7F
        sta     FR0
        cmp     #$40
        bcc     less_than_1     ; Small enough
        cmp     #$45
        bcs     exit            ; Too big
        tax

        lda     FR0-$40+1, x    ; Get "tens" digit
        and     #$10            ; if even/odd
        lsr
        lsr
        lsr                     ; get 0/2
        adc     tmp2            ; add to quadrant (C is clear here)
        adc     FR0-$40+1, x    ; and add the "ones" digit
        sta     tmp2

        ; Now, get fractional part by setting digits to 0
        lda     #0
:       sta     FR0-$40+1, x
        dex
        cpx     #$3F
        bne     :-

        jsr     FPNORM

less_than_1:

        ; Check if odd quadrant, compute FR0 = 1 - FR0
        lsr     tmp2
        bcc     no_mirror
        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FSUB
no_mirror:

        ; Compute FR0 * P(FR0^2)
        ldx     #<fp_sin_coef
        ldy     #>fp_sin_coef
        lda     #5
        jsr     eval_poly_x2

        ; Get sign into result, and clear carry
        asl     FR0
        beq     exit
        lsr     tmp2
        ror     FR0
exit:
        jmp     check_fp_err

.endproc

        .include "../deftok.inc"
        deftoken "FP_SIN"
        deftoken "FP_COS"

; vi:syntax=asm_ca65

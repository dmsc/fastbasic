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


; Main Floating Point interpreter
; -------------------------------

        .exportzp       DEGFLAG, DEGFLAG_RAD, DEGFLAG_DEG, FPSTK_SIZE, fptr

        .export   EXE_PRINT_FP
        .export   EXE_INT_FP, EXE_FP_VAL, EXE_FP_SGN, EXE_FP_ABS, EXE_FP_NEG, EXE_FLOAT
        .export   EXE_FP_DIV, EXE_FP_MUL, EXE_FP_SUB, EXE_FP_ADD, EXE_FP_STORE, EXE_FP_LOAD
        .export   EXE_FP_EXP, EXE_FP_EXP10, EXE_FP_LOG, EXE_FP_LOG10, EXE_FP_INT, EXE_FP_CMP
        .export   EXE_FP_IPOW, EXE_FP_RND, EXE_FP_SQRT, EXE_FP_SIN, EXE_FP_COS, EXE_FP_ATN

        ; From runtime.asm
        .import         neg_AX
        .import         print_fp, int_to_fp, read_fp
        .importzp       tmp1, tmp2, tmp3, IOERROR

        ; From interpreter.asm
        .import         stack_l, stack_h, stack_end, pop_stack, get_str_eol
        .import         EXE_0, pushAX
        .importzp       next_instruction, next_ins_incsp, sptr, cptr

        .include "atari.inc"

        .zeropage

        ; FP stack pointer
fptr:   .res    1
        ; Temporary store for INT TOS
fp_tmp_a:       .res    1
fp_tmp_x:       .res    1
        ; DEG/RAD flag
DEGFLAG:        .res    1

        ; Floating point stack, 8 * 6 = 48 bytes.
        ; Total stack = 128 bytes
FPSTK_SIZE = 8
fpstk_0 =       stack_end
fpstk_1 =       fpstk_0 + FPSTK_SIZE
fpstk_2 =       fpstk_1 + FPSTK_SIZE
fpstk_3 =       fpstk_2 + FPSTK_SIZE
fpstk_4 =       fpstk_3 + FPSTK_SIZE
fpstk_5 =       fpstk_4 + FPSTK_SIZE

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

        ; Save INT stack to temporary, push FP stack
.proc   save_push_fr0
        sta     fp_tmp_a
        stx     fp_tmp_x
        ; Fall through
.endproc
        ; Push FP stack, FR0 remains unchanged.
.proc   push_fr0
        dec     fptr
        ldy     fptr
        lda     FR0+0
        sta     fpstk_0, y
        lda     FR0+1
        sta     fpstk_1, y
        lda     FR0+2
        sta     fpstk_2, y
        lda     FR0+3
        sta     fpstk_3, y
        lda     FR0+4
        sta     fpstk_4, y
        lda     FR0+5
        sta     fpstk_5, y
        rts
.endproc

        ; Save INT stack to temporary, move FR0 to FR1
        ; and pop stack to FR0
.proc   save_pop_fr1
        sta     fp_tmp_a
        stx     fp_tmp_x
nosave:
        jsr     FMOVE
        ; Fall through
.endproc
        ; Pops FP stack discarding FR0
.proc   pop_fr0
        ldy     fptr
        inc     fptr
        lda     fpstk_0, y
        sta     FR0
        lda     fpstk_1, y
        sta     FR0+1
        lda     fpstk_2, y
        sta     FR0+2
        lda     fpstk_3, y
        sta     FR0+3
        lda     fpstk_4, y
        sta     FR0+4
        lda     fpstk_5, y
        sta     FR0+5
        rts
.endproc

.proc   EXE_INT_FP      ; Convert INT to FP
        ; Save INT stack, push FP stack
        jsr     save_push_fr0
        ; Restore TOS
        lda     fp_tmp_a
        ldx     fp_tmp_x
        ; Convert to FP
        jsr     int_to_fp
        ; Discard top of INT stack
        jmp     pop_stack
.endproc

.proc   EXE_FP_INT      ; Convert FP to INT, with rounding
        jsr     pushAX
        asl     FR0
        ror     tmp1    ; Store sign in tmp1
        lsr     FR0
        jsr     FPI
        bcs     err3
        ldx     FR0+1
        bpl     ok
        ; Store error #3
err3:   lda     #3
        sta     IOERROR
        ; Negate result if original number was negative
ok:     lda     FR0
        ldy     tmp1
        bpl     pos
        jsr     neg_AX
        ; Store and pop FP stack
pos:    jsr     save_pop_fr1
        jmp     fp_return_interpreter
.endproc

.proc   EXE_PRINT_FP  ; PRINT (SP+)
        ; Store integer stack.
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     print_fp
        jsr     pop_fr0
        jmp     fp_return_interpreter
.endproc

.proc   EXE_FP_CMP      ; Compare two FP numbers in stack, store 0, -1 or 1 in integer stack
        jsr     pushAX
        jsr     save_pop_fr1::nosave
        jsr     FSUB
        ; TODO: Don't check FP errors, assume SUB can't fail in comparisons
        ldx     FR0
        jsr     pop_fr0
        txa
        ldy     sptr
        jmp     EXE_0
.endproc

.proc   EXE_FP_ADD
        jsr     save_pop_fr1
        jsr     FADD
        jmp     check_fp_err
.endproc

.proc   EXE_FP_SUB
        jsr     save_pop_fr1
        jsr     FSUB
        jmp     check_fp_err
.endproc

.proc   EXE_FP_MUL
        jsr     save_pop_fr1
        jsr     FMUL
        jmp     check_fp_err
.endproc

.proc   EXE_FP_DIV
        jsr     save_pop_fr1
        jsr     FDIV
        jmp     check_fp_err
.endproc

.proc   EXE_FP_ABS
        asl     FR0
lft:    lsr     FR0
        jmp     next_instruction
.endproc

.proc   EXE_FP_NEG
        asl     FR0
        beq     ok
        bcs     EXE_FP_ABS::lft
        sec
        ror     FR0
ok:     jmp     next_instruction
.endproc

.proc   EXE_FP_SGN
        asl     FR0
        beq     zero
        ldy     #$80
        sty     FR0
        ror     FR0
        ldy     #$10
        sty     FR0+1
        ldy     #0
        sty     FR0+2
        sty     FR0+3
        sty     FR0+4
        sty     FR0+5
zero:   jmp     next_instruction
.endproc

.proc   EXE_FLOAT
        jsr     save_push_fr0

        ldy     #5
ldloop: lda     (cptr), y
        sta     FR0,y
        dey
        bpl     ldloop

        lda     cptr
        clc
        adc     #6
        sta     cptr
        bcc     fp_return_interpreter
        inc     cptr+1
        bcs     fp_return_interpreter
.endproc

.proc   EXE_FP_VAL
        jsr     get_str_eol
        jsr     push_fr0
        jsr     read_fp
        bcc     :+
        lda     #18
        sta     IOERROR
:       jmp     pop_stack
.endproc

.proc   EXE_FP_LOAD
        stx     FLPTR+1
        sta     FLPTR
        jsr     push_fr0
        jsr     FLD0P
        jmp     pop_stack
.endproc

.proc   EXE_FP_STORE
        stx     FLPTR+1
        sta     FLPTR
        jsr     FST0P
        ; Pop FP stack
        jsr     pop_fr0
        jmp     pop_stack
.endproc

.proc   EXE_FP_EXP
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     EXP
        ; Fall through
.endproc

        ; Checks FP error, restores INT stack
        ; and returns to interpreter
.proc   check_fp_err
        ; Check error from last FP op
        bcc     ok
::fp_ret_err3:
        lda     #3
        sta     IOERROR
ok:     ; Fall through
.endproc
.proc   fp_return_interpreter
; Restore INT stack
        lda     fp_tmp_a
        ldx     fp_tmp_x
        jmp     next_instruction
.endproc

.proc   EXE_FP_EXP10
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     EXP10
        jmp     check_fp_err
.endproc

        ; Square Root: Copied from Altirra BASIC
        ; Copyright (C) 2015 Avery Lee, All Rights Reserved.
.proc   EXE_FP_SQRT
FPHALF= $DF6C
        sta     fp_tmp_a
        stx     fp_tmp_x

        ; Store original X
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FST0R

        lda     FR0
        beq     fp_return_interpreter   ; X=0, we are done
        bmi     fp_ret_err3     ; X<0, error 3

        ; Calculate new exponent: E' = (E-$40)/2+$40 = (E+$40)/2
        clc
        adc     #$40    ;!! - also clears carry for loop below
        sta     FR0

        ; Compute initial guess, using a table
        ldx     #9
        stx     tmp2   ;!! Also set 4 iterations (by asl)
        lda     #$00
guess_loop:
        adc     #$11
        dex
        ldy     approx_compare_tab,x
        cpy     FR0+1
        bcc     guess_loop
guess_ok:
        ; Divide exponent by two, use lower guess digit if even
        lsr     FR0
        bcs     no_tens
        and     #$0f
no_tens:
        sta     FR0+1

iter_loop:
        ; Y = (Y + X/Y) * (1/2)
        ldy     #>PLYARG
        ldx     #<PLYARG
        jsr     FST0R   ; PLYARG = Y
        jsr     FMOVE   ; FR1 = Y
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FLD0R   ; FR0 = X
        jsr     FDIV    ; FR0 = FR0/FR1 = X/Y
        ldy     #>PLYARG
        ldx     #<PLYARG
        jsr     FLD1R   ; FR1 = PLYARG = Y
        jsr     FADD    ; FR0 = FR0 + FR1 = X/Y + Y
        ldx     #<FPHALF
        ldy     #>FPHALF
        jsr     FLD1R   ; FR1 = 0.5
        jsr     FMUL    ; FR0 = FR0 * FR1 = (X/Y + Y)/2

        ;loop back until iterations completed
        asl     tmp2
        bpl     iter_loop
        bmi     fp_return_interpreter

approx_compare_tab:
        .byte   $ff,$87,$66,$55,$36,$24,$14,$07,$02
.endproc

.proc   EXE_FP_LOG
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     LOG
        jmp     check_fp_err
.endproc

.proc   EXE_FP_LOG10
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     LOG10
        jmp     check_fp_err
.endproc

        ; Computes FR0 ^ (AX)
.proc   EXE_FP_IPOW

        ; Store exponent
        sta     tmp1
        stx     tmp1+1

        ; If negative, get absolute value
        cpx     #$80
        bcc     ax_pos
        jsr     neg_AX
        ; Change mantisa to 1/X
        sta     tmp1
        stx     tmp1+1

        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FDIV

ax_pos:
        ; Skip all hi bits == 0
        ldy     #17
skip:
        dey
        beq     xit_1
        asl     tmp1
        rol     tmp1+1
        bcc     skip

        sty     tmp2
        ; Start with FR0 = X, store to PLYEVL
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FST0R
loop:
        ; Check exit
        dec     tmp2
        beq     xit

        ; Square, FR0 = x^2
        jsr     FMOVE
        jsr     FMUL
        bcs     error

        ; Check next bit
        asl     tmp1
        rol     tmp1+1
        bcc     loop

        ; Multiply, FR0 = FR0 * x
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FLD1R
        jsr     FMUL

        ; Continue loop
        bcc     loop
error:  lda     #3
        sta     IOERROR

xit_1:  jsr     FP_SET_1
xit:    jmp     pop_stack
.endproc

        ; Load 1.0 to FR0
.proc   FP_SET_1
        jsr     ZFR0
        lda     #$40
        sta     FR0
        lda     #$01
        sta     FR0+1
        rts
.endproc

        ; Returns a random FP number in the interval 0 <= X < 1
        ; Based on code from Altirra BASIC, (C) 2015 Avery Lee.
.proc   EXE_FP_RND
FPNORM=$DC00
        jsr     save_push_fr0

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
sin_coef:
        .byte $3E,$01,$51,$58,$00,$00
        .byte $BE,$46,$74,$16,$00,$00
        .byte $3F,$07,$96,$90,$12,$54
        .byte $BF,$64,$59,$63,$88,$21
pi1_2:
        .byte $40,$01,$57,$07,$96,$33
fp_90:
        .byte $40,$90,$00,$00,$00,$00
fp_180pi:
        .byte $40,$57,$29,$57,$79,$51

DEGFLAG_RAD = <pi1_2
DEGFLAG_DEG = <fp_90

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

        ; Save integer stack
        sta     fp_tmp_a
        stx     fp_tmp_x

        ; Divide by 90° or PI/2
        .assert (>pi1_2) = (>fp_90) , error, "PI/2 and 90 fp constants in different pages!"
        ldx     DEGFLAG
        ldy     #>pi1_2
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
        ldx     #<sin_coef
        ldy     #>sin_coef
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


        ; Compute arc-tangent of FR0
        ; Uses table of coefficients on ROM, shorter code,
        ; reduced as:  ATN(x) = PI/2 - ATN(1/x)  if |x|>1.0
        ;
.proc EXE_FP_ATN
        ; Save integer stack
        sta     fp_tmp_a
        stx     fp_tmp_x

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
        ldx     #<pi1_2
        ldy     #>pi1_2
        jsr     FLD1R
        jsr     FSUB
        bcc     test_deg

small_arg:

        jsr     eval_atn_poly
test_deg:
        ; Convert to degrees if needed:
        lda     DEGFLAG
        cmp     #DEGFLAG_DEG
        bne     not_deg

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

; vi:syntax=asm_ca65

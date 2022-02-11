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


; Square root
; -----------

        .import         check_fp_err
        .importzp       tmp2

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Square Root: Copied from Altirra BASIC
        ; Copyright (C) 2015 Avery Lee, All Rights Reserved.
.proc   EXE_FP_SQRT
FPHALF= $DF6C

        ; Store original X
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FST0R

        clc
        lda     FR0
        beq     xit     ; X=0, we are done
        sec
        bmi     xit     ; X<0, error 3

        ; Calculate new exponent: E' = (E-$40)/2+$40 = (E+$40)/2
        adc     #$3F    ;!! - also clears carry for loop below
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
        ; Note: carry is clear here, no error
xit:    jmp     check_fp_err

approx_compare_tab:
        .byte   $ff,$87,$66,$55,$36,$24,$14,$07,$02
.endproc

        .include "deftok.inc"
        deftoken "FP_SQRT"

; vi:syntax=asm_ca65

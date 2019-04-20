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


; FOR/NEXT and integer comparisons
; --------------------------------

        .import         pushAX
        .importzp       tmp3

        .include "toks.inc"

        ; NOTE: FOR_START is defined with DPOKE.

        ; FOR: First iteration, goes to FOR_NEXT but does not add STEP
        ;      to variable
.proc   EXE_FOR
        jsr     pushAX
        dey
        sec
        .byte   $90     ; BCC not taken, skips next CLC
.endproc                ; Fall through
        ; FOR_NEXT: Updates FOR variable (adding STEP), compares with
        ;           limit and jumps back to FOR body.
.proc   EXE_FOR_NEXT
        clc     ; Clear carry for ADC

        ; In stack we have:
        ;      sptr     y   = step
        ;      sptr+1   y+1 = limit
        ;      sptr+2   y+2 = var_address
        ; Read variable address value
        use_stack
        lda     stack_h+2, y
        sta     tmp3+1
        lda     stack_l+2, y
        sta     tmp3

        ; Adds STEP to VAR if not in first iteration
        lda     stack_l, y
        ldx     stack_h, y
        ; Store SIGN bit to temporary
        php

        ldy     #0

        bcc     do_add
        ; Set AX to -1 to skip the ADD (as we also add C=1)
        lda     #255
        tax
do_add:
        adc     (tmp3), y       ; 4  5
        sta     (tmp3), y       ; 5  6
        pha
        iny
        txa
        adc     (tmp3), y       ; 4  5
        sta     (tmp3), y       ; 5  6
        tax
        pla

        ; Now compare LIMIT with VAR
        ldy     sptr
        dec     sptr
        iny

        ; This uses the fact that GT and LT read the value using Y indexing
        ; and not SPTR, so we keep both pointing to different places!
        ; Before:
        ;      AX           = var_value
        ;      sptr     y-2 = UNUSED
        ;      sptr+1   y-1 = step
        ;      sptr+2   y   = limit
        ;      sptr+3   y+1 = var_address
        ; After GT/LT:
        ;      AX           = comparison result
        ;      sptr     y   = step
        ;      sptr+1   y+1 = limit
        ;      sptr+2   y+2 = var_address

        ; Check sign of STEP
        plp
        bmi     GT_skipsp
    .ifdef FASTBASIC_ASM
        bpl     LT_skipsp
    .else
        ; Fall through
    .endif
.endproc

.proc   EXE_LT  ; AX = (SP+) >= AX
        use_stack
::LT_skipsp:
        clc
        sbc     stack_l, y
        txa
        sbc     stack_h, y
        bvc     LTGT_set01
::LTGT_set10:
        bmi     set1
.endproc        ; fall-through

.proc   set0
        lda     #0
        tax
        sub_exit_incsp
.endproc

.proc   EXE_GT  ; AX = (SP+) <= AX
        use_stack
::GT_skipsp:
        cmp     stack_l, y
        txa
        sbc     stack_h, y
        bvc     LTGT_set10
::LTGT_set01:
        bmi     set0
.endproc        ; fall-through

.proc   set1
        lda     #1
        ldx     #0
        sub_exit_incsp
.endproc


.proc   EXE_NEQ  ; AX = AX != (SP+)
        use_stack
        cmp     stack_l, y
        bne     set1
        txa
        eor     stack_h, y
        bne     set1
        beq     set0
.endproc

.proc   EXE_EQ  ; AX = AX == (SP+)
        use_stack
        cmp     stack_l, y
        bne     set0
        txa
        eor     stack_h, y
        bne     set0
        beq     set1
.endproc

        deftoken "LT"
        deftoken "GT"
        deftoken "EQ"
        deftoken "NEQ"
        deftoken "FOR"
        deftoken "FOR_NEXT"

; vi:syntax=asm_ca65

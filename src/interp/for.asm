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


; FOR/NEXT and integer comparisons
; --------------------------------

        ; From interpreter.asm
        .importzp       next_instruction, next_ins_incsp, sptr
        .import         stack_l, stack_h, pushAX, EXE_DPOKE
        .import         pop_stack_3
        ; From runtime.asm
        .importzp       tmp1, tmp2, tmp3

        .segment        "RUNTIME"

        ; FOR_EXIT: Remove the FOR arguments from the stack!
EXE_FOR_EXIT    = pop_stack_3

        ; FOR_START: Stores starting value to FOR variable and
        ;            keeps the address in the stack.
.proc   EXE_FOR_START
        ; In stack we have:
        ;       AX = start value
        ;       y  = var_address
        dec     sptr    ; Keeps address into stack!
        jmp     EXE_DPOKE
.endproc

        ; FOR: First iteration, goes to FOR_NEXT but does not add STEP
        ;      to variable
.proc   EXE_FOR
        sec
        .byte   $24     ; Skip next CLC
.endproc                ; Fall through
        ; FOR_NEXT: Updates FOR variable (adding STEP), compares with
        ;           limit and jumps back to FOR body.
.proc   EXE_FOR_NEXT
        clc     ; Clear carry for ADC

        ; Store STEP into stack (and also to temporary)
        pha
        stx     tmp2+1
        jsr     pushAX

        ; In stack we have:
        ;      sptr     y-1 = step
        ;      sptr+1   y   = limit
        ;      sptr+2   y+1 = var_address
        ; Read variable address value
        lda     stack_h+1, y
        sta     tmp3+1
        lda     stack_l+1, y
        sta     tmp3

        ; Adds STEP to VAR if not in first iteration
        ldy     #0
        pla

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
        bit     tmp2+1
        bmi     EXE_GT
positive:
        ; Fall through
.endproc

.proc   EXE_LT  ; AX = (SP+) >= AX
        eor     #255
        sec
        adc     stack_l, y
        txa
        eor     #255
        adc     stack_h, y
        bvs     LTGT_set01
::LTGT_set10:
        bmi     set1
.endproc        ; fall-through

.proc   set0
        lda     #0
        tax
        jmp     next_ins_incsp
.endproc

.proc   EXE_GT  ; AX = (SP+) <= AX
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
        jmp     next_ins_incsp
.endproc


.proc   EXE_NEQ  ; AX = AX != (SP+)
        cmp     stack_l, y
        bne     set1
        txa
        eor     stack_h, y
        bne     set1
        tax
        jmp     next_ins_incsp
.endproc

.proc   EXE_EQ  ; AX = AX == (SP+)
        cmp     stack_l, y
        bne     set0
        txa
        eor     stack_h, y
        bne     set0
        beq     set1
.endproc

        .include "../deftok.inc"
        deftoken "LT"
        deftoken "GT"
        deftoken "EQ"
        deftoken "NEQ"
        deftoken "FOR"
        deftoken "FOR_START"
        deftoken "FOR_NEXT"
        deftoken "FOR_EXIT"

; vi:syntax=asm_ca65

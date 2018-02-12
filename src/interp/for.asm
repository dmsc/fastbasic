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
        .importzp       next_instruction, next_ins_incsp, cptr, sptr
        .import         stack_l, stack_h, pushAX, EXE_DPOKE
        .import         pop_stack_3
        ; From runtime.asm
        .importzp       tmp1, tmp2

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

        ; FOR: First iteration, stores STEP from stack and goes to NEXT.
.proc   EXE_FOR
        ; Store STEP into stack and HI part to temporary
        stx     tmp2+1
        jsr     pushAX

        ; Jumps to original FOR with a fake STEP=0, skips the
        ; first addition:
        ldx     #0
        stx     tmp2
        beq     EXE_FOR_NEXT_INIT
.endproc

        ; FOR_NEXT: Updates FOR variable (adding STEP), compares with
        ;           limit and jumps back to FOR body.
.proc   EXE_FOR_NEXT
        ; Store STEP into stack (and also to temporary)
        sta     tmp2
        stx     tmp2+1
        jsr     pushAX

::EXE_FOR_NEXT_INIT:
        ; In stack we have:
        ;       y-1 = step
        ;       y   = limit
        ;       y+1 = var_address
        ; Read variable address value
        lda     stack_h+1, y
        sta     tmp1+1
        lda     stack_l+1, y
        sta     tmp1

        ; Copy LIMIT to the stack
        lda     stack_l, y
        sta     stack_l-2, y
        lda     stack_h, y
        sta     stack_h-2, y
        dec     sptr

        ; Get STEP again into AX
        lda     tmp2

        ; Adds STEP to VAR
        clc
        ldy     #0
        adc     (tmp1), y
        sta     (tmp1), y
        pha
        iny
        txa
        adc     (tmp1), y
        sta     (tmp1), y
        tax
        pla

        ; Now we have LIMIT and VAR in stack, compare
        ldy     sptr

        ; Check sign of STEP
        bit     tmp2+1
        bmi     EXE_GT
positive:
        ; Fall through
.endproc

.proc   EXE_LT  ; AX = (SP+) >= AX
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        cmp     tmp1
        lda     stack_h, y
        sbc     tmp1+1
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

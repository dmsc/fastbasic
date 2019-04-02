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


; The opcode interpreter
; ----------------------

        .export         interpreter_run, stack_l, stack_h
        .export         pushAX, stack_end

        .exportzp       interpreter_cptr, sptr, cptr
        .exportzp       next_ins_incsp, next_instruction
        .exportzp       tabpos, IOCHN, IOERROR, COLOR, tmp1, tmp2, tmp3, divmod_sign

        ; From clearmem.asm
        .import         clear_data, saved_cpu_stack

        ; From jumptab.asm
        .import         __JUMPTAB_RUN__

        ; From soundoff.asm
        .import         sound_off

        .include "atari.inc"

        .zeropage
tmp1:   .res    2
tmp2:   .res    2
tmp3:   .res    2
.ifdef NO_SMCODE
        .exportzp       tmp4
tmp4:   .res    2
.endif
divmod_sign:
        .res    1
IOCHN:  .res    1
IOERROR:.res    1
COLOR:  .res    1
tabpos: .res    1


        ; Integer stack, 40 * 2 = 80 bytes
.define STACK_SIZE      40
        ; Our execution stack 64 words max, aligned for maximum speed
stack_l =       $480
stack_h =       $480 + STACK_SIZE
stack_end =     stack_h + STACK_SIZE

;----------------------------------------------------------------------

; This is the main threaded interpreter, jumps to the next
; execution opcode from the opcode-stream.
;
; To execute faster, the code is run from page zero, using 16 bytes
; that include the pointer (at the "cload: LDY" instruction). The A
; and X registers are preserved across calls, and store the top of
; the 16bit stack. The Y register is loaded with the stack pointer
; (sptr).
;
; All the execution routines jump back to the next_instruction label,
; so the minimum time for an opcode is 30 cycles, this means we could
; execute at up to 58k opcodes per second.
;
        ; Code in ZP: (16 bytes)
        .segment "INTERP": zeropage
.proc   interpreter
nxt_incsp:
        inc     z:sptr
nxtins:
cload:  ldy     $1234           ;4
        inc     z:cload+1       ;5
        bne     adj             ;2
        inc     z:cload+2       ;1 (1 * 255 + 5 * 1) / 256 = 1.016
adj:    sty     z:jump+1        ;3
ldsptr: ldy     #0              ;2
jump:   jmp     (__JUMPTAB_RUN__);5 = 27 cycles per call

.endproc

sptr                    =       interpreter::ldsptr+1
cptr                    =       interpreter::cload+1
next_instruction        =       interpreter::nxtins
next_ins_incsp          =       interpreter::nxt_incsp
interpreter_cptr        =       cptr

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

        ; Main interpreter call
        ;  AX : address of code start
        ;   Y : number of variables
.proc   interpreter_run

        ; Init code pointer
        sta     cptr
        stx     cptr+1

        ; Get memory for all variables and clear the values
        jsr     clear_data

        ; Close al I/O channels
        lda     #$70
:       tax
        lda     #CLOSE
        sta     ICCOM, x
        jsr     CIOV
        txa
        sec
        sbc     #$10
        bne     :-

        ; Clear TAB position, IO channel and IO error
        ; Also clears location 0 to allow a null-pointer representation
        ; for an empty string (length = 0).
        ;
        ; lda     #0  ; A == 0 from above
        sta     tabpos
        sta     IOCHN
        sta     IOERROR
        sta     0
.ifdef FASTBASIC_FP
        .importzp       DEGFLAG
        sta     DEGFLAG
.endif ; FASTBASIC_FP

        ; Sound off
        jsr     sound_off

        ; Store current stack position to rewind on error
        tsx
        stx     saved_cpu_stack

        ; Init stack-pointer
        lda     #STACK_SIZE
        sta     sptr
.ifdef FASTBASIC_FP
        .importzp       fptr, FPSTK_SIZE
        lda     #FPSTK_SIZE
        sta     fptr
.endif ; FASTBASIC_FP

        ; Interpret opcodes
        jmp     next_instruction
.endproc

        ; Stores AX into stack, at return Y is the stack pointer.
.proc   pushAX
        sta     stack_l-1, y
        txa
        sta     stack_h-1, y
        dec     sptr            ; Note: PUSH_0 depends on return with Z flag not set!
        rts
.endproc

;.proc   EXE_DUP
;        jsr     pushAX
;        lda     stack_l-1, y
;        ldx     stack_h-1, y
;        jmp     next_instruction
;.endproc

; vi:syntax=asm_ca65

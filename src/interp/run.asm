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

        .export         interpreter_run
        .export         stack_l, stack_h, stack_end
        .exportzp       tabpos, IOCHN, IOERROR, tmp1, tmp2, tmp3, divmod_sign

        .importzp       sptr, cptr, next_instruction
        .import         clear_data, saved_cpu_stack, sound_off, bytecode_start

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
tabpos: .res    1


        ; Integer stack, 40 * 2 = 80 bytes
STACK_SIZE = 40
        ; Our execution stack 64 words max, aligned for maximum speed
stack_l =       $480
stack_h =       $480 + STACK_SIZE
stack_end =     stack_h + STACK_SIZE

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

        ; Main interpreter call
        ;  AX : address of code start
        ;   Y : number of variables
.proc   interpreter_run

    .ifndef FASTBASIC_ASM
        ; Init code pointer
        sta     cptr
        stx     cptr+1
    .endif

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

    .ifndef FASTBASIC_ASM
        ; Interpret opcodes
        jmp     next_instruction
    .else
        ; Jump to native code
        jmp     bytecode_start
    .endif
.endproc

; vi:syntax=asm_ca65

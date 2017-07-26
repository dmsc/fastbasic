;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017 Daniel Serpell
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

; Main menu system
; ----------------

        .export start, COMPILE_BUFFER
        .export BMAX
        .exportzp       reloc_addr

        ; From runtime.asm
        .import putc
        .importzp IOCHN, IOERROR, tabpos
        ; From parser.asm
        .import parser_start
        .importzp buf_ptr, linenum, end_ptr, bpos, bmax
        ; From intrepreter.asm
        .import interpreter_run, saved_cpu_stack
        .importzp interpreter_cptr
        ; From alloc.asm
        .importzp  prog_ptr, var_buf
        .import parser_alloc_init
        ; From vars.asm
        .importzp  var_count
        ; From bytecode
        .import bytecode_start
        .importzp NUM_VARS
        ; Linker vars
        .import __BSS_RUN__, __BSS_SIZE__, __INTERP_START__, __INTERP_SIZE__
        .import __JUMPTAB_RUN__, __RUNTIME_RUN__, __RUNTIME_SIZE__

        .include "atari.inc"

        ; Start of HEAP
heap_start=     __BSS_RUN__+__BSS_SIZE__
        ; Start of relocated bytecode
BYTECODE_ADDR=  __RUNTIME_RUN__ + __RUNTIME_SIZE__

        .zeropage
        ; Relocation amount
reloc_addr:     .res    2

BMAX=bmax
        .code

start:
        lda     #0
        sta     IOCHN
        sta     tabpos

        jsr     load_editor

        lda     #<bytecode_start
        ldx     #>bytecode_start
        jsr     interpreter_run
        jmp     (DOSVEC)

        ; Called from editor
COMPILE_BUFFER:
        lda     #0
        sta     reloc_addr
        sta     reloc_addr+1

        ; Buffer end pointer
        pla
        sta     end_ptr+1
        tay
        pla
        sta     end_ptr
        jsr     parser_alloc_init
        ; Buffer address
        pla
        sta     buf_ptr+1
        pla
        sta     buf_ptr

        ; Compile / Run
        pla
        pla
        sta     do_run+1
        beq     no_save

        ; We need to relocate the bytecode, calculate the offset:
        lda     #<BYTECODE_ADDR
        sec
        sbc     end_ptr
        sta     reloc_addr
        lda     #>BYTECODE_ADDR
        sbc     end_ptr+1
        sta     reloc_addr+1
no_save:

        ; Save interpreter position
        lda     bpos
        pha

        ; Parse
        jsr     parser_start
        bcs     err

        lda     prog_ptr
        sta     COMP_END
        clc
        adc     reloc_addr
        sta     compiled_prog_ptr1+1
        sta     COMP_HEAD_2+2
        lda     prog_ptr+1
        sta     COMP_END+1
        adc     reloc_addr+1
        sta     compiled_prog_ptr2+1
        sta     COMP_HEAD_2+3
        lda     var_count
        sta     compiled_var_count+1

do_run: ldx     #$00
        bne     clr_linenum

        ; Runs current parsed program
run_program:
        lda     interpreter_cptr
        pha
        lda     interpreter_cptr+1
        pha
        lda     saved_cpu_stack
        pha

        lda     #125
        jsr     putc

        lda     end_ptr
        ldx     end_ptr+1
        jsr     interpreter_run

        pla
        sta     saved_cpu_stack
        pla
        sta     interpreter_cptr+1
        pla
        sta     interpreter_cptr

clr_linenum:
        ldx     #0
        stx     linenum+1
        stx     linenum

err:    jsr     load_editor

        pla
        sta     bpos
        lda     linenum
        ldx     linenum+1
        rts

        ; Load all pointer to execute the editor
load_editor:
        lda     #NUM_VARS
        sta     var_count
        lda     #<heap_start
        sta     prog_ptr
        sta     var_buf
        lda     #>heap_start
        sta     prog_ptr+1
        sta     var_buf+1
        rts


        ; This is the header for the compiled binaries, included
        ; here to allow saving the resulting file.
        .export COMP_HEAD_1
COMP_HEAD_1:
        .byte   255, 255
        .word   __INTERP_START__
        .word   __INTERP_START__ + __INTERP_SIZE__- 1

        .export COMP_HEAD_2
COMP_HEAD_2:
        .word   __JUMPTAB_RUN__
        .word   0

        .export COMP_END
COMP_END:
        .word   0

        .export COMP_TRAILER
COMP_TRAILER:
        .word   RUNAD
        .word   RUNAD+1
        .word   compiled_start

        ; Number of bytes to write in RUNTIME + JUMPTAB segments
        .export COMP_RT_SIZE
COMP_RT_SIZE = __RUNTIME_RUN__ + __RUNTIME_SIZE__ - __JUMPTAB_RUN__

        ; This is the runtime startup code, copied into the resulting
        ; executables.
        ; Note that this code is patched before writing to a file.
        .segment        "RUNTIME"
compiled_start:
        lda     #0
        sta     IOCHN
        sta     tabpos

compiled_var_count:
        lda     #00
        sta     var_count
compiled_prog_ptr1:
        lda     #00
        sta     prog_ptr
compiled_prog_ptr2:
        lda     #00
        sta     prog_ptr+1

        lda     #<BYTECODE_ADDR
        ldx     #>BYTECODE_ADDR
        jsr     interpreter_run
        jmp     (DOSVEC)

; vi:syntax=asm_ca65

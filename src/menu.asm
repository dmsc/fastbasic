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
        .import   __BSS_RUN__, __BSS_SIZE__

        .include "atari.inc"

        ; Start of HEAP
heap_start=     __BSS_RUN__+__BSS_SIZE__

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
        ; Save interpreter position
        lda     bpos
        pha
        ; Parse
        jsr     parser_start
        bcs     err

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

        ldx     #0
        stx     linenum+1
        inx
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

; vi:syntax=asm_ca65

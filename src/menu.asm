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

; Main menu system
; ----------------

        .export start

        ; Export and imports from editor.bas
        .export COMPILE_BUFFER, BMAX, LINENUM, heap_start
        .exportzp       reloc_addr
        .import fb_var_NEWPTR

        ; From runtime.asm
        .import putc
        .importzp IOCHN, IOERROR, tabpos, tmp1, tmp2
        ; From parser.asm
        .import parser_start
        .importzp buf_ptr, linenum, end_ptr, bmax
        ; From intrepreter.asm
        .import interpreter_run, saved_cpu_stack, stack_h, stack_l
        .importzp interpreter_cptr, var_count, sptr
        ; From alloc.asm
        .importzp  prog_ptr, var_page
        .import parser_alloc_init
        ; From bytecode
        .import bytecode_start
        .importzp NUM_VARS
        ; Linker vars
        .import __BSS_RUN__, __BSS_SIZE__, __INTERP_START__, __INTERP_SIZE__
        .import __JUMPTAB_RUN__, __RUNTIME_RUN__, __RUNTIME_SIZE__

        .include "atari.inc"

        ; Start of HEAP - aligned to 256 bytes
heap_start=    ( __BSS_RUN__+__BSS_SIZE__ + 255 ) & $FF00
        ; Start of relocated bytecode
BYTECODE_ADDR=  __RUNTIME_RUN__ + __RUNTIME_SIZE__

        .zeropage
        ; Relocation amount
reloc_addr:     .res    2


        ; Exported to EDITOR.BAS
BMAX=bmax
LINENUM=linenum

        .code

start:
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

        ; Compile / Run
        pla
        pla
        tax
        beq     no_save

        ; We need to relocate the bytecode, calculate the offset:
        lda     #<BYTECODE_ADDR
        sec
        sbc     end_ptr
        tax
        lda     #>BYTECODE_ADDR
        sbc     end_ptr+1
no_save:
        stx     reloc_addr
        sta     reloc_addr+1

        ; Save our CPU return stack
        lda     saved_cpu_stack
        pha

        ; Parse
        jsr     parser_start

        ldx     #$FE
        bcs     load_editor_stack ; On error, exit returning <> 0 (0xFEFE)

        ; Loops 2 times with X=$FE and X=$FF, exits with X=0
        ; C = clear and X = $FE on enter
sto_loop:
        tay
        lda     <(prog_ptr - $FE),x
        sta     fb_var_NEWPTR - $FE,x
        adc     <(reloc_addr - $FE),x
        sta     COMP_HEAD_2+2 - $FE,x
        inx
        bne     sto_loop

        ; AY = end of program code + 1, start of heap
        ; Align up to 256 bytes
        cpy     #1
        adc     #0
        sta     compiled_var_page+1
        sta     var_page

        lda     var_count
        sta     compiled_var_count+1

        ; Check if need to run program, only if not relocated
        lda     reloc_addr + 1
        bne     load_editor_stack ; Exit returning X = 0 (from loop above)

        ; Runs current parsed program
run_program:
        ; Save interpreter position
        ; Current EDITOR.BAS does not need saving of stack
        lda     sptr
        pha
        lda     interpreter_cptr
        pha
        lda     interpreter_cptr+1
        pha

        lda     #125
        jsr     putc

        lda     end_ptr
        ldx     end_ptr+1
        jsr     interpreter_run

        pla
        sta     interpreter_cptr+1
        pla
        sta     interpreter_cptr
        pla
        sta     sptr

        ; Exit to editor returning 0
        ldx     #0

        ; Restore saved CPU stack
load_editor_stack:
        pla
        sta     saved_cpu_stack

        ; X = result, copy to A also
        txa

        ; Load all pointer to execute the editor
        ; Does not modify A/X
load_editor:
        ldy     #NUM_VARS
        sty     var_count
        ldy     #>heap_start
        sty     var_page
        rts


        ; Called from EDITOR.BAS
        .export COUNT_LINES
.proc   COUNT_LINES
sizeH   = tmp1
ptr     = tmp2
        pla
        sta     sizeH
        pla
        tax
        pla
        sta     ptr+1
        pla
        tay
        inx
        inc     sizeH

        lda     #0
        sta     ptr

loop:   lda     (ptr), y
        dex
        bne     :+
        dec     sizeH
        beq     end
:       iny
        bne     :+
        inc     ptr+1
:       cmp     #$9B
        bne     loop
end:    tya
        ldx     ptr+1
        rts
.endproc

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

compiled_var_count:
        lda     #00
        sta     var_count
compiled_var_page:
        lda     #00
        sta     var_page

        lda     #<BYTECODE_ADDR
        ldx     #>BYTECODE_ADDR
        jsr     interpreter_run
        jmp     (DOSVEC)

; vi:syntax=asm_ca65

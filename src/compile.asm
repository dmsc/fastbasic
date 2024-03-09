;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2024 Daniel Serpell
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

; Calls the compiler from the editor
; ----------------------------------

        ; Export and imports from editor.bas
        .export COMPILE_BUFFER, BMAX, LINENUM
        .import fb_var_NEWPTR

        ; From header
        .import COMP_HEAD_2, __HEAP_RUN__

        ; From runtime.asm
        .import putc
        ; From JUMP
        .import interpreter_jump_fixup
        ; From parser.asm
        .import parser_start
        .importzp buf_ptr, linenum, end_ptr, bmax, reloc_addr
        ; From intrepreter.asm
        .import interpreter_run, compiled_num_vars, compiled_var_page, var_page
        .importzp interpreter_cptr, var_count, sptr, saved_cpu_stack
        ; From alloc.asm
        .importzp  prog_ptr
        .import parser_alloc_init
        ; From bytecode
        .import bytecode_start

        .include "atari.inc"

        ; Exported to EDITOR.BAS
BMAX=bmax
LINENUM=linenum
        .exportzp RELOC_OFFSET
RELOC_OFFSET = reloc_addr


        ; Our BREAK key handler, placed in DATA segment, as it is modified
        ; during runtime.
        .data
break_irq:
        ; Force exit from interpreter - stop at next JUMP
        lda     #$2C    ; BIT abs (skips)
        sta     interpreter_jump_fixup
        ; Jump to original handler
brkky_save = *+1
        jmp     $FFFF

new_brkky:
        .word   break_irq

        ; Compile current buffer, called from the editor
        .code
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
        ; Save low ending address into Y register, needed after the loop
        tay

        ; Also save BRKKY vector and instal our own vector
        lda     BRKKY - $FE, x
        sta     brkky_save - $FE, x
        lda     new_brkky - $FE, x
        sta     BRKKY - $FE, x

        ; Copy program pointer to the "NEWPTR" editor variable
        lda     <(prog_ptr - $FE),x     ; prog_ptr is ZP
        sta     fb_var_NEWPTR - $FE,x
        ; And store relocated into the new header
        adc     <(reloc_addr - $FE),x   ; reloc_addr is ZP
        sta     COMP_HEAD_2+2 - $FE,x

        inx
        bne     sto_loop

        ; AY = end of program code + 1, start of heap
        ; Align up to 256 bytes
        cpy     #1
        adc     #0
        sta     compiled_var_page

        lda     var_count
        sta     compiled_num_vars

        ; Check if need to run program, only if not relocated
        lda     reloc_addr + 1
        bne     restore_break ; Exit returning X = 0 (from loop above)

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

        ; Reload var_page, as it was overwritten by interpreter_run
        lda     #>__HEAP_RUN__
        sta     var_page

restore_break:
        ; Restore original BREAK key handler and sets X = 0
        ldx     #2
rbreak_loop:
        lda     brkky_save-1, x
        sta     BRKKY-1, x
        dex
        bne     rbreak_loop

        ; Restore JUMP on interpreter
        lda     #$4C    ; JMP abs
        sta     interpreter_jump_fixup

        ; Restore saved CPU stack
load_editor_stack:
        pla
        sta     saved_cpu_stack

        ; X = result, copy to A also
        txa

        ; Load all pointer to execute the editor
        ; Does not modify A/X
load_editor:
        rts


; vi:syntax=asm_ca65

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

; Command line compiler
; ---------------------

        ; Export and imports from cmdline.bas
        .export COMPILE_BUFFER, BMAX, LINENUM
        .import fb_var_NEWPTR

        ; From header
        .import COMP_HEAD_2

        ; From parser.asm
        .import parser_start
        .importzp buf_ptr, linenum, end_ptr, bmax, reloc_addr
        ; From intrepreter.asm
        .import compiled_num_vars, compiled_var_page
        .importzp var_count, saved_cpu_stack
        ; From alloc.asm
        .importzp  prog_ptr
        .import parser_alloc_init
        ; From bytecode
        .import bytecode_start
        .importzp NUM_VARS

        ; Exported to CMDLINE.BAS
BMAX=bmax
LINENUM=linenum
        .exportzp RELOC_OFFSET
RELOC_OFFSET = reloc_addr

        .code
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

        ; Save our CPU return stack
        lda     saved_cpu_stack
        pha

        ; Parse
        jsr     parser_start

        ldx     #$FE
        bcs     load_program_stack ; On error, exit returning <> 0 (0xFEFE)

        ; Loops 2 times with X=$FE and X=$FF, exits with X=0
        ; C = clear and X = $FE on enter
sto_loop:
        ; Save low ending address into Y register, needed after the loop
        tay
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

        ; Exit to editor returning X=0 (from loop above)

        ; Restore saved CPU stack
load_program_stack:
        pla
        sta     saved_cpu_stack

        ; X = result, copy to A also
        txa

        ; Load all pointer to execute the basic program
        ; Does not modify A/X
load_program:
        rts


; vi:syntax=asm_ca65

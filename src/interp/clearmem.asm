;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2025 Daniel Serpell
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


; Clear Memory
; ------------

        .export         clear_data, alloc_array, mem_set, err_nomem, mem_set_0
        .export         compiled_num_vars, compiled_var_page, CLEAR_DATA
        .exportzp       saved_cpu_stack

        .import         putc, var_page, __HEAP_RUN__, __HEAP_SIZE__
        .importzp       tmp1, array_ptr, move_dest

        .include        "target.inc"

        ; Start of HEAP - aligned to 256 bytes
        .assert (<__HEAP_RUN__) = 0, error, "Heap must be page aligned"

        ; Allocation size
alloc_size=     tmp1

        ; Uppercase to export as FastBasic symbol
CLEAR_DATA = clear_data

        ; ZP location to save the old CPU stack
        .zeropage
saved_cpu_stack:
        .res    1

;----------------------------------------------------------
; Following routines are part of the runtime
        .segment        "RUNTIME"

        ; Clears data pointers before starting the interpreter
.proc   clear_data
        ; Init all pointers to end of program data
        ldx     #0
        lda     #>__HEAP_RUN__
        ;
        ; Note: this is only necessary so that the IDE and command line
        ;       compilers can use a different address for the variables
        ;       than the compiled program - so we can't overwrite the
        ;       "var_page" from the compiler and we must do it on runtime.
::compiled_var_page=*-1
        sta     var_page

        stx     array_ptr
        sta     array_ptr+1
        ; Allocate and clear 2 bytes of memory for each variable
        ; ldx #0        ;  X already 0
        ; This value will be patched with the number of variables in the program
        ; in the IDE and native compilers
        .assert __HEAP_SIZE__ < 512, error, "error, variable heap must be < 512 bytes"
        lda     #<(__HEAP_SIZE__/2)
::compiled_num_vars=*-1
        asl
        bcc     :+
        inx
:
.endproc        ; Fall through

        ; Allocate space for a new array AX = SIZE
        ; Returns: pointer to allocated memory in MOVE_DEST
        ;          size of allocated memory in ALLOC_SIZE
        ;          X=0 and Y=0
.proc alloc_array

        sta     alloc_size
        stx     alloc_size + 1

        lda     array_ptr
        sta     move_dest
        clc
        adc     alloc_size
        sta     array_ptr
        tay

        lda     array_ptr+1
        sta     move_dest+1
        adc     alloc_size+1
        sta     array_ptr+1
        bcs     err_nomem

        cpy     MEMTOP
        sbc     MEMTOP+1
        bcs     err_nomem

        ; Clears memory from (move_dest) of (alloc_size) size
::mem_set_0:
        ldy     #0      ; Value to set

::mem_set:
        txa     ; X = (alloc_size+1)
        clc
        adc     move_dest+1
        sta     move_dest+1
        tya
        inx
        ldy     alloc_size
        beq     nxt
;        .byte   $2C   ; Skip 2 bytes over next "DEC"
        bne     loop    ; Prefer branch, is faster

pgloop: dec     move_dest+1
loop:   dey
        sta     (move_dest), y
        bne     loop

nxt:    dex
        bne     pgloop

        rts
.endproc

        .import interpreter_jump_ax
        .importzp TOK_CSTRING, TOK_PRINT_STR, TOK_END

; Code for printing memory error message
memory_error_code:
        .byte   TOK_CSTRING, 14, $9b, "Memory Error", $9b
        .byte   TOK_PRINT_STR, TOK_END

err_nomem:
        lda     #<memory_error_code
        ldx     #>memory_error_code
        jmp     interpreter_jump_ax

; vi:syntax=asm_ca65

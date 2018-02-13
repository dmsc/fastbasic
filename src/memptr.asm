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


; Memory functions
; ----------------

; The memory areas are arranged as:
;  prog_ptr:    -> current program output pos
;               Buffer zone (at least 0x100 free bytes)
;  array_buf:   STRING/ARRAY AREA
;  array_ptr:   -> next available pos
;  var_buf:     VARIABLE TABLE AREA (during parsing) and VARIABLE VALUE AREA
;               (during interpreting)
;  var_ptr:     -> next available pos
;  top_mem:     TOP OF MEMORY
;
        .export         add_pointers
        .exportzp       prog_ptr, array_ptr, var_buf, var_ptr, mem_end
        .exportzp       label_buf, label_ptr, laddr_buf, laddr_ptr

        ; From runtime.asm
        .import         move_dwn_src, move_dwn_dst, move_dwn, putc
        .importzp       tmp1, tmp2
        ; From interpreter.asm
        .importzp       var_count
        .import         EXE_END

        .zeropage

        ;           During Parsing           During Execution
        ;           ---------------------------------------------
        ; Pointer to program buffer        / current program
mem_start:
prog_ptr:       .res    2
prog_end:       .res    2
        ; Pointer to variable name table   / variable value table
var_buf=        prog_end
var_ptr:        .res    2
var_end=        var_ptr
        ; Pointer to labels name table     / strings/arrays table
array_buf=      var_end
array_ptr:      .res    2
array_end=      array_ptr
label_buf=      array_buf
label_ptr=      array_ptr
label_end=      array_end
        ; Pointer to labels address table  / unused at runtime
laddr_buf=      array_end
laddr_ptr:      .res    2
        ; End of used memory
mem_end=        laddr_ptr
        ; Allocation size
alloc_size=     tmp1

;----------------------------------------------------------
; Following routines are part of the runtime
        .segment        "RUNTIME"

        ; Increase all pointers from "Y" to the last by AX
.proc   add_pointers
loop:   clc
        lda     mem_start, x
        adc     alloc_size
        sta     mem_start, x
        inx
        lda     mem_start, x
        adc     alloc_size+1
        sta     mem_start, x
        inx
        cpx     #mem_end - mem_start + 2
        bne     loop
        clc
        rts
.endproc

; vi:syntax=asm_ca65

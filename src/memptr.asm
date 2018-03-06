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

        .exportzp       prog_ptr, array_ptr, var_buf, var_ptr, mem_end
        .exportzp       label_buf, label_ptr, laddr_buf, laddr_ptr

        .zeropage

        ; Note that the memory pointers are shared between parser and runtime,
        ; so that less zeropage memory is used.
        ;
        ;           During Parsing           During Execution
        ;           ---------------------------------------------
        ; Pointer to program buffer        / UNUSED
mem_start:
prog_ptr:       .res    2
        ; Pointer to variable name table   / variable value table
var_buf:        .res    2
var_ptr=        array_buf
        ; Pointer to labels name table     / strings/arrays table
array_buf:      .res    2
label_buf=      array_buf
array_ptr=      laddr_buf
label_ptr=      laddr_buf
        ; Pointer to labels address table  / end of string/arrays table,
        ;                                    top of used memory
laddr_buf:      .res    2
laddr_ptr=      mem_end
        ; End of used memory
mem_end:        .res    2

; vi:syntax=asm_ca65

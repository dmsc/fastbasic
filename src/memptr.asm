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


; Parser Memory Areas
; -------------------

        .exportzp       prog_ptr, array_ptr, var_buf, var_ptr, mem_end
        .exportzp       label_buf, label_ptr, laddr_buf, laddr_ptr, end_ptr

        .segment "IDEZP": zeropage

        ; End of program to parse
end_ptr:        .res    2
        ; Pointer to end of program buffer
prog_ptr:       .res    2
        ; Pointers to start / end of variable name table
var_buf:        .res    2
var_ptr=        label_buf
        ; Pointers to start / end of labels name table
label_buf:      .res    2
label_ptr=      laddr_buf
        ; Pointers to start / end of labels address table
laddr_buf:      .res    2
laddr_ptr=      mem_end
        ; End of parser memory
mem_end:        .res    2

        ; Share this to BASIC runtime, to use less ZP memory
        .exportzp       BASIC_TOP
array_ptr=      laddr_buf
BASIC_TOP= array_ptr

; vi:syntax=asm_ca65

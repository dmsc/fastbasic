;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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


; MSET: sets a range of memory to a value
; ---------------------------------------

        .import         stack_l, stack_h, next_ins_incsp_2, mem_set
        .importzp       tmp1, tmp2

        .segment        "RUNTIME"

.proc   EXE_MSET

        ldx     stack_l+1, y
        stx     tmp2
        ldx     stack_h+1, y
        stx     tmp2+1

        ldx     stack_l, y
        stx     tmp1
        ldx     stack_h, y

        tay             ; Store value to set into Y
        jsr     mem_set

        jmp     next_ins_incsp_2
.endproc

        .include "deftok.inc"
        deftoken "MSET"

; vi:syntax=asm_ca65

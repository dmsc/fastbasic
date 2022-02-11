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
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; Floating Point comparison
; -------------------------

        .import         pop_fr0, pop_fr1, pushXX_set0

        .include "atari.inc"

        .segment        "RUNTIME"

        ; Compare two FP numbers in stack, store 0, -1 or 1 in integer stack
        ; This is equivalent to INT(SGN(A - B)) and push a 0.
.proc   EXE_FP_CMP
        jsr     pop_fr1
        jsr     FSUB
        ; TODO: Don't check FP errors, assume SUB can't fail in comparisons
        ldx     FR0
        jsr     pop_fr0
        jmp     pushXX_set0
.endproc

        .include "deftok.inc"
        deftoken "FP_CMP"

; vi:syntax=asm_ca65

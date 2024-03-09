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
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; Reads an 8-bit value from an address
; ------------------------------------

        .importzp       next_instruction, tmp1

        .segment        "RUNTIME"

.proc   EXE_PEEK  ; AX = *(AX)
.ifdef NO_SMCODE
        sta     tmp1
        stx     tmp1+1
        ldx     #0
        lda     (tmp1,x)        ; 13 cycles, 8 bytes
.else
        ; Self-modifying code, 1 cycle faster and 1 byte larger than the above
        stx     load+2
        tax
load:   lda     $FF00, x
        ldx     #0              ; 12 cycles, 9 bytes
.endif
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "PEEK"

; vi:syntax=asm_ca65

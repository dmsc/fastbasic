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


; Writes an 8-bit value to an address
; -----------------------------------

        ; From interpreter.asm
        .import         stack_l, stack_h
        .importzp       next_ins_incsp
        ; From runtime.asm
        .importzp       tmp1

        .segment        "RUNTIME"

.proc   EXE_POKE  ; POKE (SP++), AX
        tax
        lda     stack_h, y
.if 0
        sta     tmp1+1
        lda     stack_l, y
        sta     tmp1
        txa
        ldy     #0
        sta     (tmp1), y
.else
        ; Self-modifying code, 2 cycles faster and 2 bytes shorter than the above
        sta     save+2
        txa
        ldx     stack_l, y
save:   sta     $FF00, x
.endif
        jmp     next_ins_incsp
.endproc

        .include "../deftok.inc"
        deftoken "POKE"

; vi:syntax=asm_ca65

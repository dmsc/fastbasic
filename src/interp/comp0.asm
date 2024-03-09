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


; Boolean constants and conversion
; --------------------------------

        .export         pushXX_set0
        .import         stack_l, stack_h, pushAX
        .importzp       next_instruction, sptr

        .segment        "RUNTIME"

        ; Pushes X as "comparison return" into stack.
.proc   pushXX_set0
        ldy     sptr
        txa
.endproc        ; Fall through

.proc   EXE_PUSH_0; push AX, load 0
        jsr     pushAX
.endproc        ; Fall through

.proc   EXE_0
        lda     #0
        tax
        jmp     next_instruction
.endproc

.proc   EXE_PUSH_1; push AX, load 1
        jsr     pushAX
.endproc        ; Fall through

.proc   EXE_1
        lda     #1
        ldx     #0
        jmp     next_instruction
.endproc

.proc   EXE_COMP_0  ; AX = AX != 0
        tay
        bne     EXE_1
        txa
        bne     EXE_1
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "COMP_0"
        deftoken "0"
        deftoken "1"
        deftoken "PUSH_1"
        deftoken "PUSH_0"

; vi:syntax=asm_ca65

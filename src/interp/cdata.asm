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


; Read constant data
; ------------------

        ; From interpreter.asm
        .import         EXE_JUMP, stack_l, stack_h
        .importzp       cptr, sptr, tmp1

        .segment        "RUNTIME"

.proc   EXE_CDATA       ; *(SP) = address of data

        ; Store (cptr) + 2 to var address
        lda     stack_h, y
        sta     tmp1+1
        lda     stack_l, y
        sta     tmp1

        ldy     #0
        lda     cptr
        clc
        adc     #2
        sta     (tmp1), y
        iny
        lda     cptr+1
        adc     #0
        sta     (tmp1), y

        ; ldy     sptr ; EXE_JUMP does not use Y=sptr
        inc     sptr
        jmp     EXE_JUMP
.endproc

        .include "../deftok.inc"
        deftoken "CDATA"

; vi:syntax=asm_ca65

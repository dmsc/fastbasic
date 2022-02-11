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


; Increment a memory location
; ---------------------------

        .import         get_op_var
        .importzp       next_instruction, saddr

        .segment        "RUNTIME"

EXE_INCVAR:     ; VAR = VAR + 1
        jsr     get_op_var

.proc   EXE_INC ; *(AX) = *(AX) + 1
.ifdef NO_SMCODE
        sta     saddr
        stx     saddr+1
        ; This is too long, it misses INC A
        ldy     #0
        lda     (saddr),y
        clc
        adc     #1
        sta     (saddr),y
        bcc     :+              ; Longer, but much faster
        iny
        lda     (saddr),y
        adc     #0
        sta     (saddr),y
:
.else
        stx     loadH+2
        stx     loadL+2
        tax
loadL:  inc     $FF00, x
        bne     :+
loadH:  inc     $FF01, x
:
.endif
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "INC"
        deftoken "INCVAR"

; vi:syntax=asm_ca65

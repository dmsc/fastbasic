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


; Get's variable address
; ----------------------

        .export get_op_var

        ; From interpreter.asm
        .importzp       next_instruction, cptr, sptr
        .import         pushAX
        ; From allloc.asm
        .importzp       var_buf

        .segment        "RUNTIME"

.proc   EXE_VAR_ADDR  ; AX = address of variable
        jsr     get_op_var
        jmp     next_instruction
.endproc

.proc   EXE_VAR_ADDR_PUSH ; (SP) = address of variable
        jsr     get_op_var
        ldy     sptr
        jsr     pushAX
        jmp     next_instruction
.endproc

        ; Reads variable number from opcode stream, returns
        ; variable address in AX
        ;   var_address = var_num * 2 + var_buf
.proc   get_op_var
        ldy     #0
        lda     (cptr), y
        inc     cptr
        bne     :+
        inc     cptr+1
:       ldx     var_buf+1
        asl
        bcc     :+
        inx
        clc
:
        adc     var_buf
        bcc     :+
        inx
:
        rts
.endproc

        .include "../deftok.inc"
        deftoken "VAR_ADDR"
        deftoken "VAR_ADDR_PUSH"

; vi:syntax=asm_ca65

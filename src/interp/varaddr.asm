;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2019 Daniel Serpell
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

        .export         get_op_var
        .importzp       cptr, var_page

        .include "toks.inc"

.proc   EXE_VAR_ADDR  ; AX = address of variable
        get_var
        sub_exit
.endproc

        ; Reads variable number from opcode stream, returns
        ; variable address in AX
        ;   var_address = var_num * 2 + var_page * 256
.proc   get_op_var
        ldy     #0
        lda     (cptr), y
        inc     cptr
        bne     :+
        inc     cptr+1
:       ldx     var_page
        asl
        bcc     :+
        inx
:
        rts
.endproc

        deftoken "VAR_ADDR"

; vi:syntax=asm_ca65

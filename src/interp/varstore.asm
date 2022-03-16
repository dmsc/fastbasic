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


; Store value into variable
; -------------------------

        .import         get_op_var, alloc_array
        .importzp       next_instruction, tmp2, move_dest

        .segment        "RUNTIME"

.proc   EXE_VAR_STORE_0
        lda     #0
        tax
        beq     EXE_VAR_STORE
.endproc

.proc   EXE_DIM         ; AX = array size, variable in opcode
        jsr     alloc_array
        lda     move_dest
        ldx     move_dest+1
.endproc        ;  Fall through

.proc   EXE_VAR_STORE  ; DPOKE (VAR), AX
        pha
        stx     tmp2+1
        jsr     get_op_var
.ifdef NO_SMCODE
        sta     tmp2
        lda     tmp2+1
        stx     tmp2+1
        ldy     #1
        sta     (tmp2),y
        dey
        pla
        sta     (tmp2),y        ; 14 bytes, 29 cycles
.else
        stx     save_l+2
        stx     save_h+2
        tax
        pla
save_h: sta     $FF00, x
        lda     tmp2+1          ; Restore X
save_l: sta     $FF01, x        ; 16 bytes, 27 cycles
.endif
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "DIM"
        deftoken "VAR_STORE"
        deftoken "VAR_STORE_0"

; vi:syntax=asm_ca65

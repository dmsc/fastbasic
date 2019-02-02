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


; Writes a 16-bit value to an address
; -----------------------------------

        ; From interpreter.asm
        .import         stack_l, stack_h
        .importzp       next_ins_incsp, sptr
        ; From runtime.asm
        .importzp       tmp1, tmp2

        .segment        "RUNTIME"

        ; FOR_START: Stores starting value to FOR variable and
        ;            keeps the address in the stack.
.proc   EXE_FOR_START
        ; In stack we have:
        ;       AX   = start value
        ;       (SP) = var_address
        dec     sptr  ; Keeps address into stack!
.endproc        ; Fall through

.proc   EXE_DPOKE  ; DPOKE (SP++), AX
        stx     tmp2            ; Save X
        ldx     stack_h, y
.if 0
        stx     tmp1+1
        ldx     stack_l, y
        stx     tmp1
        ldy     #0
        sta     (tmp1), y
        iny
        lda     tmp2            ; Restore X
        sta     (tmp1), y
.else
        ; Self-modifying code, 4 cycles faster and 1 byte larger than the above
        stx     save_l+2
        stx     save_h+2
        ldx     stack_l, y
save_h: sta     $FF00, x
        lda     tmp2            ; Restore X
save_l: sta     $FF01, x
.endif
        jmp     next_ins_incsp
.endproc

        .include "../deftok.inc"
        deftoken "DPOKE"
        deftoken "FOR_START"

; vi:syntax=asm_ca65

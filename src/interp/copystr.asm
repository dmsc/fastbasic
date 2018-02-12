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


; String copy (assign)
; --------------------

        .export EXE_COPY_STR

        ; From allloc.asm
        .importzp       array_ptr
        .import         alloc_array

        ; From runtime.asm
        .importzp       tmp1, tmp2

        ; From interpreter.asm
        .import         pop_stack_2, stack_l, stack_h

        .segment        "RUNTIME"

; Copy one string to another, allocating the destination if necessary
.proc   EXE_COPY_STR    ; AX: source string   (SP): destination *variable* address
        ; Store source
        pha
        txa
        pha
        ; Get destination pointer - allocate if 0
        lda     stack_l, y
        sta     tmp1
        lda     stack_h, y
        sta     tmp1+1
        ldy     #0
        lda     (tmp1), y
        sta     tmp2
        iny
        lda     (tmp1), y
        sta     tmp2+1
        bne     ok
        ; Copy current memory pointer to the variable
        lda     array_ptr+1
        sta     (tmp1), y
        sta     tmp2+1
        dey
        lda     array_ptr
        sta     (tmp1), y
        sta     tmp2
        ; Allocate 256 bytes
        lda     #0
        ldx     #1
        jsr     alloc_array
ok:
        ; Get source pointer and check if it is allocated
        pla
        sta     tmp1+1
        pla
        sta     tmp1
        ldy     #0
        ora     tmp1+1
        beq     nul
        ; Copy len
        lda     (tmp1), y
nul:    sta     (tmp2), y
        tay
        beq     xit
        ; Copy data
cloop:  lda     (tmp1), y
        sta     (tmp2), y
        dey
        bne     cloop
xit:    jmp     pop_stack_2
.endproc

; vi:syntax=asm_ca65

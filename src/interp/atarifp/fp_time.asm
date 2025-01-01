;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2025 Daniel Serpell
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


; Floating Point TIME function
; ----------------------------

        .import         push_fr0
        .importzp       next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_FP_TIME
        jsr     push_fr0
        ; Get jiffies
retry:  lda     RTCLOK+2
        ldy     RTCLOK+1
        ldx     RTCLOK
        cmp     RTCLOK+2
        bne     retry
        pha
        ; Convert high two bytes to float
        stx     FR0+1
        sty     FR0
        jsr     IFP
        ; Multiply the result by 256
        ldx     #<fp_256
        ldy     #>fp_256
        jsr     FLD1R
        jsr     FMUL
        jsr     FMOVE
        ; Convert low byte to float
        pla
        sta     FR0
        lda     #0
        sta     FR0+1
        jsr     IFP
        ; Add
        jsr     FADD
        jmp     next_instruction
.endproc

fp_256: ; 256 in floating point
        .byte $41,$02,$56,$00,$00,$00

        .include "deftok.inc"
        deftoken "FP_TIME"

; vi:syntax=asm_ca65

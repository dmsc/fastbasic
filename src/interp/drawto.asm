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


; DRAWTO and FILLTO
; -----------------

        .import CIOV_POP

        ; From runtime.asm
        .importzp       COLOR

        ; From interpreter.asm
        .import         pushAX
        .importzp       sptr

        .include "atari.inc"

        .segment        "RUNTIME"

EXE_FILLTO:
        ldy     #FILLIN
        .byte   $2C   ; Skip 2 bytes over next "LDY"
.proc   EXE_DRAWTO
        ldy     #DRAWLN
        sty     ICCOM+$60
        ldy     sptr
        jsr     pushAX
        lda     COLOR
        sta     ATACHR
        ldx     #$60    ; IOCB #6
        lda     #$0C
        sta     ICAX1, x
        lda     #$00
        sta     ICAX2, x
        jmp     CIOV_POP
.endproc

        .include "../deftok.inc"
        deftoken "DRAWTO"
        deftoken "FILLTO"

; vi:syntax=asm_ca65

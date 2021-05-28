;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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


; Multiplies by 6 - used to access floating-point arrays
; ------------------------------------------------------

        .importzp       next_instruction, tmp1

        .segment        "RUNTIME"

.proc   EXE_MUL6 ; AX = AX * 6 (UNSIGNED)

.if 0
        stx tmp1+1      ; 3     2
        asl             ; 2     1
        sta tmp1        ; 3     2
        rol tmp1+1      ; 5     2
        ldx tmp1+1      ; 3     2
        asl             ; 2     1
        rol tmp1+1      ; 5     2
        adc tmp1        ; 3     2
        tay             ; 2     1
        txa             ; 2     1
        adc tmp1+1      ; 3     2
        tax             ; 2     1
        tya             ; 2 =37 1 =20
        jmp     next_instruction
.endif

        sta tmp1        ; 3     2
        stx tmp1+1      ; 3     2
        asl             ; 2     1
        rol tmp1+1      ; 5     2
        adc tmp1        ; 3     2
        sta tmp1        ; 3     2
        txa             ; 2     1
        adc tmp1+1      ; 3     2
        asl tmp1        ; 5     2
        rol             ; 2     1
        tax             ; 2     1
        lda tmp1        ; 3 =36 2 =20
        jmp     next_instruction
.endproc

        .include "deftok.inc"
        deftoken "MUL6"

; vi:syntax=asm_ca65

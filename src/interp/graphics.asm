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


; Graphics command
; ----------------

        .export EXE_GRAPHICS

        .import CIOV_CMD_POP

        ; From runtime.asm
        .import         cio_close
        .importzp       tmp1

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_GRAPHICS  ; OPEN #6,12,0,
        sta     tmp1
        ldx     #$60
        jsr     cio_close
        lda     tmp1
        and     #$F0
        eor     #$1C    ; Get AUX1 from BASIC mode
        sta     ICAX1, x
        lda     tmp1    ; And AUX2
        sta     ICAX2, x
        lda     #<device_s
        sta     ICBAL, x
        lda     #>device_s
        sta     ICBAH, x
        lda     #OPEN
        jmp     CIOV_CMD_POP
device_s: .byte "S:", $9B
.endproc

; vi:syntax=asm_ca65

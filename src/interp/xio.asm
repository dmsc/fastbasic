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


; CIO operations
; --------------

        .export         CIOV_CMD_POP2, CIOV_CMD_AH
        .import         CIOV_CMD, stack_l, stack_h, get_str_eol
        .importzp       sptr

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_XIO
        jsr     get_str_eol
        ldy     sptr
        lda     stack_l+2, y
        asl
        asl
        asl
        asl
        tax
        lda     INBUFF
        sta     ICBAL, x
        lda     #0
        sta     ICBLH, x
        lda     #$FF
        sta     ICBLL, x
        lda     stack_l, y
        sta     ICAX1, x
        lda     stack_h, y
        sta     ICAX2, x
        lda     stack_l+1, y
        tay
        lda     INBUFF+1
        inc     sptr
.endproc        ; Fall through
        ; Calls CIO with given command, stores I/O error, and pops stack twice
CIOV_CMD_POP2:
        inc     sptr
        inc     sptr
CIOV_CMD_AH:
        sta     ICBAH, x
        tya
        jmp     CIOV_CMD

        .include "../deftok.inc"
        deftoken "XIO"

; vi:syntax=asm_ca65

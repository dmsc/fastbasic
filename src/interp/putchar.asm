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


; CIO put character
; -----------------

        .export putc, putc_direct, putspc

        ; From runtime.asm
        .importzp       IOCHN, tabpos, IOERROR

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   putc_direct
        tay
        lda     ICAX1,X
        sta     ICAX1Z
        lda     ICPTH, x
        pha
        lda     ICPTL, x
        pha
        tya
        rts
.endproc

putspc:
        lda     #$20
.proc   putc
        ldx     IOCHN
        sty     save_y+1
        jsr     putc_direct
        sty     IOERROR
save_y: ldy     #0
        dec     tabpos
        bpl     :+
        lda     #9
        sta     tabpos
:       rts
.endproc

; vi:syntax=asm_ca65

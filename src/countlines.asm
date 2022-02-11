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

; Support code for the Editor
; ---------------------------

        .export COUNT_LINES
        .importzp tmp1, tmp2


.proc   COUNT_LINES
sizeH   = tmp1
ptr     = tmp2
        pla
        sta     sizeH
        pla
        tax
        pla
        sta     ptr+1
        pla
        tay
        inx
        inc     sizeH

        lda     #0
        sta     ptr

loop:   lda     (ptr), y
        dex
        bne     :+
        dec     sizeH
        beq     end
:       iny
        bne     :+
        inc     ptr+1
:       cmp     #$9B
        bne     loop
end:    tya
        ldx     ptr+1
        rts
.endproc


; vi:syntax=asm_ca65

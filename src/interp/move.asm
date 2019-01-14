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


; MOVE: copy memory upwards
; -------------------------

        ; From interpreter.asm
        .import         stack_l, stack_h, next_ins_incsp_2

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_MOVE  ; move memory up
        pha
        lda     stack_l, y
        sta     dst+1
        lda     stack_h, y
        sta     dst+2
        lda     stack_l+1, y
        sta     src+1
        lda     stack_h+1, y
        sta     src+2
        pla

        ; copy first bytes by adjusting the pointer *down* just the correct
        ; amount: from  "(ptr-(256-len)) + (256-len)" to "(ptr+len-256) + 256"
        ;
        inx
        tay
        beq     cpage
        dey
        clc
        adc     src+1
        sta     src+1
        bcs     :+
        dec     src+2
:       tya
        sec
        adc     dst+1
        sta     dst+1
        bcs     :+
        dec     dst+2
:
        tya
        eor     #$ff
        tay
cloop:
src:    lda     $FF00,y
dst:    sta     $FF00,y
        iny
        bne     cloop
        ; From now-on we copy full pages!
        inc     src+2
        inc     dst+2
cpage:  dex
        bne     cloop

xit:    jmp     next_ins_incsp_2

.endproc

        .include "../deftok.inc"
        deftoken "MOVE"

; vi:syntax=asm_ca65

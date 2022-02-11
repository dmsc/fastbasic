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
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; MOVE: copy memory upwards
; -------------------------

        .import         stack_l, stack_h, next_ins_incsp_2
        .importzp       tmp3, saddr

.ifdef NO_SMCODE
src = tmp3
dst = saddr
.endif
        .segment        "RUNTIME"

.proc   EXE_MOVE  ; move memory up
        pha
        lda     stack_l, y
        sta     saddr
        lda     stack_h, y
        sta     dst+1
        lda     stack_l+1, y
        sta     tmp3
        lda     stack_h+1, y
        sta     src+1
        pla

        ; copy first bytes by adjusting the pointer *down* just the correct
        ; amount: from  "(ptr-(256-len)) + (256-len)" to "(ptr+len-256) + 256"
        ;
        inx
        tay
        clc
        adc     tmp3
        sta     src
        bcs     :+
        dec     src+1
:       tya
        clc
        adc     saddr
        sta     dst
        bcs     :+
        dec     dst+1
:
        tya
        beq     cpage
        eor     #$ff
        tay
        iny
cloop:
.ifdef NO_SMCODE
        ; 16/17 cycles / iteration
        lda     (src),y       ; 5/6
        sta     (dst),y       ; 6
.else
        ; 14/15 cycles / iteration, plus 10 cycles more at preparation
src = * + 1
        lda     $FF00,y         ; 5/4
dst = * + 1
        sta     $FF00,y         ; 5
.endif
        iny
        bne     cloop
cpage:
        ; From now-on we copy full pages!
        inc     src+1
        inc     dst+1
        dex
        bne     cloop

xit:    jmp     next_ins_incsp_2

.endproc

        .include "deftok.inc"
        deftoken "MOVE"

; vi:syntax=asm_ca65

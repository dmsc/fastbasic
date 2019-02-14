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


; -MOVE: copy memory downwards
; ----------------------------

        ; memory move
        .export         move_dwn

        ; From interpreter.asm
        .import         stack_l, stack_h, next_ins_incsp_2

        .include "atari.inc"

.ifdef NO_SMCODE
        .exportzp       move_dwn_src, move_dwn_dst
        .importzp       tmp3, tmp4, divmod_sign
move_dwn_src= tmp3
move_dwn_dst= tmp4
.else
        .export         move_dwn_src, move_dwn_dst
.endif

        .segment        "RUNTIME"

.proc   EXE_NMOVE  ; move memory down
        pha
        lda     stack_l, y
        sta     move_dwn_dst
        lda     stack_h, y
        sta     move_dwn_dst+1
        lda     stack_l+1, y
        sta     move_dwn_src
        lda     stack_h+1, y
        sta     move_dwn_src+1
        pla
        jsr     move_dwn
        jmp     next_ins_incsp_2
.endproc

        ; Note: this is used from alloc.asm, so can't be inlined above
.proc   move_dwn
        ; Here, we will copy (X-1) * 255 + Y bytes, up to src+Y / dst+Y
        ; X*255 - 255 + Y = A*256+B
        ; Calculate our new X/Y values

        clc
.ifdef NO_SMCODE
        sta     divmod_sign
        txa
        adc     divmod_sign
.else
        sta     len_l+1         ; Store len_l
        txa
len_l:  adc     #$FF
.endif
        tay
        bcc     :+
        inx
        iny
:
chk_len:
        ; Adds 255*X to SRC/DST
        txa
        clc
        eor     #$FF
        adc     move_dwn_src
        sta     move_dwn_src
        txa
        adc     #$FF
        clc
        adc     move_dwn_src+1
        sta     move_dwn_src+1

        txa
        clc
        eor     #$FF
        adc     move_dwn_dst
        sta     move_dwn_dst
        txa
        adc     #$FF
        clc
        adc     move_dwn_dst+1
        sta     move_dwn_dst+1

        inx

        ; Copy 255 bytes down - last byte can't be copied without two comparisons!
        tya
        beq     xit
ploop:
cloop:
.ifdef NO_SMCODE
        ; 17 cycles / iteration
        lda     (move_dwn_src),y
        sta     (move_dwn_dst),y
.else
        ; 15 cycles / iteration, plus 14 cycles more at preparation
src:    lda     $FF00,y
dst:    sta     $FF00,y
.endif
        dey
        bne     cloop

        ; We need to decrease the pointers by 255
next_page:
        inc     move_dwn_src
        beq     :+
        dec     move_dwn_src+1
:       inc     move_dwn_dst
        beq     :+
        dec     move_dwn_dst+1
:
        ; And copy 255 bytes more!
        dey
        dex
        bne     cloop

xit:    rts
.endproc

.ifndef NO_SMCODE
move_dwn_src     = move_dwn::src+1
move_dwn_dst     = move_dwn::dst+1
.endif


        .include "../deftok.inc"
        deftoken "NMOVE"

; vi:syntax=asm_ca65

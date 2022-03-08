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


; -MOVE: copy memory downwards
; ----------------------------

        .export         move_dwn
        .import         stack_l, stack_h, next_ins_incsp_2

        .exportzp       move_dwn_src, move_dwn_dst
        .importzp       tmp3, move_source, move_dest, move_ins, move_loop
move_dwn_src= move_source
move_dwn_dst= move_dest

        .segment        "RUNTIME"

.proc   EXE_NMOVE  ; move memory down
        pha
        lda     stack_l, y
        sta     move_dest
        lda     stack_h, y
        sta     move_dest+1
        lda     stack_l+1, y
        sta     move_source
        lda     stack_h+1, y
        sta     move_source+1
        pla
        jsr     move_dwn
        jmp     next_ins_incsp_2
.endproc

        ; Note: this is used from alloc.asm, so can't be inlined above
.proc   move_dwn

        ; On input:
        ;    Length:            AX
        ;    Source Pointer:    move_dwn_src
        ;    Destination Ptr:   move_dwn_dst
        ;
        ; Copy 255 bytes at a time, in total X * 255 + Y bytes, with
        ; 0 <= X < 255, 0 <= Y < 255; so we need:
        ;    X * 255 + Y  =  Length
        ;
        ; The values of X and Y can be calculated with:
        ;
        ;    X * 256 + Y = X * 255 + X + Y
        ;                = X * 255 + Y + X
        ;                = Length      + X
        ;                = Length      + X*255/256 + X/256 + Y/256 - Y/256
        ;                = Length      + X*255/256 + Y/256 + X/256 - Y/256
        ;                = Length      + Length/256        + (X-Y)/256
        ;
        ; As we have |X-Y| < 255, the last term is always 0, so we can use
        ; the expression: Length + Length/256 to calculate our X and Y:
        ;
        clc
        sta     tmp3
        txa
        adc     tmp3
        tay
        bcc     :+
        inx     ; On carry, we need to add 1 to X and Y (because we are
        iny     ; calculating modulo 255).
:
        ; Here, the only possibility of Y = 0 is that the Length is 0
        beq     xit

        ; Now we add "255*X - 1" to the source and destination pointers,
        ; to start the copy from the end of the block.
        ; This simplifies to adding:
        ;    256 * (X-1) + (255-X) = 255 * X - 1
        stx     tmp3
        dex

        clc
        lda     move_source
        sbc     tmp3
        sta     move_source
        txa
        adc     move_source+1
        sta     move_source+1

        clc
        lda     move_dest
        sbc     tmp3
        sta     move_dest
        txa
        adc     move_dest+1
        sta     move_dest+1

        lda     #$88    ; DEY
        sta     move_ins

        inx     ; Restore X
        inx     ; Add 1, now value is from 1 to 255

        ; Copy Y bytes down in the first iteration, 255 in the following
cloop:
        jsr     move_loop

        ; We need to decrease the pointers by 255
next_page:
        inc     move_source
        beq     :+
        dec     move_source+1
:       inc     move_dest
        beq     :+
        dec     move_dest+1
:
        ; And copy 255 bytes more!
        dey
        dex
        bne     cloop

xit:    rts
.endproc


        .include "deftok.inc"
        deftoken "NMOVE"

; vi:syntax=asm_ca65

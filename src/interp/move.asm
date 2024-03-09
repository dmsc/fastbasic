;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2024 Daniel Serpell
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

        .import         stack_l, stack_h, next_ins_incsp_2, move_get_ptr
        .importzp       move_source, move_dest, move_ins, move_loop

src = move_source
dst = move_dest
        .segment        "RUNTIME"

.proc   EXE_MOVE  ; move memory up
        jsr     move_get_ptr

        ; copy first bytes by adjusting the pointer *down* just the correct
        ; amount: from  "(ptr-(256-len)) + (256-len)" to "(ptr+len-256) + 256"
        ;
        inx
        tay
        clc
        adc     src
        sta     src
        bcs     :+
        dec     src+1
:       tya
        clc
        adc     dst
        sta     dst
        bcs     :+
        dec     dst+1
:

        lda     #$C8    ; INY
        sta     move_ins

        tya
        beq     cpage
        eor     #$ff
        tay
        iny

cloop:
        jsr     move_loop
cpage:
        ; From now-on we copy full pages!
        inc     src+1
        inc     dst+1
        dex
        bne     cloop

        ; Restore DEY in loop
        lda     #$88    ; DEY
        sta     move_ins

        jmp     next_ins_incsp_2

.endproc

        .include "deftok.inc"
        deftoken "MOVE"

; vi:syntax=asm_ca65

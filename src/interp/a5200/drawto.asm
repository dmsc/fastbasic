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


; Line drawing
; ------------

        .importzp       DINDEX, COLOR, IOERROR, COLCRS, ROWCRS, tmp4
        .importzp       SAVMSC, next_instruction, tmp1
        .import         gr_mask_p, gr_shift_x, gr_mask_s, EXE_PUT

        .zeropage
mask:   .res 1
color_s:.res 1


; TODO: implement line drawing for all graphic modes
        .segment        "RUNTIME"

.proc   EXE_PLOT        ; Plot a point into current position
        ; Compatibility: for text modes, this is the same as "PUT":
        bit     DINDEX
        bpl     do_plot
        lda     COLOR
        jmp     EXE_PUT
do_plot:
        jsr     get_addr
        lda     mask
        eor     #$FF
        and     (tmp4), y
        ora     color_s
        sta     (tmp4), y
        jmp     next_instruction
.endproc

.proc   EXE_DRAWTO      ; Draw line from last position to current
        jmp     next_instruction
.endproc


.proc   get_addr
        lda     ROWCRS

        ; Multiply A by 4, overflowing to X
        ldx     #0
        asl
        bcc     L1
        ldx     #2
L1:     asl
        bcc     L2
        inx
        clc

        ; Add to original, multiply by 5
L2:     adc     ROWCRS
        bcc     :+
        inx
:
        ; And shift 3 times, multiply by 40:
        stx     tmp4+1
        asl
        rol     tmp4+1
        asl
        rol     tmp4+1
        asl
        rol     tmp4+1

        ; Add to screen address
        adc     SAVMSC
        sta     tmp4
        lda     tmp4+1
        adc     SAVMSC+1
        sta     tmp4+1
        cmp     #$40    ; Compare with top of ram
        bcs     ret_error

        ; Get mask and shift amounts
        ldx     DINDEX
        lda     gr_mask_p, x
        sta     mask

        ldy     gr_shift_x, x

        ; First shift is 16 bits
        lda     COLCRS+1
        lsr
        lda     COLCRS
        sta     tmp1
        lda     #192
        ; Next shifts are 8 bits
shift:  ror     tmp1    ; Shift column position
        ror             ; Shift bit position
        dey
        bne     shift
        ; Here A = bit position * 32, shift 4 more times:
        rol
        rol
        rol
        rol
        and     #7
        eor     #7
        tax

        ; Generate bit pattern and mask
        lda     COLOR
        and     mask

        dex
        bmi     ok_mask
rol_mask:
        asl
        asl     mask
        dex
        bpl     rol_mask
ok_mask:
        sta     color_s

        ldy     tmp1
        rts
.endproc

        ; Return from calling code with error
ret_error:
        pla
        pla
        lda     #18
        sta     IOERROR
        jmp     next_instruction

        .include "deftok.inc"
        deftoken "DRAWTO"
        deftoken "PLOT"

; vi:syntax=asm_ca65

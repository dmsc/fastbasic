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
        .importzp       SAVMSC, next_instruction, tmp1, tmp2, tmp3
        .import         gr_mask_p, gr_shift_x, gr_mask_s, EXE_PUT

        .zeropage
mask:   .res 1
color_s:.res 1
colpos = tmp1

OLDROW: .res 1
OLDCOL: .res 2

comp:   .res 2
error:  .res 2

row_add:.res 1
col_add:.res 2

delta_x = tmp2
delta_y = tmp3
old_err = tmp1 + 1


; TODO: implement line drawing for all graphic modes
        .segment        "RUNTIME"

.proc   EXE_PLOT        ; Plot a point into current position
        ; Compatibility: for text modes, this is the same as "PUT":
        bit     DINDEX
        bpl     do_plot
        lda     COLOR
        jmp     EXE_PUT
do_plot:

        ldx     #2
cp_pos: lda     ROWCRS, x
        sta     OLDROW, x
        dex
        bpl     cp_pos

        jsr     get_addr
        lda     mask
        eor     #$FF
        and     (tmp4), y
        ora     color_s
        sta     (tmp4), y
        jmp     next_instruction
.endproc


.proc   EXE_DRAWTO      ; Draw line from last position to current

        ; Fast Bresenham line implementation, updating memory pointers

        ; Get DY - easy as it is only 8 bits
        ldy     #1

        lda     ROWCRS
        sec
        sbc     OLDROW
        bcs     dr_ypos

        ; Y direction negative
        eor     #$FF    ; This is cheaper than lda/sbc again
        adc     #$01

        ldy     #255
dr_ypos:
        sta     delta_y
        sty     row_add

        ; Get DX
        lda     #0
        sta     col_add+1
        ldx     #1

        lda     COLCRS
        sec
        sbc     OLDCOL
        tay
        lda     COLCRS+1
        sbc     OLDCOL+1
        bcs     dr_xpos

        ; X direction negative
        eor     #$FF
        pha
        tya
        eor     #$FF
        adc     #$01
        tay
        pla
        adc     #0

        dec     col_add+1
        ldx     #$FF

dr_xpos:
        sta     delta_x+1
        sty     delta_x
        stx     col_add

        ; Pseudo-code for this line-drawing algorithm:
        ;
        ; dx = ABS(x1-x0)
        ; dy = ABS(y1-y0)
        ; sx = SGN(x1-x0)
        ; sy = SGN(y1-y0)
        ;
        ; error = dx - (dy / 2)
        ; comp = (dx + dy) / 2
        ;
        ; DO
        ;     orig_error = error;
        ;     IF error < comp
        ;
        ;         IF y0 = y1
        ;             EXIT
        ;
        ;         error = error + dx
        ;         y0 = y0 + sy
        ;
        ;     If orig_error >= 0
        ;
        ;         IF x0 = x1
        ;             EXIT
        ;
        ;         error = error - dy
        ;         x0 = x0 + sx
        ;
        ;     PLOT x0, y0
        ; LOOP

        ; Get's comp
        lda     delta_x
        adc     delta_y
        sta     comp
        lda     delta_x+1
        adc     #0
        lsr
        sta     comp+1
        ror     comp

        ; Get's error
        lda     delta_y
        lsr
        eor     #$FF
        sec     ; Can be avoided - only ads slight round error
        adc     delta_x
        sta     error
        lda     delta_x+1
        adc     #$FF
        sta     error+1

        ; Now, begin loop:
        jmp     line_start

no_inc_x:
        ; Plots current pixel
        jsr     get_addr
        lda     mask
        eor     #$FF
        and     (tmp4), y
        ora     color_s
        sta     (tmp4), y

line_start:
        ; Compare with "comp"
        lda     error
        cmp     comp
        lda     error+1
        sta     old_err         ; Store old error
        sbc     comp+1
        bpl     no_inc_y

        clc
        lda     error
        adc     delta_x
        sta     error
        lda     error+1
        adc     delta_x+1
        sta     error+1

        lda     OLDROW
        cmp     ROWCRS
        beq     end_line

        clc
        adc     row_add
        sta     OLDROW

no_inc_y:
        ; Compare old error with 0
        bit     old_err
        bmi     no_inc_x

        sec
        lda     error
        sbc     delta_y
        sta     error
        lda     error+1
        adc     #$FF
        sta     error+1

        lda     OLDCOL
        ldx     OLDCOL+1
        cmp     COLCRS
        bne     no_eol
        cpx     COLCRS+1
        beq     end_line
no_eol:
        clc
        adc     col_add
        sta     OLDCOL
        txa
        adc     col_add+1
        sta     OLDCOL+1
        jmp     no_inc_x

end_line:
        jmp     next_instruction
.endproc


.proc   get_addr
        lda     OLDROW

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
L2:     adc     OLDROW
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
        lda     OLDCOL+1
        lsr
        lda     OLDCOL
        sta     colpos
        lda     #192
        ; Next shifts are 8 bits
shift:  ror     colpos  ; Shift column position
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

        ldy     colpos
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

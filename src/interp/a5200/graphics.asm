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


; Atari 5200 GRAPHICS statement
; -----------------------------

        .export         set_grmode, gr_mask_p, gr_shift_x
        .importzp       tmp1, move_dest, next_instruction
        .importzp       DINDEX, COLCRS, ROWCRS, SAVMSC, COLOR
        .import         mem_set_0, MEMTOP, GPRIOR

        .segment        "RUNTIME"
        .include        "atari5200.inc"


.proc   EXE_GRAPHICS
        jsr     set_grmode
        jmp     next_instruction
.endproc

        ; Modes supported:
        ;  #   size     type  bytes  RAM      DL      DINDEX
        ;                     /line           size
        ;  -----------------------------------------------
        ;  0 : 40x24    TEXT   40     1k       32      6 +      128
        ;  1 : 20x24    TEXT   20     0.5k     32      4 + 64 + 128
        ;  2 : 20x12    TEXT   20     0.25k    20      5 + 64 + 128
        ;  7 : 160x96   2bpp   40     4k      104      0
        ;  8 : 320x192  1bpp   40     8k      202      1
        ;  9 : 80x192   4bpp   40     8k      202      2
        ; 10 : 80x192   4bpp   40     8k      202      2
        ; 11 : 80x192   4bpp   40     8k      202      2
        ; 12 : 40x24    TEXT   40     1k       32      6       + 128
        ; 13 : 40x12    TEXT   40     0.5k     20      6       + 128
        ; 15 : 160x192  2bpp   40     8k      202      3
        ;
        ; DL Types specs:
        ;
        ;  0 : 20x24    TEXT   3E20
        ;  1 : 20x12    TEXT   3F10
        ;  2 : 40x24    TEXT   3C40
        ;  3 : 40x12    TEXT   3E20
        ;  4 : 40x96    2bpp   3100
        ;  5 : 40x192   1bpp   21F0
        ;  6 : 40x192   2bpp   21F0
        ;  7 : 40x192   4bpp   21F0
        ;
        ; All modes use a fixed memory layout, so the display list is always at
        ; the same location:
        ;
.proc   set_grmode
        and     #$0F

        ldy     #0
        sty     SDMCTL
        sty     DMACTL

        tay

        lda     dl_type, y
        sta     DINDEX
        and     #7
        tax

        lda     GPRIOR          ; Mask bits 6-7 of GPRIOR, and set from table
        eor     dl_mode, y
        and     #$C0
        eor     GPRIOR
        sta     GPRIOR

        lda     dl_mode, y
        and     #$0F
        pha

        lda     mem_adr_l, x
        sta     SAVMSC
        sta     move_dest
        lda     mem_adr_h, x
        sta     SAVMSC + 1
        sta     move_dest+1
        lda     dl_adr_l, x
        sta     SDLSTL
        sta     MEMTOP
        lda     dl_adr_h, x
        sta     SDLSTH
        sta     MEMTOP+1

        lda     rows, x
        sta     ROWCRS

        ; Clear memory
        lda     #$00
        sec
        sbc     move_dest
        sta     tmp1
        lda     #$40
        sbc     move_dest+1
        tax
        jsr     mem_set_0

        ; Make the display list
        lda     #112
        ldy     #0
lp1:    sta     (SDLSTL), y
        iny
        cpy     #3
        bne     lp1
        pla
        pha
        ora     #$40
        sta     (SDLSTL), y
        iny
        lda     SAVMSC
        sta     (SDLSTL), y
        iny
        lda     SAVMSC+1
        sta     (SDLSTL), y

        ; Now, the rest of the lines - up to number of rows
        pla
setr:
        iny
        cpy     #95
        bne     no_4k
        ; Patch crossing of 4K segment
        pha
        ora     #$40
        sta     (SDLSTL), y
        iny
        lda     #<$3000
        sta     (SDLSTL), y
        iny
        lda     #>$3000
        sta     (SDLSTL), y
        iny
        dec     ROWCRS
        pla

no_4k:
        sta     (SDLSTL), y
        dec     ROWCRS
        bne     setr

ok:     ; Last part, jump
        lda     #65
        sta     (SDLSTL), y
        iny
        lda     SDLSTL
        sta     (SDLSTL), y
        iny
        lda     SDLSTH
        sta     (SDLSTL), y

        ; Restores color palette
        ldy     #4
setp:
        lda     palette, y
        sta     COLOR0, y
        dey
        bpl     setp

        lda     #0
        sta     ROWCRS
        sta     COLCRS
        sta     COLCRS+1
        sta     COLOR

        ; Re-enable DMA
        ldy     #$22
        sty     SDMCTL

        rts
.endproc

palette:        .byte   $28,$CA,$94,$46,$00

;dl_type:        .byte   2, 0, 1, 2, 2, 2, 2, 4, 5, 6, 6, 6, 2, 3, 2, 7
        ; Byte copied to DINDEX
dl_type:        .byte   $86,$C4,$C5,$86,$86,$86,$86,$00,$01,$02,$02,$02,$86,$87,$86,$03
        ; Encode ANTIC mode and GPRIOR values
dl_mode:        .byte   $02,$06,$07,$02,$02,$02,$02,$0D,$0F,$4F,$8F,$CF,$04,$05,$02,$0E

mem_adr_l:      .lobytes $3100, $21F0, $21F0, $21F0, $3E20, $3F10, $3C40, $3E20
mem_adr_h:      .hibytes $3100, $21F0, $21F0, $21F0, $3E20, $3F10, $3C40, $3E20
dl_adr_l:       .lobytes $3098, $2126, $2126, $2126, $3E00, $3EF0, $3C20, $3E00
dl_adr_h:       .hibytes $3098, $2126, $2126, $2126, $3E00, $3EF0, $3C20, $3E00
rows:           .byte       96,   192,   192,   192,    24,    12,    24,    12

                ;       2bpp    1bpp    4bpp    2bpp
gr_mask_p:      .byte   3,      1,     15,      3
gr_shift_x:     .byte   2,      3,      1,      2

        .include "deftok.inc"
        deftoken "GRAPHICS"

; vi:syntax=asm_ca65

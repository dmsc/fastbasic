;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017 Daniel Serpell
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

; Common runtime between interpreter and parser
; ---------------------------------------------

        ; 16bit math
        .export         umul16, sdiv16, smod16, neg_AX
        ; simple I/O
        .export         getkey, getc, putc, print_hex_byte, print_hex_word, print_word
        .export         cio_close, close_all, sound_off
        .exportzp       IOCHN, COLOR, IOERROR, tabpos
        ; String functions
        .export         skipws, read_word
        ; memory move
        .export         move_up_src, move_up_dst, move_up
        .export         move_dwn_src, move_dwn_dst, move_dwn
        ; Graphics
        .export         graphics

        .importzp       tmp1, tmp2, tmp3, bptr, blen

        .include        "atari.inc"
        .zeropage
sign:   .res    1
IOCHN:  .res    1
IOERROR:.res    2
COLOR:  .res    1
tabpos: .res    1

        .code

; Negate AX value
.proc   neg_AX
        clc
        eor     #$FF
        adc     #1
        pha
        txa
        eor     #$FF
        adc     #0
        tax
        pla
        rts
.endproc

; Adjust sign for SIGNED div operations
; INPUT: OP1:    A / X
;        OP2: tmp1 / tmp1+1
;        P flag : from "X"
.proc   sign_adjust
        ldy     #0
        cpx     #0
        bpl     x_pos
        dey
        dey
        dey
        jsr     neg_AX
x_pos:  sta     tmp3
        stx     tmp3+1
        ldx     tmp1+1
        bpl     y_pos
        lda     tmp1
        iny
        jsr     neg_AX
        sta     tmp1
        stx     tmp1+1
y_pos:  sty     sign
        jsr     udiv16
        rts
.endproc

; Signed 16x16 division
.proc   sdiv16
        jsr     sign_adjust
        lsr     sign
        bcc     ret
        jmp     neg_AX
ret:    rts
.endproc

; Signed 16x16 modulus
.proc   smod16
        jsr     sign_adjust
        lda     tmp2
        ldx     tmp2+1
        asl     sign
        bcc     ret
        jmp     neg_AX
ret:    rts
.endproc

;
; 16x16 -> 16 multiplication
.proc umul16
        ; Mult
        sta     tmp3
        stx     tmp3+1

        lda     #0
        sta     tmp2+1
        ldy     #16             ; Number of bits

        lsr     tmp1+1
        ror     tmp1            ; Get first bit into carry
@L0:    bcc     @L1

        clc
        adc     tmp3
        pha
        lda     tmp3+1
        adc     tmp2+1
        sta     tmp2+1
        pla

@L1:    ror     tmp2+1
        ror
        ror     tmp1+1
        ror     tmp1
        dey
        bne     @L0

        sta     tmp2            ; Save byte 3
        lda     tmp1            ; Load the result
        ldx     tmp1+1
        rts                     ; Done
.endproc

; Divide TMP3 / TMP2, result in AX and remainder in TMP2
.proc   udiv16
        ldy     #16
        lda     #0
        sta     tmp2+1
        cpx     #0
        beq     udiv16x8

L0:     asl     tmp3
        rol     tmp3+1
        rol
        rol     tmp2+1

        pha
        cmp     tmp1
        lda     tmp2+1
        sbc     tmp1+1
        bcc     L1

        sta     tmp2+1
        pla
        sbc     tmp1
        pha
        inc     tmp3

L1:     pla
        dey
        bne     L0
        sta     tmp2
        lda     tmp3
        ldx     tmp3+1
        rts

udiv16x8:
L2:     asl     tmp3
        rol     tmp3+1
        rol
        bcs     L3

        cmp     tmp1
        bcc     L4
L3:     sbc     tmp1
        inc     tmp3

L4:     dey
        bne     L2
        sta     tmp2
        lda     tmp3
        ldx     tmp3+1
        rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; I/O routines
;
.proc   getkey
        lda     KEYBDV+5
        pha
        lda     KEYBDV+4
        pha
        lda     #12
        sta     ICAX1Z          ; fix problems with direct call to KEYBDV
lrts:   rts
.endproc

.proc   getc
        lda     #GETCHR
        sta     ICCOM, x
        lda     #0
        sta     ICBAH, x
        sta     ICBAL, x
        sta     ICBLL, x
        sta     ICBLH, x
        jsr     CIOV
        rts
.endproc

.proc   print_hex_byte

        .data
hex_table:
        .byte   "0123456789ABCDEF"
        .code

        pha
        lda     #'$'
        jsr     ::putc
only:   pla
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     print_hex
        pla
print_hex:
        and     #$0F
        tax
        lda     hex_table,x
        ; Fall through
.endproc

        ; Falls from print_byte!
.proc   putc_nosave
        tay
        lda     ICPTH, x
        pha
        lda     ICPTL, x
        pha
        tya
        rts
.endproc

.proc   putc
        pha
        stx     save_x+1
        sty     save_y+1
        ldx     IOCHN
        jsr     putc_nosave
save_x: ldx     #0
save_y: ldy     #0
        dec     tabpos
        bpl     :+
        lda     #9
        sta     tabpos
:       pla
        rts
.endproc

.proc   print_hex_word
        pha
        txa
        jsr     print_hex_byte
        jmp     print_hex_byte::only
.endproc

.proc   print_word
FR0     = $D4
IFP     = $D9AA
        stx     tmp1
        cpx     #$80
        bcc     positive
        clc
        eor     #$FF
        adc     #1
        tay
        txa
        eor     #$FF
        adc     #0
        tax
        tya

positive:
        sta     FR0
        stx     FR0+1
        jsr     IFP
        lda     tmp1
        and     #$80
        eor     FR0
        sta     FR0
        ; Fall through
.endproc
.proc   print_fp
FASC    = $D8E6
INBUFF  = $F3
        jsr     FASC
        ldy     #$FF
ploop:  iny
        lda     (INBUFF), y
        pha
        and     #$7F
        jsr     putc
        pla
        bpl     ploop
        rts
.endproc

.proc   cio_close
        lda     #CLOSE
        sta     ICCOM, x
        jmp     CIOV
.endproc

.proc   close_all
        lda     #$70
:       tax
        jsr     cio_close
        txa
        sec
        sbc     #$10
        bne     :-
        rts
.endproc

.proc   sound_off
        ldy     #7
        lda     #0
:       sta     AUDF1, y
        dey
        bpl     :-
        rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Convert string to integer (word)

; Multiply "tmp1" by 10 - uses A,X, keeps Y
.proc   mul10
        lda     tmp1
        ldx     tmp1+1

        asl
        rol     tmp1+1
        bcs     xit
        asl
        rol     tmp1+1
        bcs     xit

        adc     tmp1
        sta     tmp1
        txa
        adc     tmp1+1
        bcs     xit

        asl     tmp1
        rol     a

        sta     tmp1+1
xit:    rts
.endproc

.scope  skipws
skipws_loop:
        iny
::skipws:
        cpy     blen
        beq     xit
        lda     (bptr), y
        cmp     #' '
        beq     skipws_loop
        clc
xit:    rts
.endscope

.proc   read_word
        ; Skips white space at start
        jsr     skipws
        bcs     xit     ; End of string and no characters found

        ; Clears result
        ldx     #0
        stx     tmp1
        stx     tmp1+1

        ; Reads a '+' or '-'
        cmp     #'+'
        beq     skip
        cmp     #'-'
        bne     nosign
        dex
skip:   iny

nosign: stx     sign
        sty     tmp2+1  ; Store starting Y position - used to check if read any digits
loop:
        ; Check length
        cpy     blen
        beq     xit_n

        ; Reads one character
        lda     (bptr), y
        sec
        sbc     #'0'
        cmp     #10
        bcs     xit_n ; Not a number

        iny             ; Accept

        sta     tmp2    ; and save digit

        jsr     mul10
        bcs     ebig

        ; Add new digit
        lda     tmp2
        adc     tmp1
        sta     tmp1
        bcc     loop
        inc     tmp1+1
        bne     loop

ebig:
        sec
xit:    rts

xit_n:  cpy     tmp2+1
        beq     ebig    ; No digits read

        ; Restore sign - conditional!
        lda     tmp1
        ldx     tmp1+1
        lsr     sign
        bcc     :+
        jsr     neg_AX
        clc
:       rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory move routines
.proc   move_up
        ; copy first bytes by adjusting the pointer *down* just the correct
        ; amount: from  "(ptr-(256-len)) + (256-len)" to "(ptr+len-256) + 256"
        ;
        inx
        ldy     #0
        cmp     #0
        beq     cpage
        tay
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

xit:    rts
.endproc
move_up_src     = move_up::src+1
move_up_dst     = move_up::dst+1

.proc   move_dwn
        ; Store len_l
        sta     len_l+1

        ; Here, we will copy (X-1) * 255 + Y bytes, up to src+Y / dst+Y
        ; X*255 - 255 + Y = A*256+B
        ; Calculate our new X/Y values
        txa
        clc
len_l:  adc     #$FF
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
        adc     src+1
        sta     src+1
        txa
        adc     #$FF
        clc
        adc     src+2
        sta     src+2

        txa
        clc
        eor     #$FF
        adc     dst+1
        sta     dst+1
        txa
        adc     #$FF
        clc
        adc     dst+2
        sta     dst+2

        inx

        ; Copy 255 bytes down - last byte can't be copied without two comparisons!
        tya
        beq     xit
ploop:
cloop:
src:    lda     $FF00,y
dst:    sta     $FF00,y
        dey
        bne     cloop

        ; We need to decrease the pointers by 255
next_page:
        inc     src+1
        beq     :+
        dec     src+2
:       inc     dst+1
        beq     :+
        dec     dst+2
:
        ; And copy 255 bytes more!
        dey
        dex
        bne     cloop

xit:    rts
.endproc
move_dwn_src     = move_dwn::src+1
move_dwn_dst     = move_dwn::dst+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Graphics code
.proc   graphics
        sta     tmp1
        ldx     #$60
        jsr     cio_close
        lda     tmp1
        and     #$F0
        eor     #$1C    ; Get AUX1 from BASIC mode
        sta     ICAX1, x
        lda     tmp1    ; And AUX2
        sta     ICAX2, x
        lda     #OPEN
        sta     ICCOM, x
        lda     #<device_s
        sta     ICBAL, x
        lda     #>device_s
        sta     ICBAH, x
        jmp     CIOV
        .data
device_s: .byte "S:", $9B
        .code
.endproc

; vi:syntax=asm_ca65

;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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


; Print 16bit number
; ------------------

.ifdef FASTBASIC_FP
        .export         int_to_fp, fp_to_str
.endif
        .import         neg_AX
        .importzp       next_instruction


        .segment        "RUNTIME"

EXE_INT_STR:          ; AX = STRING( AX )

        ; In the integer version we simply fall-through
        ; from int_to_fp to fp_to_str, so we use 8 bytes less.
        ;
.ifdef FASTBASIC_FP
        jsr     int_to_fp
        jsr     fp_to_str
        jmp     next_instruction
.endif

int_to_fp:
FR0     = $D4
IFP     = $D9AA
        cpx     #$80
        php                     ; Store sign in C
        bcc     positive
        jsr     neg_AX
positive:
        sta     FR0
        stx     FR0+1
        jsr     IFP

        asl     FR0
        plp                     ; Get sign and store in FR0
        ror     FR0

.ifdef  FASTBASIC_FP
        rts
.endif
        ; Fall through
fp_to_str:
FASC    = $D8E6
INBUFF  = $F3
LBUF    = $580
        jsr     FASC
        ; Decrease INBUFF, adds one byte for the string length
        dec     INBUFF
        ldy     #$0
        ; Calculate length
ploop:  iny
        lda     (INBUFF), y
        bpl     ploop
        ; Ok, last character, set high bit to 0
        and     #$7F
        sta     (INBUFF), y
        ; And store length into string start
        tya
        ldy     #0
        sta     (INBUFF), y
        ; Returns buffer in AX
        lda     INBUFF
        ldx     INBUFF+1
.ifdef FASTBASIC_FP
        rts
.else
        jmp     next_instruction
.endif

        .include "../deftok.inc"
        deftoken "INT_STR"

; vi:syntax=asm_ca65

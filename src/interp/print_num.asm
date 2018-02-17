;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017,2018 Daniel Serpell
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
        .export print_fp, int_to_fp
.endif
        ; From interpreter.asm
        .import pop_stack
        .import putc, neg_AX
        .importzp tmp1


        .segment        "RUNTIME"

EXE_PRINT_NUM:          ; PRINT (SP+)

        ; In the integer version we simply fall-through
        ; from int_to_fp to print_fp and pop_stack, so we
        ; use 8 bytes less.
        ;
.ifdef FASTBASIC_FP
        jsr     int_to_fp
        jsr     print_fp
        jmp     pop_stack
.endif

int_to_fp:
FR0     = $D4
IFP     = $D9AA
        stx     tmp1
        cpx     #$80
        bcc     positive
        jsr     neg_AX
positive:
        sta     FR0
        stx     FR0+1
        jsr     IFP
        lda     tmp1
        and     #$80
        eor     FR0
        sta     FR0

.ifdef FASTBASIC_FP
        rts
.endif
        ; Fall through
print_fp:
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
.ifdef FASTBASIC_FP
        rts
.else
        jmp     pop_stack
.endif

        .include "../deftok.inc"
        deftoken "PRINT_NUM"

; vi:syntax=asm_ca65

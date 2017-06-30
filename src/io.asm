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

; Common I/O functions used by parser and menu
; --------------------------------------------


        .export print, getline, getline_file, line_buf
        ; From runtime.asm
        .import putc

        .include "atari.inc"
;
line_buf        = LBUFF

.proc   getline
        ldx     #0
file:   lda     #>line_buf
        sta     ICBAH, x
.assert (>line_buf) = GETREC, error, "invalid optimization"
        ;lda     #GETREC
        sta     ICCOM, x
        lda     #<line_buf
        sta     ICBAL, x
.assert (<line_buf) = $80, error, "invalid optimization"
        ;lda     #$80
        sta     ICBLL, x
        lda     #0
        sta     ICBLH, x
        jsr     CIOV
        lda     ICBLL, x
xit:    rts
.endproc
getline_file    = getline::file

.proc   print
        jsr     get_ml_byte
        beq     getline::xit
        jsr     putc
        jmp     print
.endproc


.proc   get_ml_byte
        stx     read_x+1        ; 4
        tsx                     ; 2
        inc     $103,x          ; 7
        lda     $103,x          ; 4
        sta     read_a+1        ; 4
        bne     :+              ; 2 3
        inc     $104,x          ; 7 0
:       lda     $104,x          ; 4
        sta     read_a+2        ; 4
read_x: ldx     #0              ; 2
read_a: lda     $FF00           ; 4  = 44 (38)
        rts
.endproc

; vi:syntax=asm_ca65

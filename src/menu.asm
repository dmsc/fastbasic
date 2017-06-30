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

; Main menu system
; ----------------

        .export start

        ; From io.asm
        .import print, getline, line_buf
        ; From runtime.asm
        .import putc, getkey, print_word, graphics
        .importzp IOCHN, tabpos
        ; From parser.asm
        .import parser_start, input_file
        ; From intrepreter.asm
        .import interpreter_run
        ; From errors.asm
        .import print_error

        .include "atari.inc"

        .data
parsed_ok:      .res 1

        .code

start:
        lda     #0
        sta     IOCHN
        sta     tabpos
        sta     parsed_ok
        sta     input_file
        jsr     graphics
        jsr     print
        .byte   "FastBasic - (c) 2017 dmsc", $9b, 0

main_menu:
        jsr     print
        .byte   $9b, "menu: ", 'F'+$80, "ILE  ", 'P'+$80, "ARSE  ", 0
        lda     parsed_ok
        beq     :+
        jsr     print
        .byte   'R'+$80, "UN  ", 0
:       jsr     print
        .byte   'D'+$80, "OS", $9b, 0

        jsr     getkey

        ; Parse program
        cmp     #'P'
        bne     :+
        lda     #0
        sta     parsed_ok
        jsr     parser_start
        bcs     main_menu
        inc     parsed_ok
        bne     main_menu

        ; Run program
:       cmp     #'R'
        bne     :+
        lda     parsed_ok
        beq     main_menu
        jsr     interpreter_run
        lda     #0
        sta     IOCHN
        jmp     main_menu

        ; Go to DOS
:       cmp     #'D'
        bne     :+
        jmp     (DOSVEC)

        ; Open input file
:       cmp     #'F'
        bne     main_menu
        jsr     print
        .byte   "Filename?", 0
        jsr     getline

        ldx     #$70
        stx     input_file
        lda     #CLOSE
        sta     ICCOM, x
        jsr     CIOV
        lda     #4
        sta     ICAX1, x
        lda     #0
        sta     ICAX2, x
        lda     #OPEN
        sta     ICCOM, x
        lda     #<line_buf
        sta     ICBAL, x
        lda     #>line_buf
        sta     ICBAH, x
        jsr     CIOV
        tya
        bpl     menu_2
        jsr     print_error
        ldx     #0
        stx     input_file
menu_2: jmp     main_menu

; vi:syntax=asm_ca65

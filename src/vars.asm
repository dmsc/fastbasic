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

; Handles a list of names (variables or labels)
; --------------------------------------------

        .export         var_search, label_search, name_new
        .exportzp       var_namelen, label_count

        ; From interpreter.asm
        .importzp       var_count
        ; From alloc.asm
        .importzp       var_buf, label_buf, prog_ptr
        .import         alloc_area_8
        ; From parser.asm
        .import         parser_skipws


; Each variable is stored in the list as:
;   N bytes:  variable name, last char +$80
;   1 byte:   variable type
; To find a variable, we simply walk the list skipping the types.


; Parsing pointers:
CIX     = $F2
INBUFF  = $F3

; Our internal pointers:
        .zeropage
name:   .res 2
var:    .res 2
len:    .res 1
label_count:    .res 1

; Use a longer name for external references
var_namelen=    len

;----------------------------------------------------------
        .code

        ; Checks if a character is valid for a variable name
.proc   check_char
        cmp     #'0'
        bcc     bad_char
        cmp     #'9'+1
        bcc     exit
first:
        cmp     #'_'
        beq     char_ok
        cmp     #'A'
        bcc     bad_char
        cmp     #'Z'+1
exit:
        rts
bad_char:
        sec
        rts
char_ok:
        clc
        rts
.endproc

        ; Search the list of labels by name,
        ; Inputs:
        ;  (INBUFF + CIX) : Variable name, from parsing code, terminated in any invalid char
.proc   label_search
        ldx     #label_buf - prog_ptr
        ldy     label_count
        bne     list_search
.endproc

        ; Search the list of variables by name,
        ; Inputs:
        ;  (INBUFF + CIX) : Variable name, from parsing code, terminated in any invalid char
.proc   var_search
        ; Pointer to var list to "var"
        ldx     #var_buf - prog_ptr
        ldy     var_count
.endproc        ; Fall through

        ; Search a list of names - used for variables or labels
.proc   list_search
        sty     search_count

        ; Pointer to start of var/label list to "var"
        lda     prog_ptr, x
        sta     var
        lda     prog_ptr+1, x
        sta     var+1

        ; Get's the name length, used when creating new variables
        jsr     var_getlen

        ; Variable number
        ldx     #$ff
        bne     search_start

search_loop:

        ; Compare data
        ldy     #0
cmp_loop:
        lda     (var), y
        eor     (name), y
        asl
        bne     skip_var
        iny
        bcc     cmp_loop
        cpy     len
        bne     next_var

found:
        lda     (var), y
        clc
        rts

skip_var:
        lda     (var), y
        asl
        iny
        bcc     skip_var
next_var:
        tya
        sec
        adc     var
        sta     var
        bcc     :+
        inc     var+1
:
search_start:
        inx
::search_count=   * + 1
        cpx     #0
        bne     search_loop

not_found:
        sec
        rts
.endproc

        ; Find the length of the valid variable name string
        ; If no character is valid, pops the stack and returns with carry set.
        ; Also, init the "name" pointer with the current position
.proc   var_getlen
        ; Skips spaces
        jsr     parser_skipws
        ; Pointer with var name to "name"
        lda     INBUFF
        clc
        adc     CIX
        sta     name
        lda     INBUFF+1
        adc     #0
        sta     name+1

        ; Start checking
        ldy     #0
        ; Read the first character
        lda     (name),y
        jsr     check_char::first
        bcs     exit_2
next:
        iny
        lda     (name),y
        jsr     check_char
        bcc     next

        .byte   $2C     ; Skips two PLA
exit_2:
        pla
        pla
        sty     len
        sec
        rts
.endproc

        ; Common proc to add a new label or variable
        ; X = ZP address of label/var table pointer
.proc   name_new
        ; Pointer to end of var/label list to "var"
        lda     prog_ptr, x
        sta     var
        lda     prog_ptr+1, x
        sta     var+1
        ; Allocate memory for name
        lda     len
        beq     var_getlen::exit_2
        clc
        adc     #1
        jsr     alloc_area_8
        bcs     var_getlen::exit_2


        ; Set type to 0 initially
        ldy     len
        lda     #0
        sta     (var), y

        ; Copy name of var/label
        dey
        lda     (name),y
        eor     #$80
loop:
        sta     (var),y
        dey
        bmi     end
        lda     (name),y
        bpl     loop

end:    rts
.endproc

; vi:syntax=asm_ca65

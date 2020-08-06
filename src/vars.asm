;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2019 Daniel Serpell
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

        .export         var_search, list_search, name_new
        .exportzp       var_namelen, label_count, var_count

        ; From alloc.asm
        .importzp       var_buf, prog_ptr
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
var_count:      .res    1

; Use a longer name for external references
var_namelen=    len

;----------------------------------------------------------
        .code

        ; Checks if a character is valid for a variable name
.proc   check_char
        cmp     #'0'
        bcc     ret_sec
        cmp     #'9'+1
        bcc     exit
first:
        cmp     #'_'
        beq     ret_clc
        sbc     #'A'-1
        cmp     #26
exit:
        rts
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
::ret_clc:
        clc
        rts

skip_var:
        lda     (var), y
        asl
        iny
        bcc     skip_var

next_var:

.ifdef FASTBASIC_FP
        .importzp       VT_FLOAT
        ; Check if variable is FP and add two to the number, this allocates
        ; 6 bytes to the variable at runtime.
        lda     (var), y        ; Get type
        .assert VT_FLOAT & 128 , error, "VT_FLOAT must be > 127"
        bpl     no_float        ; float is > 127
        inx
        inx
no_float:
.endif

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

        ; Variable name not found, exit with C=1
::ret_sec:
        sec
        rts
.endproc

        ; Find the length of the valid variable name string
        ; If no character is valid, pops the stack and returns with carry set.
        ; Also, init the "name" pointer with the current position
.proc   var_getlen
        ; Skips spaces
        jsr     parser_skipws
        ; Checks first character - most times we don't need to search anything else
        lda     (INBUFF), y
        jsr     check_char::first

        tya
        ldy     #0
        bcs     exit_2

        ; Ok, we have at least one character

        ; Pointer with var name to "name"
        adc     INBUFF
        sta     name
        lda     INBUFF+1
        adc     #0
        sta     name+1

        ; Check rest of characters
next:
        iny
        lda     (name),y
        jsr     check_char
        bcc     next

        ; Check if there is a dot after the name, and reject
        cmp     #'.'
        beq     exit_2

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

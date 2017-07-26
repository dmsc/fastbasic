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

; Handles a list of names (variables or labels)
; --------------------------------------------

        .export         var_getlen, var_search, var_new, var_set_type
        .export         label_search, label_new
        .exportzp       var_namelen, var_count, label_count

        ; From parser.asm
        .importzp       bptr, bpos
        ; From alloc.asm
        .importzp       var_buf, var_ptr, label_buf, label_ptr, prog_ptr
        .import         alloc_area_8


; Each variable is stored in the list as:
;   1 byte:   length of name in bytes
;   N bytes:  variable name
;   1 byte:   variable type
; To find a variable, we simply walk the list by adding the length
; to each name.

; Our internal pointers:
        .zeropage
name:   .res 2
var:    .res 2
len:    .res 1
var_count:      .res 1
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
        ;  (bptr + bpos) : Variable name, from parsing code, terminated in any invalid char
.proc   label_search
        ldx     #label_buf - prog_ptr
        ldy     #label_count
        sty     search_count
        bne     list_search
.endproc

        ; Search the list of variables by name,
        ; Inputs:
        ;  (bptr + bpos) : Variable name, from parsing code, terminated in any invalid char
.proc   var_search
        ; Pointer to var list to "var"
        ldx     #var_buf - prog_ptr
        ldy     #var_count
        sty     search_count
.endproc        ; Fall through

        ; Search a list of names - used for variables or labels
.proc   list_search
        ; Pointer to start of var/label list to "var"
        lda     prog_ptr, x
        sta     var
        lda     prog_ptr+1, x
        sta     var+1

        ; Variable number
        ldx     #$ff
        bne     search_start

search_loop:

        ; Compare lengths
        ldy     #0
        lda     (var),y
        cmp     len
        bne     next_var

        ; Compare data
        tay
cmp_loop:
        lda     (var), y
        dey
        bmi     var_found
        cmp     (name), y
        beq     cmp_loop
next_var:
        ; Advance pointer to next var
        ldy     #0
        lda     (var),y
        clc
        adc     #2      ; No carry, as len is max 128
        adc     var
        sta     var
        bcc     :+
        inc     var+1
:
search_start:
        inx
::search_count=   * + 1
        cpx     $12
        bne     search_loop

not_found:
        sec
        rts

var_found:      ; Returns variable type in A
        ldy     len
        iny
        lda     (var), y
        clc
        rts
.endproc

        ; Find the length of the valid variable name string
        ; If no character is valid, pops the stack and returns with carry set.
        ; Also, init the "name" pointer with the current position
.proc   var_getlen
        ; Pointer with var name to "name"
        lda     bptr
        clc
        adc     bpos
        sta     name
        lda     bptr+1
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
end:
        sty     len
        rts
exit_2:
        pla
        pla
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
        clc
        adc     #2
        jsr     alloc_area_8
        bcs     exit
        ; Copy length and name of var/label
        ldy     #0
        lda     len
        sta     (var),y
loop:
        lda     (name),y
        iny
        sta     (var),y
        cpy     len
        bne     loop

        ; Set type to 0 initially
        lda     #0
        iny
        sta     (var), y
exit:   rts
.endproc

        ; Adds a new variable to the variable table, returns the var index
.proc   var_new
        ldx     #var_ptr - prog_ptr
        jsr     name_new
        ldx     var_count
        inc     var_count
        clc
        rts
.endproc

        ; Adds a new label
.proc   label_new
        ldx     #label_ptr - prog_ptr
        jsr     name_new
        ldx     label_count
        inc     label_count
        clc
        rts
.endproc

        ; Sets the type of the lase defined variable
        ; A = type
.proc   var_set_type
        ; Pointer to var list to "var"
        ldx     var_ptr
        stx     var
        ldx     var_ptr+1
        dex
        stx     var+1

        ldy     #$FF
        sta     (var), y

        clc
        rts
.endproc

; vi:syntax=asm_ca65

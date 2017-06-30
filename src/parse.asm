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

; Parser state machine interpreter
; --------------------------------

        .export         parser_start, parser_error, input_file, parser_skipws
        .import         __PINIT_RUN__
        ; Common vars
        .exportzp       tmp1, tmp2, tmp3, COLOR
        ; Parser state
        .exportzp       bptr, bpos, blen, bmax
        ; Output state
        .exportzp       opos
        ; From actions.asm
        .importzp       VT_WORD, VT_ARRAY_WORD, VT_ARRAY_BYTE, VT_STRING
        .importzp       loop_sp
        .import         check_labels
        ; From alloc.asm
        .import         alloc_prog
        .importzp       prog_ptr
        ; From runtime.asm
        .import         print_word, putc, skipws
        .importzp       IOCHN, IOERROR
        ; From io.asm
        .import         print, getline_file, line_buf
        ; From errors.asm
        .import         print_error
        .importzp       ERR_PARSE, ERR_BRK, ERR_IO, ERR_NO_ELOOP, ERR_LABEL
        ; Export used tokens values to the interpreter
        .exportzp       TOK_CSTRING

TOK_END = 0

        .zeropage
bptr:   .res 2
bpos:   .res 1
bmax:   .res 1
blen:   .res 1
opos:   .res 1
pptr:   .res 2
tmp1:   .res 2
tmp2:   .res 2
tmp3:   .res 2
linenum:.res 2
COLOR:  .res 1

        .code
        .include "atari.inc"

;; Parser SM commands:
SM_EXIT =       0
SM_RET  =       1
SM_ERET =       2
SM_EMIT_1=      3
SM_EMIT_2=      4
SM_EMIT_3=      5
SM_EMIT_4=      6
SM_EMIT_5=      7
SM_EMIT_6=      8
SM_EMIT_7=      9
SM_EMIT_8=      10
SM_EMIT_9=      11
SM_EMIT_10=     12
SM_EMIT_11=     13
SM_EMIT_12=     14
SM_EMIT_13=     15
SM_EMIT_14=     16
SM_EMIT_15=     17
SM_EMIT_16=     18
SM_EMIT_N=      SM_EMIT_16 + 1
SM_EMIT=        SM_EMIT_1

        .include "basic.asm"

; NOTE: the parser initialization is done using a *magic* segment "PINIT" with
;       all the routines joined together, and terminated with the code in the
;       segment "PINIT_RTS", that simply jumps to the start of parsing.
;
;       This makes the code simpler, but we can't control the order of
;       initialization.
;
        .segment "PINIT_RTS"
        lda     #0
        sta     linenum
        sta     linenum+1
        tsx
        stx     saved_stack
        lda     #<line_buf
        sta     bptr
        lda     #>line_buf
        sta     bptr+1
        jmp     parse_line

parser_start    = __PINIT_RUN__

; Now, the rest of the code
        .code

.proc parser_error
        ; Restore stack
ldstk:  ldx     #$ff
        txs
        ; Get error message
        pha
        ; Check if error == parse error
        cmp     #ERR_PARSE+1
        bcs     no_show_line

        ; Show input line
        ldy     #0
perror:
        lda     (bptr),y
        cpy     bmax
        bne     :+
        eor     #$80
:       jsr     putc
        iny
        cpy     blen
        bne     perror

        cpy     bmax
        bne     :+
        lda     #' '+$80
        jsr     putc
:       lda     #$9b
        jsr     putc

no_show_line:
        ; And shows line number
        jsr     print
        .byte   "At line ",0
        lda     linenum
        ldx     linenum+1
        jsr     print_word
        jsr     print
        .byte   ": ", 0

        pla
        jmp     print_error
.endproc
saved_stack = parser_error::ldstk + 1

.proc   input_error
        lda     #ERR_BRK
        cpy     #$80    ; BREAK
        beq     parser_error
        tya
        bne     parser_error
.endproc

.proc parse_eof
        ; Check if parser stack is empty
        lda     loop_sp
        beq     ok_loop
        lda     #ERR_NO_ELOOP
        bne     parser_error
ok_loop:
        ; Check for missing labels
        jsr     check_labels
        bcc     ok
        lda     #ERR_LABEL
        bne     parser_error
ok:     lda     #TOK_END
        jsr     emit_const
        lda     opos
        jsr     alloc_prog
        ldx     saved_stack
        txs
        clc
        rts
.endproc
E_END_PARSE=    parse_eof

.proc parser_fetch
        inc     pptr
        bne     :+
        inc     pptr+1
:       ldy     #0
        lda     (pptr),y
        rts
.endproc


line_ok:
        ; Increases output buffer
        lda     opos
        jsr     alloc_prog

.proc parse_line
        lda     #0
        sta     blen
        sta     bpos
        sta     bmax
        sta     opos

        ; Reads a line
        inc     linenum
        bne     :+
        inc     linenum+1
:
        lda     #'>'
        jsr     putc
        ldx     #0
::input_file = *-1
        jsr     getline_file
        sta     blen
        beq     parse_eof
        cpy     #$88
        beq     no_eol
        tya
        bmi     input_error
        dec     blen
no_eol:
        ; Convert to uppercase
        jsr     ucase_buffer

        ldx     #<(PARSE_START-1)
        ldy     #>(PARSE_START-1)
        lda     #0
        pha
        pha
        beq     parser_sub
.endproc

        ; Matched a dot (abbreviated statement), skips over all remaining chars
matched_dot:
        iny
        cpy     bmax
        bcc     :+
        sty     bmax
:       sty     bpos
skip_chars:
        jsr     parser_fetch
        bmi     ploop_nofetch
        cmp     #SM_EMIT_N
        bcs     skip_chars
        tax
        bcc     ploop_nofetch

        ; Parser sub
parser_sub:
        stx     pptr
        sty     pptr+1
        ; Always skip WS at start of new token
        jsr     parser_skipws

        ; Store input and output position
        lda     bpos
        pha
        lda     opos
        pha

        ; Parser loop
ploop:
        ; Read next parser instruction
        jsr     parser_fetch
ploop_nofetch:
        bmi     pcall
        cmp     #SM_EMIT_N
        bcs     match_char
        tax
        .assert SM_EXIT = 0, error, "SM_EXIT must be 0"
        beq     pexit_err
        dex
        .assert SM_RET  = 1, error, "SM_RET must be 1"
        beq     pexit_ok
        dex
        .assert SM_ERET = 2, error, "SM_ERET must be 1"
        beq     pemit_ret

pemit_n:
        clc
        adc     #($100 - SM_EMIT_1)
        tax
:       jsr     emit_sub
        dex
        bpl     :-
        bmi     ploop

        ; Character match
match_char:
        ldy     bpos
        cmp     #'a'
        bcc     match
        cmp     #'z'+1
        bcs     match
        tax
        lda     #'.'
        cmp     (bptr),y
        beq     matched_dot
        txa
        eor     #32 ; To uppercase
match:
        cmp     (bptr),y
        bne     ploop_nextline
        iny
        cpy     bmax
        bcc     :+
        sty     bmax
:       sty     bpos
go_ploop:
        jmp     ploop

pcall:
        asl
        tay
        lda     SM_TABLE_ADDR+1,y
        ldx     SM_TABLE_ADDR,y
        cpy     #(2*(SMB_STATE_START-128))
        bcc     pcall_ml

        tay
        lda     pptr+1
        pha
        lda     pptr
        pha
        jmp     parser_sub

call_ax1:
        pha
        txa
        pha
        rts

pcall_ml:
        jsr     call_ax1
        bcc     ploop
        bcs     ploop_nextline

pemit_ret:
        jsr     emit_sub

pexit_ok:
        pla
        pla
        pla
        sta     pptr
        pla
        sta     pptr+1
        bne     ploop
        jmp     line_ok


pexit_err:
        pla
        sta     opos
        pla
        sta     bpos
        pla
        sta     pptr
        pla
        beq     set_parse_error
        sta     pptr+1
        ; fall through

        ; Match failed, unroll go to next line or exit
ploop_nextline:
        pla
        sta     opos
        pla
        sta     bpos
        pha
        lda     opos
        pha

skip_nextline:
        jsr     parser_fetch
        cmp     #SM_EMIT_N      ; Note: comparisons sorted for faster skip
        bcs     skip_nextline
        tax
        .assert SM_EXIT = 0, error, "SM_EXIT must be 0"
        beq     pexit_err
        dex
        .assert SM_RET  = 1, error, "SM_RET must be 1"
        beq     go_ploop
        dex
        .assert SM_ERET = 2, error, "SM_ERET must be 1"
        beq     skip_ret
        clc
        adc     #($100 - SM_EMIT_1)
        tax
:       jsr     parser_fetch    ; Skip token
        dex
        bpl     :-
        jmp     skip_nextline
skip_ret:
        jsr     parser_fetch    ; Skip token and RET
        jmp     ploop

set_parse_error:
        lda     #ERR_PARSE
        jmp     parser_error

.proc   parser_skipws
        ldy     bpos
        jsr     skipws
        cpy     bmax
        bcc     :+
        sty     bmax
:       sty     bpos
        rts
.endproc

emit_sub:
        jsr     parser_fetch
emit_const:
        ldy     opos
        sta     (prog_ptr),y
        inc     opos
xit:    rts

        ; Transforms the line to uppercase
.proc   ucase_buffer
        ldy     blen
loop:
        dey
        bmi     xit
        lda     (bptr), y
        cmp     #'"'
        beq     skip_str        ; Skip string constants
        sbc     #'a'
        cmp     #'z'-'a'+1
        bcs     loop
        adc     #'A'
        sta     (bptr), y
        bcc     loop

skip_str:
        dey
        bmi     xit
        lda     (bptr), y
        cmp     #'"'
        bne     skip_str
        beq     loop
.endproc

; vi:syntax=asm_ca65

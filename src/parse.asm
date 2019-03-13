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

; Parser state machine interpreter
; --------------------------------

        .export         parser_start, parser_error, parser_skipws, parser_emit_byte, parser_inc_opos
        ; Parser state
        .exportzp       bptr, bpos, bmax, linenum, buf_ptr, end_ptr
        .exportzp       loop_sp
        ; Output state
        .exportzp       opos
        ; From actions.asm
        .importzp       VT_WORD, VT_ARRAY_WORD, VT_ARRAY_BYTE, VT_STRING, VT_FLOAT, VT_ARRAY_STRING
        .importzp       LT_PROC_1, LT_PROC_2, LT_DATA, LT_DO_LOOP, LT_REPEAT, LT_WHILE_1
        .importzp       LT_WHILE_2, LT_FOR_1,LT_FOR_2, LT_EXIT, LT_IF, LT_ELSE, LT_ELIF
        .import         check_labels
        ; From alloc.asm
        .import         alloc_prog
        .importzp       prog_ptr
        ; From vars.asm
        .importzp       var_count, label_count
        ; From runtime.asm
        .importzp       IOCHN, COLOR, IOERROR
        .import         putc
        ; From interpreter.asm
        .importzp       DEGFLAG, DEGFLAG_DEG, DEGFLAG_RAD
        .import         EXE_END, saved_cpu_stack, PMGMODE, PMGBASE
        ; From errors.asm
        .import         error_msg_list
        .importzp       ERR_PARSE, ERR_NO_ELOOP, ERR_LABEL, ERR_TOO_LONG

        .zeropage
buf_ptr:.res 2
end_ptr:.res 2
bmax:   .res 1
opos:   .res 1
pptr:   .res 2
linenum:.res 2
loop_sp:.res 1

        .code
        .include "atari.inc"

; Use LBUFF as line buffer
; line_buf        = LBUFF

; Use (INBUFF)+CIX as our parser pointer
bptr    = INBUFF
bpos    = CIX
; And some math-pack routines not exported
INTLBUF = $DA51
SKBLANK = $DBA1
parser_skipws   = SKBLANK

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

        .include "basic.inc"
        .include "basic.asm"

; Now, the rest of the code
        .code

emit_sub:
        jsr     parser_fetch
emit_const:
parser_emit_byte:
        ldy     opos
        sta     (prog_ptr),y
parser_inc_opos:
        inc     opos
        bne     rts1
too_long:
        ldx     #ERR_TOO_LONG
        ; Fall through

.proc parser_error
        ; Prints error message in X
        ldy     #$FF
ploop:  iny
        cpx     #1      ; C=1 if X != 0
        lda     error_msg_list, y
        bcs     skip    ; Skip if X != 0
        php
        and     #$7F
        jsr     putc
        plp
skip:   bpl     ploop
        dex
        bpl     ploop
        sec
::parse_end:
        jmp     EXE_END
.endproc

.proc parse_eof
        ; Check if parser stack is empty
        lda     loop_sp
        beq     ok_loop
        ldx     #ERR_NO_ELOOP
        bne     parser_error
ok_loop:
        ; Check for missing labels
        jsr     check_labels
        bcs     ok
        ldx     #ERR_LABEL
        bne     parser_error
ok:     lda     #TOK_END
        jsr     emit_const
        jsr     alloc_prog
        clc
        bcc     parse_end       ; exit
.endproc

.proc parser_fetch
        inc     pptr
        bne     :+
        inc     pptr+1
:       ldy     #0
        lda     (pptr),y
::rts1: rts
.endproc


;       Parser start and initialization
parser_start:
        tsx
        stx     saved_cpu_stack
        lda     #0
        sta     linenum
        sta     linenum+1
        sta     loop_sp
        sta     var_count
        sta     label_count
parse_line:
        lda     #0
        sta     bpos
        sta     bmax

        lda     buf_ptr
        cmp     end_ptr
        lda     buf_ptr+1
        sbc     end_ptr+1
        bcs     parse_eof

        ; Reads a line
        inc     linenum
        bne     :+
        inc     linenum+1
:

.proc   ucase_line
        ; Point parsing buffer pointer to line buffer
        jsr     INTLBUF

        ; Convert to uppercase and copy to line buffer
        ldy     #$FF
loop:
        iny
        lda     (buf_ptr), y
loop_redo:
        sta     (bptr), y
        cmp     #$9B
        beq     ucase_end

        cmp     #'"'
        beq     skip_str        ; Skip string constants
        sbc     #'a'
        cmp     #'z'-'a'+1
        bcs     loop
        adc     #'A'
        bcc     loop_redo

skip_str:
        iny
        lda     (buf_ptr), y
        sta     (bptr), y
        cmp     #'"'
        beq     loop
        cmp     #$9b
        bne     skip_str
ucase_end:
.endproc

        ; Point buf_ptr to next line
        tya
        sec
        adc     buf_ptr
        sta     buf_ptr
        bcc     :+
        inc     buf_ptr+1
:

parse_start:
        ; Parse statement
        ldx     #<(PARSE_START-1)
        ldy     #>(PARSE_START-1)
        lda     #0
        sta     opos
        pha
        pha

        ; Parser sub
parser_sub:
        stx     pptr
        sty     pptr+1
        tsx
        cpx     #16
        bcc     err_too_long
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
ploop_tax:
        tax
        .assert SM_EXIT = 0, error, "SM_EXIT must be 0"
        beq     pexit_err
        dex
        .assert SM_RET  = 1, error, "SM_RET must be 1"
        beq     pexit_ok
        dex
        .assert SM_ERET = 2, error, "SM_ERET must be 2"
        beq     pemit_ret

        .assert SM_EMIT_1 = 3, error, "SM_EMIT_1 must be 3"
:       jsr     emit_sub
        dex
        bne     :-
        beq     ploop

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
        inc     bpos
        bne     ploop

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
        bcs     parser_sub

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

        ; Parser returned, alloc program space
        jsr     alloc_prog

        ; Check if we are at end of line
        ldy     bpos
        lda     (bptr), y
        cmp     #':'            ; Colon: continue parsing line
        beq     parse_start
        cmp     #$9B
        bne     set_parse_error

        ; End parsing of current line
        jmp     parse_line

err_too_long:
        jmp     too_long

        ; Calls a machine-language subroutine
pcall_ml:
        jsr     call_ax1
        bcc     ploop
        bcs     ploop_nextline

        ; Matched a dot (abbreviated statement), skips over all remaining chars
matched_dot:
        iny
        sty     bpos
skip_chars:
        jsr     parser_fetch
        bmi     ploop_nofetch
        cmp     #SM_EMIT_N
        bcs     skip_chars
        bcc     ploop_tax

call_ax1:
        pha
        txa
        pha
        rts

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

        ; Match failed, save position, unroll and go to next line or exit
ploop_nextline:
        ldy     bpos
        cpy     bmax
        bcc     :+
        sty     bmax
:
        pla
        sta     opos
        pla
        sta     bpos
        pha
        lda     opos
        pha

        ldy     #0

skip_nextline:
        iny
        lda     (pptr),y
        cmp     #SM_EMIT_N      ; Note: comparisons sorted for faster skip
        bcs     skip_nextline
        tax
        .assert SM_EXIT = 0, error, "SM_EXIT must be 0"
        beq     pexit_err
        dex
        .assert SM_RET  = 1, error, "SM_RET must be 1"
        beq     go_ploop
        dex
        .assert SM_ERET = 2, error, "SM_ERET must be 2"
        beq     skip_ret
        .assert SM_EMIT_1 = 3, error, "SM_EMIT_1 must be 3"
:       iny                     ; Skip token
        dex
        bne     :-
        beq     skip_nextline
skip_ret:
        iny                     ; Skip token and RET
go_ploop:
        tya
        clc
        adc     pptr
        sta     pptr
        bcc     :+
        inc     pptr+1
:       jmp     ploop

set_parse_error:
        ldx     #ERR_PARSE
        jmp     parser_error

; vi:syntax=asm_ca65

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

; Parser state machine interpreter
; --------------------------------

        .export         parser_start, parser_error, parser_skipws, parser_emit_byte, parser_inc_opos
        ; Parser state
        .exportzp       bptr, bpos, bmax, linenum, buf_ptr, end_ptr
        .exportzp       loop_sp, var_sp
        ; Output state
        .exportzp       opos
        ; From actions.asm
        .importzp       VT_WORD, VT_STRING, VT_FLOAT, VT_UNDEF
        .importzp       VT_ARRAY_WORD, VT_ARRAY_BYTE, VT_ARRAY_STRING, VT_ARRAY_FLOAT
        .importzp       LT_PROC_DATA, LT_PROC_2, LT_DO_LOOP, LT_REPEAT, LT_WHILE_1
        .importzp       LT_WHILE_2, LT_FOR_1,LT_FOR_2, LT_EXIT, LT_IF, LT_ELSE, LT_ELIF
        ; From alloc.asm
        .import         alloc_prog
        .importzp       prog_ptr, BASIC_TOP
        ; From vars.asm
        .exportzp       var_count, label_count
        ; From runtime.asm
        .importzp       IOCHN, COLOR, IOERROR
        .import         putc
        ; From interpreter.asm
        .importzp       DEGFLAG, DEGFLAG_DEG, DEGFLAG_RAD, saved_cpu_stack
        .import         EXE_END, PMGMODE, PMGBASE
        ; Interpreted commands
        .import         CLEAR_DATA, SOUND_OFF
        ; From errors.asm
        .import         error_msg_list
        .importzp       ERR_PARSE, ERR_NO_ELOOP, ERR_LABEL, ERR_TOO_LONG

        .zeropage
buf_ptr:.res 2
end_ptr:.res 2
bmax:   .res 1
opos:   .res 1
pptr:   .res 2

; This variables are cleared in one loop:
zp_clear_start:
linenum:        .res 2
loop_sp:        .res 1
var_sp:         .res 1
label_count:    .res 1
var_count:      .res 1
zp_clear_end:

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

.proc parse_eof
        ; Check if parser stack is empty
        ldy     #ERR_NO_ELOOP
        lda     loop_sp
        bne     parser_error

        .importzp       laddr_ptr, laddr_buf
; Check if all labels are defined
        ldy     #1
        .assert ERR_LABEL = 1, error, "Parser depends on ERR_LABEL = 1"
        lda     laddr_buf
lbl_chk_start:
        cmp     laddr_ptr
        lda     laddr_buf+1
        sbc     laddr_ptr+1
        beq     ok

        lda     (laddr_buf), y
        beq     parser_error    ; unresolved label, return with Y=1 : ERR_LABEL

        ; Note: C = 0 from above!
        lda     laddr_buf
        adc     #4
        sta     laddr_buf
        bcc     lbl_chk_start
        inc     laddr_buf+1
        bcs     lbl_chk_start

ok:     ;lda     #TOK_END       ; Already A=0 from above
        .assert TOK_END = 0, error, "Parser depends on TOK_END = 0"
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
        ldy     #ERR_TOO_LONG
        ; Fall through

.proc parser_error
        ; Prints error message in Y
ploop:  lda     error_msg_list, y
        php
        iny
        and     #$7F
        jsr     putc
        plp
        bpl     ploop
        sec
::parse_end:
        jmp     EXE_END
.endproc


;       Parser start and initialization
parser_start:
        tsx
        stx     saved_cpu_stack
        lda     #0
        ldx     #zp_clear_end - zp_clear_start
zp_clear:
        sta     zp_clear_start, x
        dex
        bpl     zp_clear

parse_line:
        ldx     #0
        stx     bpos
        stx     bmax

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
        ;ldx     #0   ; X is 0 from above, assume INTLBUF does not overwrite X.
        ldy     #$FF
loop:
        iny
        lda     (buf_ptr), y
loop_redo:
        sta     (bptr), y
        cmp     #$9B
        beq     ucase_end       ; End upper-casing, C=1

        cmp     #'"'
        bne     skip_str        ; Skip string constants
        txa
        eor     #1
        tax
skip_str:
        cpx     #1
        beq     loop
        sbc     #'a'-1
        cmp     #'z'-'a'+1
        bcs     loop
        adc     #'A'
        bcc     loop_redo

ucase_end:
.endproc

        ; C=1 always from above
        ; Point buf_ptr to next line
        tya
        adc     buf_ptr
        sta     buf_ptr
        bcc     :+
        inc     buf_ptr+1
:

        lda     #0
parse_start:
        ; Parse statement, A=0 on input
        ldx     #<(PARSE_START-1)
        ldy     #>(PARSE_START-1)
        sta     opos
        pha

        ; Parser sub
parser_sub:
        pha
        stx     pptr
        sty     pptr+1
        tsx
        cpx     #16
        bcc     too_long
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
ploop_tax:
        tax
        bcs     match_char
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
        bcs     parser_sub      ; Jump always

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
        inc     bpos
        lda     (bptr), y
        eor     #':'            ; Colon: continue parsing line
        beq     parse_start     ; jump with A=0

        ; Current syntax file always checks for EOL at the end of parsing,
        ; no need to check here
;        eor     #$9B^':'
;        bne     set_parse_error

        ; End parsing of current line, jump with A=0
        jmp     parse_line

        ; Calls a machine-language subroutine
        ; NOTE: we always call ML subs with carry clear (C=0)
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
        ; sta     opos  ; // Ignored
        pla
        ; sta     bpos  ; // Ignored
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
; When skipping, we can't find an SM_EXIT before a RET:
;        .assert SM_EXIT = 0, error, "SM_EXIT must be 0"
;        beq     pexit_err
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
        ; clc                   ; C is 0 from above
        adc     pptr
        sta     pptr
        bcc     :+
        inc     pptr+1
:       jmp     ploop

set_parse_error:
        ldy     #ERR_PARSE
        jmp     parser_error

; vi:syntax=asm_ca65

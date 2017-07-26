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

; State machine actions (external subs)
; -------------------------------------

        .export         E_REM, E_EOL, E_NUMBER_WORD, E_NUMBER_BYTE
        .export         E_PUSH_LT, E_POP_LOOP, E_POP_REPEAT
        .export         E_POP_IF, E_ELSE, E_ELIF, E_EXIT_LOOP
        .export         E_POP_WHILE, E_POP_FOR, E_POP_PROC_1, E_POP_PROC_2, E_POP_DATA
        .export         E_CONST_STRING
        .export         E_VAR_CREATE, E_VAR_WORD, E_VAR_ARRAY_BYTE, E_VAR_ARRAY_WORD
        .export         E_VAR_SET_TYPE, E_VAR_STRING
        .export         E_LABEL, E_LABEL_DEF
        .export         check_labels
        .exportzp       VT_WORD, VT_ARRAY_WORD, VT_ARRAY_BYTE, VT_STRING
        .exportzp       LT_PROC_1, LT_PROC_2, LT_DATA, LT_DO_LOOP, LT_REPEAT, LT_WHILE_1, LT_WHILE_2, LT_FOR_1, LT_FOR_2, LT_EXIT, LT_IF, LT_ELSE, LT_ELIF
        .importzp       loop_sp, bpos, bptr, tmp1, tmp2, tmp3, opos
        ; From runtime.asm
        .import         umul16, sdiv16, read_word
        ; From vars.asm
        .import         var_search, var_new, var_getlen, var_set_type
        .import         label_search, label_new
        .importzp       var_namelen
        ; From alloc.asm
        .import         alloc_laddr
        .importzp       prog_ptr, laddr_ptr, laddr_buf
        ; From parser.asm
        .import         parser_error, parser_skipws
        .importzp       TOK_CSTRING
        ; From error.asm
        .importzp       ERR_LOOP, ERR_VAR
        ; From menu.asm
        .importzp       reloc_addr

;----------------------------------------------------------
        ; Types of variables
        .enum
                VT_UNDEF
                VT_WORD
                VT_ARRAY_WORD
                VT_ARRAY_BYTE
                VT_STRING
        .endenum
        ; Types of labels
        .enum
                LBL_UNDEF       = 0
                LBL_PROC
        .endenum
        ; Types of loops
        .enum
                ; First entries can't use "EXIT"
                LT_PROC_1
                LT_DATA
                LT_EXIT
                ; From here, loops don't push jump destinations
                LT_LAST_JUMP = 32
                LT_PROC_2
                LT_DO_LOOP
                LT_REPEAT
                LT_WHILE_1
                LT_FOR_1
                ; And from here, loops push destinations and are ignored by EXIT
                LT_WHILE_2= 128 ; Pushes
                LT_FOR_2        ; Pushes
                LT_IF           ; Pushes
                LT_ELSE         ; Pushes
                LT_ELIF         ; Pushes
        .endenum

;----------------------------------------------------------
        ; TODO: this space should be reclaimed by the interpreter!
        .bss
loop_stk:       .res    128

;----------------------------------------------------------
        .code

; Returns the current code pointer in AX
.proc   get_codep
        lda     prog_ptr
        ldx     prog_ptr+1
        clc
        adc     opos
        bcc     ok
        inx
        clc
ok:     rts
.endproc

; Emits address into codep, relocating if necessary.
.proc   emit_addr
        clc
        adc     reloc_addr
        pha
        txa
        adc     reloc_addr+1
        tax
        pla
.endproc        ; Fall through
;
; Emits 16bit AX into codep
.proc   emit_AX
        ldy     opos
new_y:  sta     (prog_ptr),y
        txa
        iny
        sta     (prog_ptr),y
        iny
        sty     opos
        clc
        rts
.endproc

; Parser external subs
.proc   E_REM
        ; Accept all the line
        ldy     bpos
loop:   iny
        lda     (bptr), y
        cmp     #$9b
        bne     loop
        sty     bpos
ok:     clc
        rts
.endproc

.proc   E_EOL
        ldy     bpos
        lda     (bptr),y
        cmp     #$9b ; Atari EOL
        beq     E_REM::ok
        cmp     #$0A ; ASCII EOL
        beq     E_REM::ok
xit:    sec
        rts
.endproc

.proc   E_NUMBER_WORD
        jsr     parser_skipws

        ldx     #0
        stx     tmp1+1

        lda     (bptr), y
        cmp     #'$'
        beq     read_hex

        jsr     read_word
        bcs     E_EOL::xit
        sty     bpos
        jmp     emit_AX

read_hex:
        iny

nloop:
        ; Read a number
        lda     (bptr),y
        sec
        sbc     #'0'
        cmp     #10
        bcc     digit
        cmp     #'A'-'0'
        bcc     xit
        sbc     #'A'-'0'-10
        cmp     #16
        bcs     xit ; Not an hex number

digit:
        iny             ; Accept
        sta     tmp1    ; and save digit

        ; Multiply tmp by 16
        txa
        asl
        rol     tmp1+1
        bcs     ebig
        asl
        rol     tmp1+1
        bcs     ebig
        asl
        rol     tmp1+1
        bcs     ebig
        asl
        rol     tmp1+1
        bcs     ebig

        ; Add new digit
        ora     tmp1
        tax
        bcc     nloop

ebig:
        sec
        rts

xit:
        cpy     bpos
        beq     ebig

        sty     bpos

        txa
        ldx     tmp1+1
        jmp     emit_AX
.endproc

.proc   E_NUMBER_BYTE
        jsr     E_NUMBER_WORD
        bcs     xit
        dec     opos
        cpx     #1
xit:    rts
.endproc

.proc   E_CONST_STRING
        ; Get characters until a '"' - emit all characters read!
        ldx     #0
        ; Store original output position
        lda     opos
        sta     tmp1
        ; Increase by two (token and length)
        inc     opos
        inc     opos
nloop:
        ; Check length
        ldy     bpos
        inc     bpos
        lda     (bptr), y
        cmp     #'"'
        beq     eos
        cmp     #$9b
        beq     err
        ; Store
store:  inx
        ldy     opos
        sta     (prog_ptr),y
        inc     opos
        bne     nloop
err:    ; Restore opos and exit
        lda     tmp1
        sta     opos
        sec
        rts
eos:    iny
        lda     (bptr), y
        inc     bpos
        cmp     #'"'    ; Check for "" to encode one ".
        beq     store
        dec     bpos
        ; Store token and length
eos_ok: ldy     tmp1
        lda     #TOK_CSTRING
        sta     (prog_ptr), y
        iny
        txa
        sta     (prog_ptr), y
        ; And adds an extra character to properly terminate string on IO operations
        ldy     opos
        sta     (prog_ptr),y
        inc     opos
        clc
        rts
.endproc


; Variable marching.
; The parser calls the routine to check if there is a variable
; with the correct type
.proc   E_VAR_STRING
        lda     #VT_STRING
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_VAR_ARRAY_BYTE
        lda     #VT_ARRAY_BYTE
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_VAR_ARRAY_WORD
        lda     #VT_ARRAY_WORD
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_VAR_WORD
        lda     #VT_WORD
        sta     tmp3    ; Store variable type
        jsr     parser_skipws
        ; Check if we have a valid name - this exits on error!
        jsr     var_getlen
        ; Search existing var
        jsr     var_search
        bcs     exit
        cmp     tmp3
        bne     not_found
        jmp     emit_varn
not_found:
        sec
exit:
        rts
.endproc

; Creates a new variable, with no type (the type will be set by parser next)
.proc   E_VAR_CREATE
        jsr     parser_skipws
        ; Check if we have a valid name - this exits on error!
        jsr     var_getlen
        ; Search existing var
        jsr     var_search
        bcc     E_VAR_WORD::not_found ; Exit with error if already exists
        ; Create new variable - exits on error
        jsr     var_new
        ; Fall through
.endproc
        ; Emits the variable, advancing pointers.
.proc   emit_varn
        ; Store VARN
        txa
        ldy     opos
        sta     (prog_ptr),y
        inc     opos
        ; Fall through
.endproc
        ; Advances variable name in source pointer
.proc   advance_varn
        lda     bpos
        clc
        adc     var_namelen
        sta     bpos
        jsr     parser_skipws
        clc
        rts
.endproc

; Sets the type of a variable - variable number and new type must be in the stack:
.proc   E_VAR_SET_TYPE
        dec     opos            ; Remove variable TYPE from stack
        ldy     opos
        lda     (prog_ptr),y    ; The variable TYPE
        jmp     var_set_type
.endproc

                ; Loop iteration for label-address,
        ; increment pointer, compares with end
        ; and reads values
.proc   next_laddr
loop:
        lda     tmp1
        clc
        adc     #4
        sta     tmp1
        bcc     comp
        inc     tmp1+1
comp:
        lda     tmp1
        cmp     laddr_ptr
        lda     tmp1+1
        sbc     laddr_ptr+1
        bcs     xit
        ldy     #0
        lda     (tmp1), y       ; Read variable type
        sta     tmp2
        iny
        lda     (tmp1), y       ; Read variable number and compare
cpnum:  eor     #$00
        bne     loop            ; Not our variable, retry
        iny
        lda     (tmp1), y       ; Yes, read hi address in X
        tax
        iny
        lda     (tmp1), y       ; lo address in A
        ldy     tmp2            ; And type in Y
xit:    rts
.endproc

; Adds a label address pointer to the list
.proc   add_laddr_list
        pha

        lda     laddr_ptr
        sta     tmp2
        lda     laddr_ptr+1
        sta     tmp2+1

        lda     #4
        jsr     alloc_laddr

        pla
        bcs     xit

        ldy     #0
        sta     (tmp2), y
        iny
        lda     next_laddr::cpnum+1
        sta     (tmp2), y
        jsr     get_codep
        ldy     #3
        sta     (tmp2), y
        dey
        txa
        sta     (tmp2), y
        clc
xit:    rts
.endproc

.proc   label_create
        jsr     parser_skipws
        ; Check if we have a valid name - this exits on error!
        jsr     var_getlen
        jsr     label_search
        bcc     xit
        ; Create a new label
        jsr     label_new
xit:
        lda     laddr_buf
        ldy     laddr_buf+1
        sta     tmp1
        sty     tmp1+1
        stx     next_laddr::cpnum+1
        jmp     next_laddr::comp
.endproc

; Label search / create (on use)
.proc   E_LABEL
        jsr     label_create
        ; Emits a label, searching the label address in the label list
        bcs     nfound

        ; Check label number
cloop:  bpl     next    ; 0 == label not defined, 1 == label defined, 128 == label address
        ; Found, get address from label and emit
emit_end:
        jsr     emit_addr
        jmp     advance_varn
next:
        jsr     next_laddr
        bcc     cloop
        ; Not found, add to the label address list
nfound: lda     #0
        jsr     add_laddr_list
        bcc     emit_end
ret:    rts
.endproc

; Label definition search/create
.proc   E_LABEL_DEF
        jsr     label_create

        ; Fills all undefined labels with current position - saved for the label
        bcs     nfound

        ; Check label number
cloop:  bmi     error   ; label already defined

        ; Write current codep to AX
        jsr     patch_codep
        ldy     #0
        lda     #1
        sta     (tmp1), y

        ; Continue
next:   jsr     next_laddr
        bcc     cloop
nfound:
        lda     #128
        jsr     add_laddr_list
        bcs     error
        jmp     advance_varn
error:  sec
xit:    rts
.endproc

; Check if all labels are defined
; Returns C=1 if ok.
.proc   check_labels
        ldy     #0
        sty     tmp1
        ldy     laddr_buf
        lda     laddr_buf+1
        sta     tmp1+1
start:
        cpy     laddr_ptr
        lda     tmp1+1
        sbc     laddr_ptr+1
        bcs     E_LABEL_DEF::xit

        lda     (tmp1), y
        beq     E_LABEL_DEF::xit

        ; Note: C = 0 from above!
        tya
        adc     #4
        tay
        bcc     start
        inc     tmp1+1
        bcs     start
.endproc

; Actions for LOOPS
.proc   patch_codep
        ; Patches saved position with current position
        sta     tmp2
        stx     tmp2+1
        jsr     get_codep
        ldy     #0
        clc
        adc     reloc_addr
        sta     (tmp2),y
        iny
        txa
        adc     reloc_addr+1
        sta     (tmp2),y
        clc
        rts     ; C is cleared on exit!
.endproc

.proc   E_PUSH_LT
        ; Push current position, don't emit
        dec     opos            ; Remove LOOP TYPE from stack
        ldy     opos
        lda     (prog_ptr),y    ; Get the LOOP TYPE
.endproc        ; Fall through
.proc   push_codep
        ; Saves current code position in loop stack
        ldy     loop_sp
        sta     loop_stk, y
        pha
        jsr     get_codep
        iny
        sta     loop_stk, y
        iny
        txa
        sta     loop_stk, y
        iny
        bmi     loop_error
        sty     loop_sp
        pla
        and     #$7F
        cmp     #LT_LAST_JUMP+1
        bcs     xit
        inc     opos
        inc     opos
xit:    clc
        rts     ; C is cleared on exit!
.endproc

.proc   loop_error
        lda     #ERR_LOOP
        jmp     parser_error
.endproc

.proc   pop_codep
        ; Saves current code position in loop stack
        ldy     loop_sp
        dey
        dey
        dey
        sty     loop_sp
        bmi     loop_error
        ; Check if loop type is correct
retry:  cmp     loop_stk, y
        beq     ok
        ; If loop type is "ELSE", accept also "IF"
        cmp     #LT_ELSE
        bne     loop_error
        lda     #LT_IF
        bne     retry
ok:     ; Get saved position
        iny
        iny
        lda     loop_stk, y
        tax
        dey
        lda     loop_stk, y
rtsclc: clc
        rts     ; C is cleared on exit!
.endproc

.proc   E_POP_PROC_2
        ; Pop saved position, store
        lda     #LT_PROC_2
        jsr     pop_codep
.endproc        ; Falls through
.proc   check_loop_exit
        ; Checks if there is an "EXIT" in the stack, and adjust target pointer
        ldy     loop_sp
        dey
        dey
        dey
        bmi     pop_codep::rtsclc
        lda     loop_stk, y
        cmp     #LT_EXIT
        bne     pop_codep::rtsclc
        ; Yes, pop and patch
        sty     loop_sp
        iny
        iny
        lda     loop_stk, y
        tax
        dey
        lda     loop_stk, y
        jsr     patch_codep
        ; And check for more possible EXIT's
        jmp     check_loop_exit
.endproc

.proc   E_POP_DATA
        ; Pop saved position, store
        lda     #LT_DATA
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_POP_PROC_1
        ; Pop saved "jump to end" position
        lda     #LT_PROC_1
        jsr     pop_codep
        jmp     patch_codep
.endproc

.proc   E_POP_WHILE
        ; Pop saved "jump to end" position
        lda     #LT_WHILE_2
        jsr     pop_codep
        ; Save current position + 2 (skip over jump)
        inc     opos
        inc     opos
        jsr     patch_codep
        ; Pop saved "loop reentry" position
        lda     #LT_WHILE_1
        jsr     pop_codep
        ; And store
        dec     opos
        dec     opos
        jsr     emit_addr
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_LOOP
        ; Pop saved position, store
        lda     #LT_DO_LOOP
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_POP_REPEAT
        ; Pop saved position, store
        lda     #LT_REPEAT
        jsr     pop_codep
        jsr     emit_addr
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_FOR
        ; Pop saved "jump to end" position
        lda     #LT_FOR_2
        jsr     pop_codep
        ; Save current position + 1 (skip over jump)
        inc     opos
        jsr     patch_codep
        ; Pop saved "loop reentry" position
        lda     #LT_FOR_1
        jsr     pop_codep
        ; And store
        dec     opos
        dec     opos
        jsr     emit_addr
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_IF
        ; Patch IF/ELSE with current position
        lda     #LT_ELSE
        jsr     pop_codep
        jsr     patch_codep
.endproc        ; Fall through
.proc   check_elif
        ldy     loop_sp
        dey
        dey
        dey
        bmi     no_elif
        lda     #LT_ELIF
        cmp     loop_stk, y
        bne     no_elif
        ; ELIF, remove from stack and patch
        jsr     pop_codep
        jmp     patch_codep
no_elif:
        clc
        rts
.endproc

.proc   E_ELIF
        ldy     #LT_ELIF
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_ELSE
        ldy     #LT_ELSE
        sty     type+1
        ; Pop the old position to patch (from IF)
        lda     #LT_IF
        jsr     pop_codep
        sta     tmp1
        stx     tmp1+1
        ; Test if there is an ELIF to pop here
        dec     opos
        jsr     check_elif
        inc     opos
        ; Emit a jump to a new position
type:   lda     #LT_ELSE
        jsr     push_codep
        ; Parch current position + 2 (over jump)
        lda     tmp1
        ldx     tmp1+1
        jmp     patch_codep
.endproc

.proc   E_EXIT_LOOP
        ; Search the loop stack for a loop (not "I"f nor "E"lse) and inserts a
        ; patching code before
        ldy     loop_sp
retry:  dey
        dey
        dey
        bmi     loop_error
        lda     loop_stk, y
        bmi     retry           ; FOR(2)/WHILE(2)/IF/ELSE/ELIF are > 127
        cmp     #LT_DATA+1      ; PROC/DATA
        bcc     loop_error
ok:
        ; Store slot
        sty     comp_y+1
        ; Check if enough stack
        ldx     loop_sp
        inx
        inx
        inx
        bmi     loop_error

        ; Move all stack 3 positions up
        ldy     loop_sp
        stx     loop_sp
move:
        dey
        lda     loop_stk, y
        dex
        sta     loop_stk, x
comp_y: cpy     #$FF
        bne     move

        ; Store our new stack entry
        lda     loop_sp
        pha
        ldy     comp_y+1
        sty     loop_sp
        lda     #LT_EXIT
        jsr     push_codep
        pla
        sta     loop_sp
        clc
        rts
loop_error:
        jmp     ::loop_error
.endproc

; vi:syntax=asm_ca65

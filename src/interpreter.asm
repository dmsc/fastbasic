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

; The opcode interpreter
; ----------------------

        .export         interpreter_run, saved_cpu_stack
        .exportzp       interpreter_cptr

        ; From allloc.asm
        .importzp       var_buf, array_ptr, mem_end
        .import         clear_data, alloc_array
        ; From parser.asm
        .importzp       bptr, bpos

        ; From runtime.asm
        .import         umul16, sdiv16, smod16, neg_AX, read_word
        .import         print_word, getkey, getc, putc
        .import         move_up_src, move_up_dst, move_up
        .import         move_dwn_src, move_dwn_dst, move_dwn
        .import         graphics, cio_close, close_all, sound_off
        .importzp       tmp1, tmp2, tmp3, tabpos
        .importzp       IOCHN, COLOR, IOERROR

        ; From io.asm
        .import         getline, line_buf
        ; Define our segment
        .import         __INTERP_LOAD__, __INTERP_RUN__, __INTERP_SIZE__



        .zeropage
sptr    =       bpos    ; Use bpos as stack pointe

.define STACK_SIZE      64
        ; Our execution stack 64 words max, aligned for maximum speed
stack_l =       $480
stack_h =       $480 + STACK_SIZE

;----------------------------------------------------------------------

; This is the main threaded interpreter, jumps to the next
; execution opcode from the opcode-stream.
;
; To execute faster, the code is run from page zero, using 16 bytes
; that include the pointer (at the "cload: LDY" instruction). The A
; and X registers are preserved across calls, and store the top of
; the 16bit stack.
;
; All the execution routines jump back to the next_instruction label,
; so the minimum time for an opcode is 28 cycles, this means we could
; execute at up to 63k opcodes per second.
;
        ; Code in ZP: (16 bytes)
        .segment "INTERP": zeropage
.proc   interpreter
nxt_incsp:
        inc     sptr
nxtins:
cload:  ldy     $1234           ;4
        inc     z:cload+1       ;5
        bne     adj             ;2
        inc     z:cload+2       ;1 (1 * 255 + 5 * 1) / 256 = 1.016
adj:    sty     z:jump+1        ;3
jump:   jmp     (OP_JUMP)       ;5 = 25 cycles per call

.endproc

cptr                    =       interpreter::cload+1
next_instruction        =       interpreter::nxtins
next_ins_incsp          =       interpreter::nxt_incsp
interpreter_cptr        =       cptr

        ; Rest of interpreter is in runtime segment
        .segment        "RUNTIME"

        ; Main interpreter call
.proc   interpreter_run

        ; Init code pointer
        sta     cptr
        stx     cptr+1

        ; Get memory for all variables and clear the values
        jsr     clear_data
        ; Close al I/O channels
        jsr     close_all
        ; Sound off
        jsr     sound_off
        ; Clear TAB position
        lda     #0
        sta     tabpos
        ; And IO ERROR
        sta     IOERROR
        ; Store current stack position to rewind on error
        tsx
        stx     saved_cpu_stack

        ; Init stack-pointer
        lda     #STACK_SIZE
        sta     sptr

        ; Interpret opcodes
        jmp     next_instruction
.endproc

        ; Reads variable number from opcode stream, returns
        ; variable address in AX
.proc   get_op_var
        jsr     pushAX
        ldy     #0
        lda     (cptr), y
        inc     cptr
        bne     :+
        inc     cptr+1
:       ldx     var_buf+1
        asl
        bcc     :+
        inx
        clc
:
        adc     var_buf
        bcc     :+
        inx
:
        rts
.endproc

        ; Stores AX into stack, at return Y is the stack pointer.
.proc   pushAX
        dec     sptr
        ldy     sptr
        sta     stack_l, y
        txa
        sta     stack_h, y
        rts
.endproc

.proc   TOK_END ; RETURN
        ldx     #0
::saved_cpu_stack = * - 1
        txs
        rts
.endproc

;.proc   TOK_DUP
;        jsr     pushAX
;        lda     stack_l, y
;        jmp     next_instruction
;.endproc

.proc   TOK_SHL8
        tax
        lda     #0
        jmp     next_instruction
.endproc

.proc   TOK_SGN
        cpx     #0
        bmi     neg
        bne     pos
        tax
        beq     zro
pos:    lda     #1
zro:    ldx     #0
        beq     xit
neg:    lda     #$FF
        tax
xit:    jmp     next_instruction

.endproc

.proc   TOK_ABS
        cpx     #0
        bpl     go_next_ins
.endproc        ; Fall through
.proc   TOK_NEG ; AX = -AX
        jsr     neg_AX
xit:    jmp     next_instruction
.endproc
go_next_ins=    TOK_NEG::xit

.proc   TOK_USHL ; AX = AX * 2 (UNSIGNED)
        asl
        tay
        txa
        rol
        tax
        tya
        jmp     next_instruction
.endproc

.proc   TOK_BIT_AND ; AX = (SP+) & AX
        ldy     sptr
        and     stack_l, y
        pha
        txa
        and     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

.proc   TOK_BIT_OR ; AX = (SP+) | AX
        ldy     sptr
        ora     stack_l, y
        pha
        txa
        ora     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

.proc   TOK_BIT_EXOR ; AX = (SP+) ^ AX
        ldy     sptr
        eor     stack_l, y
        pha
        txa
        eor     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

TOK_SUB:
        jsr     neg_AX
        ; Fall through
.proc   TOK_ADD ; AX = (SP+) + AX
        ldy     sptr
        clc
        adc     stack_l, y
        pha
        txa
        adc     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

.proc   TOK_MUL  ; AX = (SP+) * AX
        ldy     sptr
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        ldx     stack_h, y
        jsr     umul16
        jmp     next_ins_incsp
.endproc

.proc   TOK_DIV  ; AX = (SP+) / AX
        ldy     sptr
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        ldx     stack_h, y
        jsr     sdiv16
        jmp     next_ins_incsp
.endproc

.proc   TOK_MOD  ; AX = (SP+) % AX
        ldy     sptr
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        ldx     stack_h, y
        jsr     smod16
        jmp     next_ins_incsp
.endproc

.proc   TOK_VAR_ADDR  ; AX = address of variable
        jsr     get_op_var
        jmp     next_instruction
.endproc

.proc   TOK_NUM  ; AX = read from op (load byte first!)
        jsr     pushAX
        ldy     #1              ; 2
        lda     (cptr), y       ; 5
        tax                     ; 2
        dey                     ; 2
        lda     (cptr), y       ; 5
        inc     cptr            ; 5
        beq     adjust_cptr_1   ; 2
        inc     cptr            ; 5
        beq     adjust_cptr     ; 2=30
        jmp     next_instruction
adjust_cptr_1:
        inc     cptr
adjust_cptr:
        inc     cptr+1
        jmp     next_instruction
.endproc

.proc   TOK_BYTE  ; AX = read 1 byte from op
        jsr     pushAX
        ldy     #0
        lda     (cptr), y
        ldx     #0
        inc     cptr
        beq     TOK_NUM::adjust_cptr
        jmp     next_instruction
.endproc

.proc   TOK_CSTRING     ; AX = address of string
        jsr     pushAX
        lda     cptr
        pha
        ldx     cptr+1
        ldy     #0      ; Get string length into A
        sec
        adc     (cptr), y
        sta     cptr
        pla
        bcs     TOK_NUM::adjust_cptr_1
        inc     cptr
        bne     :+
        inc     cptr+1
:       jmp     next_instruction
.endproc

.proc   TOK_CDATA       ; AX = address of data
        jsr     pushAX
        ldx     cptr+1
        lda     cptr
        clc
        adc     #2
        bcc     :+
        inx
:       jmp     TOK_JUMP
.endproc

        ; Array dimensioning - assigns an address to given array variable
.proc   TOK_DIM         ; AX = array size, (SP) = variable address
        ldy     array_ptr
        sty     ret_a+1
        ldy     array_ptr+1
        sty     ret_x+1
        jsr     alloc_array
        bcs     memory_error
ret_a:  lda     #0
ret_x:  ldx     #0
        jmp     TOK_DPOKE
.endproc

.proc  memory_error
        ; Show message and ends
        ldx     #len

:       lda     msg, x
        jsr     putc
        dex
        bpl     :-
        jmp     TOK_END
msg:    .byte $9b, "rorrE yromeM", $9b
len=    * - msg
.endproc

; Copy one string to another, allocating the destination if necessary
.proc   TOK_COPY_STR    ; AX: source string   (SP): destination *variable* address
        ; Store source
        pha
        txa
        pha
        ; Get destination pointer - allocate if 0
        ldy     sptr
        lda     stack_l, y
        sta     tmp1
        lda     stack_h, y
        sta     tmp1+1
        ldy     #0
        lda     (tmp1), y
        sta     tmp2
        iny
        lda     (tmp1), y
        sta     tmp2+1
        bne     ok
        ; Copy current memory pointer to the variable
        lda     array_ptr+1
        sta     (tmp1), y
        sta     tmp2+1
        dey
        lda     array_ptr
        sta     (tmp1), y
        sta     tmp2
        ; Allocate 256 bytes
        lda     #0
        ldx     #1
        jsr     alloc_array
        bcs     memory_error
ok:
        ; Get source pointer and check if it is allocated
        pla
        sta     tmp1+1
        pla
        sta     tmp1
        ldy     #0
        ora     tmp1+1
        beq     nul
        ; Copy len
        lda     (tmp1), y
nul:    sta     (tmp2), y
        tay
        beq     pop_stack_2
        ; Copy data
cloop:  lda     (tmp1), y
        sta     (tmp2), y
        dey
        bne     cloop
        beq     pop_stack_2
.endproc

.proc   TOK_DPOKE  ; DPOKE (SP++), AX
        pha
        ldy     sptr
        lda     stack_h, y
.if 0
        sta     tmp1+1
        lda     stack_l, y
        sta     tmp1
        ldy     #0
        pla
        sta     (tmp1), y
        txa
        iny
        sta     (tmp1), y
.else
        ; Self-modifying code, 4 cycles faster and 1 byte larger than the above
        sta     save_l+2
        sta     save_h+2
        txa
        ldx     stack_l, y
save_h: sta     $FF01, x
        pla
save_l: sta     $FF00, x
.endif
        ; Fall through
.endproc
pop_stack_2:
        inc     sptr
.proc   pop_stack
        ldy     sptr
        lda     stack_l, y
        ldx     stack_h, y
        jmp     next_ins_incsp
.endproc

pop_stack_3:
        inc     sptr
        bne     pop_stack_2

        ; Calls CIOV, stores I/O error, resets IOCHN and pops stack
.proc   CIOV_POP
        jsr     CIOV
ioerr:
        sty     IOERROR
iochn0:
        lda     #0
        sta     IOCHN
        beq     pop_stack
.endproc

.proc   TOK_PEEK  ; AX = *(AX)
.if 0
        sta     tmp1
        stx     tmp1+1
        ldy     #0
        lda     (tmp1),y
.else
        ; Self-modifying code, 3 cycles faster and 1 byte shorter than the above
        stx     load+2
        tax
load:   lda     $FF00, x
.endif
        ldx     #0
        jmp     next_instruction
.endproc

.proc   TOK_INC ; DPOKE(AX, DPEEK(AX) + 1)
        stx     loadH+2
        stx     loadL+2
        tax
loadL:  inc     $FF00, x
        bne     :+
loadH:  inc     $FF01, x
:       jmp     pop_stack
.endproc

.proc   TOK_VAR_LOAD  ; AX = value of variable
        jsr     get_op_var
        ; Fall through:
        ; jmp     TOK_DPEEK
.endproc

.proc   TOK_DPEEK  ; AX = PEEK(AX) + 256 * PEEK(AX+1)
.if 0
        sta     tmp1
        stx     tmp1+1
        ldy     #1
        lda     (tmp1),y
        tax
        dey
        lda     (tmp1),y
.else
        ; self-modifying code, 4 cycles faster and 1 byte longer than the above
        stx     loadH+2
        stx     loadL+2
        tay
loadH:  ldx     $FF01, y
loadL:  lda     $FF00, y
.endif
        jmp     next_instruction
.endproc

; Stores an EOL at end of string, to allow calling SIO routines
.proc   get_str_eol
        sta     bptr
        stx     bptr+1
        ; Get length
        ldy     #0
        lda     (bptr), y
        tay
        iny
        bne     ok
        dey     ; String too long, just overwrite last character
ok:     lda     #$9B
        sta     (bptr), y
        ldy     #1
        rts
.endproc

.proc   TOK_VAL
        jsr     get_str_eol
        jsr     read_word
        bcc     :+
        lda     #18
        sta     IOERROR
:       jmp     next_instruction
.endproc

.proc   TOK_TIME
        jsr     pushAX
retry:  ldx     19
        lda     20
        cpx     19
        bne     retry
        jmp     next_instruction
.endproc

.proc   TOK_FRE
        jsr     pushAX
        lda     MEMTOP
        sec
        sbc     mem_end
        tay
        lda     MEMTOP+1
        sbc     mem_end+1
        tax
        tya
        jmp     next_instruction
.endproc

.proc   TOK_RAND        ; AX= RANDDOM from 0 to AX-1

        ; First get a mask from the value-1
        stx     tmp1+1
        cpx     #0
        bmi     ok

        ldy     #0
get_l:  iny
        asl
        rol     tmp1+1
        bpl     get_l
ok:
        sta     tmp1

        ; Now, get a number in the range
retry:  lda     RANDOM
        tax
        cmp     tmp1
        lda     RANDOM
        sta     tmp2
        sbc     tmp1+1
        bcs     retry

        ; And scale back
        txa
        cpy     #0
        beq     xit
scale:  lsr     tmp2
        ror
        dey
        bne     scale
xit:    ldx     tmp2
        jmp     next_instruction
.endproc

.proc   TOK_GETKEY
        jsr     pushAX
        jsr     getkey
        sty     IOERROR
        ldx     #0
        jmp     next_instruction
.endproc

.proc   TOK_L_NOT  ; A = !A
        eor     #1
        jmp     next_instruction
.endproc

.proc   TOK_L_OR  ; A = A | (SP+)
        ldy     sptr
        ora     stack_l, y
        jmp     next_ins_incsp
.endproc

.proc   TOK_L_AND  ; A = A & (SP+)
        ldy     sptr
        and     stack_l, y
        jmp     next_ins_incsp
.endproc

.proc   TOK_FOR
        jsr     pushAX
        ; In stack we have:
        ;       y   = step
        ;       y+1 = limit
        ;       y+2 = var_address
        ; Read variable value, compare with limit
        stx     tmp2
        lda     stack_h+2, y
        sta     tmp1+1
        lda     stack_l+2, y
        sta     tmp1

        ldy     #1
        lda     (tmp1), y
        tax
        dey
        lda     (tmp1), y
        ; Now, compare with limit
        jsr     pushAX
        lda     stack_l+2, y
        ldx     stack_h+2, y
        asl     tmp2
        bcs     TOK_GEQ
positive:
        ; Fall through
.endproc

.proc   TOK_LEQ  ; AX = (SP+) <= AX
        ldy     sptr
        cmp     stack_l, y
        txa
        sbc     stack_h, y
        bvc     :+
        eor     #$80
:       bmi     set0
        bpl     set1
.endproc

.proc   TOK_GEQ  ; AX = (SP+) >= AX
        sta     tmp1
        stx     tmp1+1
        ldy     sptr
        lda     stack_l, y
        cmp     tmp1
        lda     stack_h, y
        sbc     tmp1+1
        bvc     :+
        eor     #$80
:       bpl     set1
        bmi     set0
.endproc

TOK_0:
        jsr     pushAX
        dec     sptr
.proc   set0
        lda     #0
        tax
        jmp     next_ins_incsp
.endproc

TOK_1:
        jsr     pushAX
        dec     sptr
.proc   set1
        lda     #1
        ldx     #0
        jmp     next_ins_incsp
.endproc

.proc   TOK_NEQ  ; AX = AX != (SP+)
        ldy     sptr
        cmp     stack_l, y
        bne     set1
        txa
        eor     stack_h, y
        bne     set1
        tax
        jmp     next_ins_incsp
.endproc

.proc   TOK_EQ  ; AX = AX == (SP+)
        ldy     sptr
        cmp     stack_l, y
        bne     set0
        txa
        eor     stack_h, y
        bne     set0
        beq     set1
.endproc

.proc   TOK_COMP_0  ; AX = AX != 0
        stx     tmp1
        ora     tmp1
        beq     ret_0
        lda     #1
        ldx     #0
ret_0:  jmp     next_instruction
.endproc

.proc   TOK_PRINT_NUM  ; PRINT (SP+)
        jsr     print_word
        jmp     pop_stack
.endproc

.proc   TOK_PRINT_STR   ; PRINT string
        sta     tmp1
        stx     tmp1+1
        ldy     #0
        lda     (tmp1), y       ; LENGTH
        beq     nil
        sta     tmp2
loop:   iny
        lda     (tmp1), y
        jsr     putc
        cpy     tmp2
        bne     loop
nil:    jmp     pop_stack
.endproc

.proc   TOK_PRINT_EOL   ; PRINT EOL
        jsr     pushAX
        ; Reset tab position
        lda     #1
        sta     tabpos
        lda     #$9b
.endproc        ; Fall through
.proc   TOK_PUT
        jsr     putc
        jmp     CIOV_POP::iochn0
.endproc

.proc   TOK_PRINT_TAB   ; PRINT TAB
        jsr     pushAX
        lda     #$20
        jsr     putc
:       jsr     putc
        ldx     tabpos
        bne     :-
        jmp     pop_stack
.endproc

.proc   TOK_GET
        jsr     pushAX
        jsr     getc
        sty     IOERROR
        ldx     #0
        stx     IOCHN
        jmp     next_instruction
.endproc

.proc   TOK_INPUT_STR   ; INPUT to string buffer (INBUFF)
        jsr     pushAX
        ldx     IOCHN
        jsr     getline
        sty     IOERROR
        sta     line_buf - 1    ; Assume that this location is available
        beq     no_eol  ; EOF
        cpy     #$88
        beq     no_eol
        tya
        bmi     no_eol  ; TODO: ERROR!?
        dec     line_buf - 1
no_eol:
        lda     #<(line_buf-1)
        ldx     #>(line_buf-1)
        jmp     next_instruction
.endproc

.proc   TOK_POKE  ; POKE (SP++), AX
        tax
        ldy     sptr
        lda     stack_h, y
.if 0
        sta     tmp1+1
        lda     stack_l, y
        sta     tmp1
        txa
        ldy     #0
        sta     (tmp1), y
.else
        ; Self-modifying code, 2 cycles faster and 2 bytes shorter than the above
        sta     save+2
        txa
        ldx     stack_l, y
save:   sta     $FF00, x
.endif
        jmp     pop_stack_2
.endproc


.proc   TOK_JUMP
        sta     save_a+1
no_a:   stx     save_x+1
        ldy     #1
        lda     (cptr), y
        tax
        dey
        lda     (cptr), y
        sta     cptr
        stx     cptr+1
save_a: lda     #$ff
save_x: ldx     #$ff
        jmp     next_instruction
.endproc

.proc   TOK_CALL
        sta     TOK_JUMP::save_a+1
        lda     cptr
        clc
        adc     #2
        pha
        lda     cptr+1
        adc     #0
        pha
        jmp     TOK_JUMP::no_a
.endproc

.proc   TOK_RET
        tay
        pla
        sta     cptr+1
        pla
        sta     cptr
        tya
        jmp     next_instruction
.endproc

.proc   TOK_CJUMP
        cmp     #0
        bne     skip
        ldy     #1
        lda     (cptr), y
        tax
        dey
        lda     (cptr), y
        sta     cptr
        stx     cptr+1
        jmp     pop_stack
skip:   inc     cptr
        beq     adjust_cptr_1
        inc     cptr
        beq     adjust_cptr
        jmp     pop_stack
adjust_cptr_1:
        inc     cptr
adjust_cptr:
        inc     cptr+1
        jmp     pop_stack
.endproc

.proc   TOK_FOR_START
        ; In stack we have:
        ;       AX = start value
        ;       y  = var_address
        pha
        ldy     sptr
        lda     stack_h, y
        sta     save_l+2
        sta     save_h+2
        txa
        ldx     stack_l, y
save_h: sta     $FF01, x
        pla
save_l: sta     $FF00, x
        jmp     pop_stack
.endproc

.proc   TOK_FOR_NEXT
        sta     tmp2
        ; In stack we have:
        ;       AX  = step
        ;       y   = limit
        ;       y+1 = var_address
        ; Read variable value, add to step and store into variable
        ldy     sptr
        lda     stack_h+1, y
        sta     tmp1+1
        lda     stack_l+1, y
        sta     tmp1

        ldy     #0
        clc
        lda     tmp2
        adc     (tmp1), y
        sta     (tmp1), y
        iny
        txa
        adc     (tmp1), y
        sta     (tmp1), y
        lda     tmp2
        jmp     next_instruction
.endproc

        ; Remove the FOR arguments from the stack!
TOK_FOR_EXIT    = pop_stack_3

.proc   TOK_MOVE  ; move memory up
        ldy     sptr
        pha
        lda     stack_l, y
        sta     move_up_dst
        lda     stack_h, y
        sta     move_up_dst+1
        lda     stack_l+1, y
        sta     move_up_src
        lda     stack_h+1, y
        sta     move_up_src+1
        pla
        jsr     move_up
        jmp     pop_stack_3
.endproc

.proc   TOK_NMOVE  ; move memory down
        ldy     sptr
        pha
        lda     stack_l, y
        sta     move_dwn_dst
        lda     stack_h, y
        sta     move_dwn_dst+1
        lda     stack_l+1, y
        sta     move_dwn_src
        lda     stack_h+1, y
        sta     move_dwn_src+1
        pla
        jsr     move_dwn
        jmp     pop_stack_3
.endproc

.proc   TOK_GRAPHICS  ; OPEN #6,12,0,
        jsr     graphics
        sty     IOERROR
        jmp     pop_stack
.endproc

        .include "atari.inc"

.proc   TOK_PLOT
        jsr     pushAX
        ldy     COLOR
        ldx     #$60    ; IOCB #6
        lda     ICAX1,X
        sta     ICAX1Z
        lda     ICAX2,X
        sta     ICAX2Z
        jsr     putchar_io
        sty     IOERROR
        jmp     pop_stack
.endproc

; Calls PUTCHAR for I/O channel X
.proc   putchar_io
        lda     ICPTH,X
        pha
        lda     ICPTL,X
        pha
        tya
        ldy     #$5C
        rts
.endproc

TOK_FILLTO:
        ldy     #FILLIN
        .byte   $2C   ; Skip 2 bytes over next "LDY"
.proc   TOK_DRAWTO
        ldy     #DRAWLN
        sty     ICCOM+$60
        jsr     pushAX
        lda     COLOR
        sta     ATACHR
        ldx     #$60    ; IOCB #6
        lda     #$0C
        sta     ICAX1, x
        lda     #$00
        sta     ICAX2, x
        jmp     CIOV_POP
.endproc

.proc   TOK_CLOSE
        jsr     pushAX
        ldx     IOCHN
        jsr     cio_close
        jmp     CIOV_POP::ioerr
.endproc

.proc   TOK_BPUT
        ldy     #PUTCHR
        .byte   $2C   ; Skip 2 bytes over next "LDY"
.endproc        ; Fall through
.proc   TOK_BGET
        ldy     #GETCHR
        sty     setcom+1
        stx     save_x+1

        ldx     IOCHN

        sta     ICBLL, x        ; Length
save_x: lda     #0
        sta     ICBLH, x

        ldy     sptr
        lda     stack_l, y
        sta     ICBAL, x        ; Address
        lda     stack_h, y
        sta     ICBAH, x

setcom: lda     #0
        sta     ICCOM, x
        inc     sptr
        jmp     CIOV_POP
.endproc

.proc   TOK_XIO
        jsr     get_str_eol
        ldy     bptr+1
        inc     bptr
        bne     :+
        iny
:       ldx     IOCHN
        tya
        sta     ICBAH, x
        lda     bptr
        sta     ICBAL, x
        lda     #0
        sta     ICBLH, x
        lda     #$FF
        sta     ICBLL, x
        ldy     sptr
        lda     stack_l, y
        sta     ICAX1, x
        lda     stack_h, y
        sta     ICAX2, x
        lda     stack_l+1, y
        sta     ICCOM, x
        inc     sptr
        inc     sptr
        jmp     CIOV_POP
.endproc

.proc   TOK_SOUND_OFF
        sta     save_a+1
        jsr     sound_off
save_a: lda     #0
        jmp     next_instruction
.endproc

.proc   TOK_PAUSE
        tay
        iny
        inx
wait:   lda     RTCLOK+2
:       cmp     RTCLOK+2
        beq     :-
        dey
        bne     wait
        dex
        bne     wait
        jmp     pop_stack
.endproc

; USR support
.proc   TOK_USR_PARAM   ; Stores AX as an usr parameter
        pha
        txa
        pha
        jmp     pop_stack
.endproc

.proc   TOK_USR_ADDR
        ; Store out return address into the CPU stack
        tay
        lda     #>(next_instruction - 1)
        pha
        lda     #<(next_instruction - 1)
        pha
        tya
        jmp     next_instruction
.endproc

.proc   TOK_USR_CALL
        ; Calls the routine, address is in AX
        sta     jump+1
        stx     jump+2
jump:   jmp     $FFFF
.endproc

        ; From parse.asm - MUST KEEP IN SAME ORDER!

        .segment "JUMPTAB"
        .align  256
OP_JUMP:
        ; Copied from basyc.syn, must be in the same order:
        .word   TOK_END
        ; Constant and variable loading
        .word   TOK_NUM, TOK_BYTE, TOK_CSTRING, TOK_CDATA, TOK_VAR_ADDR, TOK_VAR_LOAD
        .word   TOK_SHL8, TOK_0, TOK_1
        ; Numeric operators
        .word   TOK_NEG, TOK_ABS, TOK_SGN, TOK_ADD, TOK_SUB, TOK_MUL, TOK_DIV, TOK_MOD
        ; Bitwise operators
        .word   TOK_BIT_AND, TOK_BIT_OR, TOK_BIT_EXOR
        ; Functions
        .word   TOK_PEEK, TOK_DPEEK
        .word   TOK_TIME, TOK_FRE, TOK_RAND
        ; Boolean operators
        .word   TOK_L_NOT, TOK_L_OR, TOK_L_AND
        ; Comparisons
        .word   TOK_GEQ, TOK_LEQ, TOK_NEQ, TOK_EQ
        ; Convert from int to bool
        .word   TOK_COMP_0
        ; Low level statements
        .word   TOK_POKE, TOK_DPOKE, TOK_MOVE, TOK_NMOVE, TOK_INC
        ; Graphic support statements
        .word   TOK_GRAPHICS, TOK_PLOT, TOK_DRAWTO, TOK_FILLTO
        ; Print statements
        .word   TOK_PRINT_NUM, TOK_PRINT_STR, TOK_PRINT_TAB, TOK_PRINT_EOL
        ; I/O
        .word   TOK_GETKEY, TOK_INPUT_STR, TOK_XIO, TOK_CLOSE, TOK_GET, TOK_PUT
        .word   TOK_BPUT, TOK_BGET
        ; Jumps
        .word   TOK_JUMP, TOK_CJUMP, TOK_CALL, TOK_RET
        ; FOR loop support
        .word   TOK_FOR, TOK_FOR_START, TOK_FOR_NEXT, TOK_FOR_EXIT
        ; Arrays
        .word   TOK_DIM, TOK_USHL
        ; Strings
        .word   TOK_COPY_STR, TOK_VAL
        ; Sound off - could be implemented as simple POKE expressions, but it's shorter this way
        .word   TOK_SOUND_OFF
        .word   TOK_PAUSE
        ; USR, calls ML routinr
        .word   TOK_USR_ADDR, TOK_USR_PARAM, TOK_USR_CALL

; vi:syntax=asm_ca65

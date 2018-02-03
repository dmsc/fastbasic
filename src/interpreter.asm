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
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; The opcode interpreter
; ----------------------

        .export         interpreter_run, saved_cpu_stack, stack_l, stack_h
        .exportzp       interpreter_cptr, var_count, sptr

        ; From allloc.asm
        .importzp       var_buf, array_ptr, mem_end
        .import         clear_data, clear_memory, alloc_array

        ; From runtime.asm
        .import         umul16, neg_AX, read_word
        .import         divmod_sign_adjust
        .import         print_word, getkey, putc, putc_nosave
        .import         move_up_src, move_up_dst, move_up
        .import         move_dwn_src, move_dwn_dst, move_dwn
        .import         cio_close, close_all, sound_off
        .import         getline, line_buf
        .importzp       tmp1, tmp2, tmp3, tabpos, divmod_sign
        .importzp       IOCHN, COLOR, IOERROR

.ifdef FASTBASIC_FP
        ; Imported only in Floating Point version
        .import         print_fp, int_to_fp, read_fp
        .exportzp       DEGFLAG, DEGFLAG_RAD, DEGFLAG_DEG
.endif ; FASTBASIC_FP

        .include "atari.inc"

        .zeropage
var_count:
        .res    1

        ; Integer stack, 40 * 2 = 80 bytes
.define STACK_SIZE      40
        ; Our execution stack 64 words max, aligned for maximum speed
stack_l =       $480
stack_h =       $480 + STACK_SIZE

.ifdef FASTBASIC_FP
        ; FP stack pointer
fptr:   .res    1
        ; Temporary store for INT TOS
fp_tmp_a:       .res    1
fp_tmp_x:       .res    1
        ; DEG/RAD flag
DEGFLAG:        .res    1

        ; Floating point stack, 8 * 6 = 48 bytes.
        ; Total stack = 128 bytes
.define FPSTK_SIZE      8
fpstk_0 =       stack_h + STACK_SIZE
fpstk_1 =       fpstk_0 + FPSTK_SIZE
fpstk_2 =       fpstk_1 + FPSTK_SIZE
fpstk_3 =       fpstk_2 + FPSTK_SIZE
fpstk_4 =       fpstk_3 + FPSTK_SIZE
fpstk_5 =       fpstk_4 + FPSTK_SIZE
.endif ; FASTBASIC_FP

;----------------------------------------------------------------------

; This is the main threaded interpreter, jumps to the next
; execution opcode from the opcode-stream.
;
; To execute faster, the code is run from page zero, using 16 bytes
; that include the pointer (at the "cload: LDY" instruction). The A
; and X registers are preserved across calls, and store the top of
; the 16bit stack. The Y register is loaded with the stack pointer
; (sptr).
;
; All the execution routines jump back to the next_instruction label,
; so the minimum time for an opcode is 30 cycles, this means we could
; execute at up to 58k opcodes per second.
;
        ; Code in ZP: (16 bytes)
        .segment "INTERP": zeropage
.proc   interpreter
nxt_incsp:
        inc     z:sptr
nxtins:
cload:  ldy     $1234           ;4
        inc     z:cload+1       ;5
        bne     adj             ;2
        inc     z:cload+2       ;1 (1 * 255 + 5 * 1) / 256 = 1.016
adj:    sty     z:jump+1        ;3
ldsptr: ldy     #0              ;2
jump:   jmp     (OP_JUMP)       ;5 = 27 cycles per call

.endproc

sptr                    =       interpreter::ldsptr+1
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
        ; Clear TAB position, IO channel and IO error
        lda     #0
        sta     tabpos
        sta     IOCHN
        sta     IOERROR
        ; Store current stack position to rewind on error
        tsx
        stx     saved_cpu_stack

        ; Init stack-pointer
        lda     #STACK_SIZE
        sta     sptr
.ifdef FASTBASIC_FP
        lda     #FPSTK_SIZE
        sta     fptr
        lda     #DEGFLAG_RAD
        sta     DEGFLAG
.endif ; FASTBASIC_FP

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
        sta     stack_l-1, y
        txa
        sta     stack_h-1, y
        rts
.endproc

;.proc   TOK_DUP
;        jsr     pushAX
;        lda     stack_l-1, y
;        ldx     stack_h-1, y
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
        beq     xit
pos:    lda     #1
        ldx     #0
        beq     xit
neg:    lda     #$FF
        tax
xit:    jmp     next_instruction
.endproc

.proc   TOK_ABS
        cpx     #0
        bpl     TOK_SGN::xit
.endproc        ; Fall through
.proc   TOK_NEG ; AX = -AX
        jsr     neg_AX
        jmp     next_instruction
.endproc

.proc   TOK_DIV  ; AX = (SP+) / AX
        jsr     divmod_sign_adjust
        bit     divmod_sign
        bmi     TOK_NEG
        jmp     next_instruction
.endproc

.proc   TOK_MOD  ; AX = (SP+) % AX
        jsr     divmod_sign_adjust
        lda     tmp2
        ldx     tmp2+1
        bit     divmod_sign
        bvs     TOK_NEG
        jmp     next_instruction
.endproc

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
        and     stack_l, y
        pha
        txa
        and     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

.proc   TOK_BIT_OR ; AX = (SP+) | AX
        ora     stack_l, y
        pha
        txa
        ora     stack_h, y
        tax
        pla
        jmp     next_ins_incsp
.endproc

.proc   TOK_BIT_EXOR ; AX = (SP+) ^ AX
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
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        ldx     stack_h, y
        jsr     umul16
        lda     tmp1            ; Load the result
        ldx     tmp1+1
        jmp     next_ins_incsp
.endproc

.proc   TOK_VAR_ADDR  ; AX = address of variable
        jsr     get_op_var
        jmp     next_instruction
.endproc

.proc   TOK_NUM  ; AX = read from op (load byte first!)
        jsr     pushAX
        ldy     #1              ; 2     2
        lda     (cptr), y       ; 5     2
        tax                     ; 2     1
        dey                     ; 2     1
        lda     (cptr), y       ; 5     2

        inc     cptr            ; 5     2
        beq     adjust_cptr_1   ; 2     2
        inc     cptr            ; 5     2
        beq     adjust_cptr     ; 2=30  2=16
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
        beq     TOK_NUM::adjust_cptr
        jmp     next_instruction
.endproc

        ; Array dimensioning - assigns an address to given array variable
.proc   TOK_DIM         ; AX = array size, (SP) = variable address
        ldy     array_ptr
        sty     tmp2
        ldy     array_ptr+1
        sty     tmp2+1
        jsr     alloc_array
        bcs     memory_error
        ; Now we have to cleanup the area
        jsr     clear_memory
        lda     tmp2
        ldx     tmp2+1
        ldy     sptr
        jmp     TOK_DPOKE
.endproc

memory_error_msg:
        .byte $9b, "rorrE yromeM", $9b
memory_error_len=    * - memory_error_msg

.proc  memory_error
        ; Show message and ends
        ldy     #memory_error_len-1

:       lda     memory_error_msg, y
        jsr     putc
        dey
        bpl     :-
.endproc ; Fall through

.proc   TOK_END ; RETURN
        ldx     #0
::saved_cpu_stack = * - 1
        txs
        rts
.endproc

; Copy one string to another, allocating the destination if necessary
.proc   TOK_COPY_STR    ; AX: source string   (SP): destination *variable* address
        ; Store source
        pha
        txa
        pha
        ; Get destination pointer - allocate if 0
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

.proc   TOK_MOVE  ; move memory up
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
pop_stack_3:
        inc     sptr
        bne     pop_stack_2
.endproc

        ; Remove the FOR arguments from the stack!
TOK_FOR_EXIT    = TOK_MOVE::pop_stack_3

.proc   TOK_XIO
        jsr     get_str_eol
        ldx     IOCHN
        tya
        clc
        adc     INBUFF
        sta     ICBAL, x
        lda     #0
        sta     ICBLH, x
        adc     INBUFF+1
        sta     ICBAH, x
        lda     #$FF
        sta     ICBLL, x
        ldy     sptr
        lda     stack_l, y
        sta     ICAX1, x
        lda     stack_h, y
        sta     ICAX2, x
        lda     stack_l+1, y
        inc     sptr
is_cio: inc     sptr
.endproc        ; Fall through
        ; Calls CIO with given command, stores I/O error, resets IOCHN, pops stack
CIOV_CMD_POP:
        sta     ICCOM, x
        ; Calls CIOV, stores I/O error, resets IOCHN and pops stack
.proc   CIOV_POP
        jsr     CIOV
ioerr:
        sty     IOERROR
iochn0:
        ldy     #0
        sty     IOCHN
        beq     pop_stack
.endproc

.proc   TOK_IOCHN0
        ldy     #0
        sty     IOCHN
        jmp     next_instruction
.endproc

.proc   TOK_BPUT
        ldy     #PUTCHR
        .byte   $2C   ; Skip 2 bytes over next "LDY"
.endproc        ; Fall through
.proc   TOK_BGET
        ldy     #GETCHR
        sty     setcom+1
        tay
        txa

        ldx     IOCHN

        sta     ICBLH, x
        tya
        sta     ICBLL, x        ; Length

        ldy     sptr
        lda     stack_l, y
        sta     ICBAL, x        ; Address
        lda     stack_h, y
        sta     ICBAH, x

setcom: lda     #0
        bne     TOK_XIO::is_cio ; Note: A is never 0
.endproc

.proc   TOK_NMOVE  ; move memory down
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
        jmp     TOK_MOVE::pop_stack_3
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

.proc   TOK_DEC ; DPOKE(AX, DPEEK(AX) - 1)
        stx     loadH+2
        stx     loadL1+2
        stx     loadL2+2
        tax
loadL1: ldy     $FF00, x
        bne     loadL2
loadH:  dec     $FF01, x
loadL2: dec     $FF00, x
        jmp     pop_stack
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
        sta     INBUFF
        stx     INBUFF+1
        ; Get length
        ldy     #0
        lda     (INBUFF), y
        tay
        iny
        bne     ok
        dey     ; String too long, just overwrite last character
ok:     lda     #$9B
        sta     (INBUFF), y
        ldy     #1
        sty     CIX
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

.proc   TOK_RAND        ; AX= RANDOM from 0 to AX-1

        ldy     #$80
        stx     tmp1+1

get_l:  dey
        beq     xit
        asl
        rol     tmp1+1
        bpl     get_l
        sta     tmp1

        ; Now, get a number in the range
retry:  ldx     RANDOM
        cpx     tmp1
        lda     RANDOM
        sta     tmp2
        sbc     tmp1+1
        bcs     retry

        ; And scale back
        txa
scale:  lsr     tmp2
        ror
        iny
        bpl     scale
        ldx     tmp2
xit:    jmp     next_instruction
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
        ora     stack_l, y
        jmp     next_ins_incsp
.endproc

.proc   TOK_L_AND  ; A = A & (SP+)
        and     stack_l, y
        jmp     next_ins_incsp
.endproc

.proc   TOK_FOR
        ; Store STEP into stack and HI part to temporary
        stx     tmp2+1
        jsr     pushAX

        ; Jumps to original FOR with a fake STEP=0, skips the
        ; first addition:
        ldx     #0
        stx     tmp2
        beq     TOK_FOR_NEXT_INIT
.endproc

.proc   TOK_FOR_NEXT
        ; Store STEP into stack (and also to temporary)
        sta     tmp2
        stx     tmp2+1
        jsr     pushAX

::TOK_FOR_NEXT_INIT:
        ; In stack we have:
        ;       y-1 = step
        ;       y   = limit
        ;       y+1 = var_address
        ; Read variable address value
        lda     stack_h+1, y
        sta     tmp1+1
        lda     stack_l+1, y
        sta     tmp1

        ; Copy LIMIT to the stack
        lda     stack_l, y
        sta     stack_l-2, y
        lda     stack_h, y
        sta     stack_h-2, y
        dec     sptr

        ; Get STEP again into AX
        lda     tmp2

        ; Adds STEP to VAR
        clc
        ldy     #0
        adc     (tmp1), y
        sta     (tmp1), y
        pha
        iny
        txa
        adc     (tmp1), y
        sta     (tmp1), y
        tax
        pla

        ; Now we have LIMIT and VAR in stack, compare
        ldy     sptr

        ; Check sign of STEP
        bit     tmp2+1
        bmi     TOK_GT
positive:
        ; Fall through
.endproc

.proc   TOK_LT  ; AX = (SP+) >= AX
        sta     tmp1
        stx     tmp1+1
        lda     stack_l, y
        cmp     tmp1
        lda     stack_h, y
        sbc     tmp1+1
        bvs     LTGT_set01
::LTGT_set10:
        bpl     set0
        bmi     set1
.endproc

.proc   TOK_GT  ; AX = (SP+) <= AX
        cmp     stack_l, y
        txa
        sbc     stack_h, y
        bvc     LTGT_set10
::LTGT_set01:
        bmi     set0
        bpl     set1
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
        cmp     stack_l, y
        bne     set1
        txa
        eor     stack_h, y
        bne     set1
        tax
        jmp     next_ins_incsp
.endproc

.proc   TOK_EQ  ; AX = AX == (SP+)
        cmp     stack_l, y
        bne     set0
        txa
        eor     stack_h, y
        bne     set0
        beq     set1
.endproc

.proc   TOK_CMP_STR     ; Compare string in (AX) with (SP), store 0, 1 or -1 in stack,
                        ; the load 0 to perform an integer comparison
        sta     tmp1
        txa
        beq     null_str1
        sta     tmp1+1

        lda     stack_l, y
        sta     tmp2
        ldx     stack_h, y
        beq     rtn_lt
        stx     tmp2+1

        ; Get lengths
        ldy     #0
        lda     (tmp1), y
        sta     tmp3
        lda     (tmp2), y
        sta     tmp3+1

        ; X is the return value
        ldx     #0

        ; Compare each byte
next_char:
        cpy     tmp3
        beq     end_str1
        cpy     tmp3+1
        beq     rtn_lt

        iny
        lda     (tmp1), y
        cmp     (tmp2), y
        beq     next_char

        bcs     rtn_lt
        bcc     rtn_gt

null_str1:
        cmp     stack_h, y
        .byte   $2C     ; Skip 2 bytes

end_str1:
        cpy     tmp3+1
        beq     xit

rtn_gt:
        inx
        .byte   $24     ; Skip 1 byte

rtn_lt:
        dex
xit:
        txa
        inc     sptr
        ldy     sptr
.endproc        ; Fall through TOK_0

TOK_0:
        jsr     pushAX
        dec     sptr
.proc   set0
        lda     #0
        tax
        jmp     next_ins_incsp
.endproc

.proc   TOK_COMP_0  ; AX = AX != 0
        tay
        bne     ret_1
        txa
        beq     ret_0
ret_1:  lda     #1
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
        ldx     IOCHN
        lda     #GETCHR
        sta     ICCOM, x
        lda     #0
        sta     ICBLL, x
        sta     ICBLH, x
        jsr     CIOV
        sty     IOERROR
        ldx     #0
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

.proc   TOK_CDATA       ; AX = address of data
        jsr     pushAX
        ldx     cptr+1
        lda     cptr
        clc
        adc     #2
        bcc     :+
        inx
:       ; ldy     sptr ; TOK_JUMP does not use Y=sptr
.endproc        ; Fall through
.proc   TOK_JUMP
        pha
        stx     save_x+1
        ldy     #1
        lda     (cptr), y
        tax
        dey
        lda     (cptr), y
        sta     cptr
        stx     cptr+1
save_x: ldx     #$ff
        pla
        jmp     next_instruction
.endproc

.proc   TOK_CALL
        tay
        lda     cptr
        clc
        adc     #2
        pha
        lda     cptr+1
        adc     #0
        pha
        tya
        bcc     TOK_JUMP
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
        tay
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

.proc   TOK_GRAPHICS  ; OPEN #6,12,0,
        sta     tmp1
        ldx     #$60
        jsr     cio_close
        lda     tmp1
        and     #$F0
        eor     #$1C    ; Get AUX1 from BASIC mode
        sta     ICAX1, x
        lda     tmp1    ; And AUX2
        sta     ICAX2, x
        lda     #<device_s
        sta     ICBAL, x
        lda     #>device_s
        sta     ICBAH, x
        lda     #OPEN
        jmp     CIOV_CMD_POP
device_s: .byte "S:", $9B
.endproc

.proc   TOK_PLOT
        jsr     pushAX
        ldy     COLOR
        ldx     #$60    ; IOCB #6
        jsr     putc_nosave
        jmp     CIOV_POP::ioerr
.endproc

TOK_FILLTO:
        ldy     #FILLIN
        .byte   $2C   ; Skip 2 bytes over next "LDY"
.proc   TOK_DRAWTO
        ldy     #DRAWLN
        sty     ICCOM+$60
        ldy     sptr
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
        lda     #CLOSE
        jmp     CIOV_CMD_POP
.endproc

.proc   TOK_SOUND_OFF
        pha
        jsr     sound_off
        pla
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

; Following two routines are only used in FP version
; TODO: Should move to a different source file
.ifdef FASTBASIC_FP

        ; Save INT stack to temporary, push FP stack
.proc   save_push_fr0
        sta     fp_tmp_a
        stx     fp_tmp_x
        ; Fall through
.endproc
        ; Push FP stack, FR0 remains unchanged.
.proc   push_fr0
        dec     fptr
        ldy     fptr
        lda     FR0+0
        sta     fpstk_0, y
        lda     FR0+1
        sta     fpstk_1, y
        lda     FR0+2
        sta     fpstk_2, y
        lda     FR0+3
        sta     fpstk_3, y
        lda     FR0+4
        sta     fpstk_4, y
        lda     FR0+5
        sta     fpstk_5, y
        rts
.endproc

        ; Save INT stack to temporary, move FR0 to FR1
        ; and pop stack to FR0
.proc   save_pop_fr1
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     FMOVE
        ; Fall through
.endproc
        ; Pops FP stack discarding FR0
.proc   pop_fr0
        ldy     fptr
        inc     fptr
        lda     fpstk_0, y
        sta     FR0
        lda     fpstk_1, y
        sta     FR0+1
        lda     fpstk_2, y
        sta     FR0+2
        lda     fpstk_3, y
        sta     FR0+3
        lda     fpstk_4, y
        sta     FR0+4
        lda     fpstk_5, y
        sta     FR0+5
        rts
.endproc

.proc   TOK_INT_FP      ; Convert INT to FP
        ; Save INT stack, push FP stack
        jsr     save_push_fr0
        ; Restore TOS
        lda     fp_tmp_a
        ldx     fp_tmp_x
        ; Convert to FP
        jsr     int_to_fp
        ; Discard top of INT stack
        jmp     pop_stack
.endproc

.proc   TOK_FP_INT      ; Convert FP to INT, with rounding
        jsr     pushAX
        asl     FR0
        ror     tmp1    ; Store sign in tmp1
        lsr     FR0
        jsr     FPI
        bcs     err3
        ldx     FR0+1
        bpl     ok
        ; Store error #3
err3:   lda     #3
        sta     IOERROR
        ; Negate result if original number was negative
ok:     lda     FR0
        ldy     tmp1
        bpl     pos
        jsr     neg_AX
        ; Store and pop FP stack
pos:    jsr     save_pop_fr1
        jmp     fp_return_interpreter
.endproc

.proc   TOK_PRINT_FP  ; PRINT (SP+)
        ; Store integer stack.
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     print_fp
        jsr     pop_fr0
        jmp     fp_return_interpreter
.endproc

.proc   fp_ldfr0
        jsr     pushAX
        lda     FR0
        rts
.endproc

.proc   TOK_FP_EQ
        jsr     fp_ldfr0
        bne     fp_set0
        ; Fall through
.endproc
.proc   fp_set1
        jsr     pop_fr0
        lda     #1
        ldx     #0
        jmp     next_instruction
.endproc

.proc   TOK_FP_GEQ
        jsr     fp_ldfr0
        bpl     fp_set1
        bmi     fp_set0
.endproc

.proc   TOK_FP_GT
        jsr     fp_ldfr0
        beq     fp_set0
        bpl     fp_set1
        ; Fall through
.endproc
.proc   fp_set0
        jsr     pop_fr0
        lda     #0
        tax
        jmp     next_instruction
.endproc

.proc   TOK_FP_ADD
        jsr     save_pop_fr1
        jsr     FADD
        jmp     check_fp_err
.endproc

.proc   TOK_FP_SUB
        jsr     save_pop_fr1
        jsr     FSUB
        jmp     check_fp_err
.endproc

.proc   TOK_FP_MUL
        jsr     save_pop_fr1
        jsr     FMUL
        jmp     check_fp_err
.endproc

.proc   TOK_FP_DIV
        jsr     save_pop_fr1
        jsr     FDIV
        jmp     check_fp_err
.endproc

.proc   TOK_FP_ABS
        asl     FR0
lft:    lsr     FR0
        jmp     next_instruction
.endproc

.proc   TOK_FP_NEG
        asl     FR0
        beq     ok
        bcs     TOK_FP_ABS::lft
        sec
        ror     FR0
ok:     jmp     next_instruction
.endproc

.proc   TOK_FP_SGN
        asl     FR0
        beq     zero
        ldy     #$80
        sty     FR0
        ror     FR0
        ldy     #$10
        sty     FR0+1
        ldy     #0
        sty     FR0+2
        sty     FR0+3
        sty     FR0+4
        sty     FR0+5
zero:   jmp     next_instruction
.endproc

.proc   TOK_FLOAT
        jsr     save_push_fr0

        ldy     #5
ldloop: lda     (cptr), y
        sta     FR0,y
        dey
        bpl     ldloop

        lda     cptr
        clc
        adc     #6
        sta     cptr
        bcc     fp_return_interpreter
        inc     cptr+1
        bcs     fp_return_interpreter
.endproc

.proc   TOK_FP_VAL
        jsr     get_str_eol
        jsr     push_fr0
        jsr     read_fp
        bcc     :+
        lda     #18
        sta     IOERROR
:       jmp     pop_stack
.endproc

.proc   TOK_FP_LOAD
        stx     FLPTR+1
        sta     FLPTR
        jsr     push_fr0
        jsr     FLD0P
        jmp     pop_stack
.endproc

.proc   TOK_FP_STORE
        stx     FLPTR+1
        sta     FLPTR
        jsr     FST0P
        ; Pop FP stack
        jsr     pop_fr0
        jmp     pop_stack
.endproc

.proc   TOK_FP_EXP
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     EXP
        ; Fall through
.endproc

        ; Checks FP error, restores INT stack
        ; and returns to interpreter
.proc   check_fp_err
        ; Check error from last FP op
        bcc     ok
::fp_ret_err3:
        lda     #3
        sta     IOERROR
ok:     ; Fall through
.endproc
.proc   fp_return_interpreter
; Restore INT stack
        lda     fp_tmp_a
        ldx     fp_tmp_x
        jmp     next_instruction
.endproc

.proc   TOK_FP_EXP10
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     EXP10
        jmp     check_fp_err
.endproc

        ; Square Root: Copied from Altirra BASIC
        ; Copyright (C) 2015 Avery Lee, All Rights Reserved.
.proc   TOK_FP_SQRT
FPHALF= $DF6C
        sta     fp_tmp_a
        stx     fp_tmp_x

        ; Store original X
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FST0R

        lda     FR0
        beq     fp_return_interpreter   ; X=0, we are done
        bmi     fp_ret_err3     ; X<0, error 3

        ; Calculate new exponent: E' = (E-$40)/2+$40 = (E+$40)/2
        clc
        adc     #$40    ;!! - also clears carry for loop below
        sta     FR0

        ; Compute initial guess, using a table
        ldx     #9
        stx     tmp2   ;!! Also set 4 iterations (by asl)
        lda     #$00
guess_loop:
        adc     #$11
        dex
        ldy     approx_compare_tab,x
        cpy     FR0+1
        bcc     guess_loop
guess_ok:
        ; Divide exponent by two, use lower guess digit if even
        lsr     FR0
        bcs     no_tens
        and     #$0f
no_tens:
        sta     FR0+1

iter_loop:
        ; Y = (Y + X/Y) * (1/2)
        ldy     #>PLYARG
        ldx     #<PLYARG
        jsr     FST0R   ; PLYARG = Y
        jsr     FMOVE   ; FR1 = Y
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FLD0R   ; FR0 = X
        jsr     FDIV    ; FR0 = FR0/FR1 = X/Y
        ldy     #>PLYARG
        ldx     #<PLYARG
        jsr     FLD1R   ; FR1 = PLYARG = Y
        jsr     FADD    ; FR0 = FR0 + FR1 = X/Y + Y
        ldx     #<FPHALF
        ldy     #>FPHALF
        jsr     FLD1R   ; FR1 = 0.5
        jsr     FMUL    ; FR0 = FR0 * FR1 = (X/Y + Y)/2

        ;loop back until iterations completed
        asl     tmp2
        bpl     iter_loop
        bmi     fp_return_interpreter

approx_compare_tab:
        .byte   $ff,$87,$66,$55,$36,$24,$14,$07,$02
.endproc

.proc   TOK_FP_LOG
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     LOG
        jmp     check_fp_err
.endproc

.proc   TOK_FP_LOG10
        sta     fp_tmp_a
        stx     fp_tmp_x
        jsr     LOG10
        jmp     check_fp_err
.endproc

        ; Computes FR0 ^ (AX)
.proc   TOK_FP_IPOW

        ; Store exponent
        sta     tmp1
        stx     tmp1+1

        ; If negative, get absolute value
        cpx     #$80
        bcc     ax_pos
        jsr     neg_AX
        ; Change mantisa to 1/X
        sta     tmp1
        stx     tmp1+1

        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FDIV

ax_pos:
        ; Skip all hi bits == 0
        ldy     #17
skip:
        dey
        beq     xit_1
        asl     tmp1
        rol     tmp1+1
        bcc     skip

        sty     tmp2
        ; Start with FR0 = X, store to PLYEVL
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FST0R
loop:
        ; Check exit
        dec     tmp2
        beq     xit

        ; Square, FR0 = x^2
        jsr     FMOVE
        jsr     FMUL
        bcs     error

        ; Check next bit
        asl     tmp1
        rol     tmp1+1
        bcc     loop

        ; Multiply, FR0 = FR0 * x
        ldx     #<PLYARG
        ldy     #>PLYARG
        jsr     FLD1R
        jsr     FMUL

        ; Continue loop
        bcc     loop
error:  lda     #3
        sta     IOERROR

xit_1:  jsr     FP_SET_1
xit:    jmp     pop_stack
.endproc

        ; Load 1.0 to FR0
.proc   FP_SET_1
        jsr     ZFR0
        lda     #$40
        sta     FR0
        lda     #$01
        sta     FR0+1
        rts
.endproc

        ; Returns a random FP number in the interval 0 <= X < 1
        ; Based on code from Altirra BASIC, (C) 2015 Avery Lee.
.proc   TOK_FP_RND
FPNORM=$DC00
        jsr     save_push_fr0

        lda     #$3F
        sta     FR0

        ; Get 5 digits
        ldx     #5
loop:
        ; Retries until we get a valid BCD number
get_bcd_digit:
        lda     RANDOM
        cmp     #$A0
        bcs     get_bcd_digit
        sta     FR0, x
        and     #$0F
        cmp     #$0A
        bcs     get_bcd_digit
        dex
        bne     loop

        ; Re-normalize random value (for X < 0.01) and exit
        jsr     FPNORM
        jmp     check_fp_err
.endproc

        ; SIN function, using a minimax 5 degree polynomial:
        ;    SIN(π/2 x) = ((((s[4] * x² + s[3]) * x² + s[2]) * x² + s[1]) * x² + s[0]) * x
        ;
        ; We use the polynomial:
        ;  S() = 1.57079633  -0.6459638821  0.0796901254  -0.00467416  0.00015158
        ;
        ; Maximum relative error 1.23e-08, this is better than the 6 degree
        ; poly in Atari BASIC, and 2 times worst than the 6 degree poly in
        ; Altirra BASIC.
        ;
        ; The polynomial was found with a minimax approximation in [-1:1], and
        ; then optimized by brute-force search to keep the total error bellow
        ; 1.23E-8 and ensuring that the approximation is always <= 1.0, so no
        ; adjustments are needed after calculation.
        ;
        ; As we expand the polynomial about SIN(π/2 x), we also don't need to
        ; take the modulus, we only divide the argument by π/2 (or 90 if we are
        ; in DEG mode), and this is exactly the first coefficient.
        ;
sin_coef:
        .byte $3E,$01,$51,$58,$00,$00
        .byte $BE,$46,$74,$16,$00,$00
        .byte $3F,$07,$96,$90,$12,$54
        .byte $BF,$64,$59,$63,$88,$21
pi1_2:
        .byte $40,$01,$57,$07,$96,$33
fp_90:
        .byte $40,$90,$00,$00,$00,$00
fp_180pi:
        .byte $40,$57,$29,$57,$79,$51

DEGFLAG_RAD = <pi1_2
DEGFLAG_DEG = <fp_90

        ; Evaluates ATAN polynomial
.proc   eval_atn_poly
ATNCOEF     = $DFAE
        lda     #11
        ldx     #<ATNCOEF
        ldy     #>ATNCOEF
.endproc        ; Fall through
        ; Evaluates a polynomial in *odd* powers of X, as:
        ;  z = x^2
        ;  y = x * P(z)
        ;
        ; On input, X:Y points to the coefficient table,
        ; A is the number of coefficients.
.proc   eval_poly_x2
        ; Store arguments
        pha
        txa
        pha
        tya
        pha

        ; Store X (=FR0) into FPSCR
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FST0R

        ; Compute X^2
        jsr     FMOVE
        jsr     FMUL

        ; Compute P(X^2) with our coefficients
        pla
        tay
        pla
        tax
        pla
        jsr     PLYEVL

        ; Compute X * P(X^2)
        ldx     #<FPSCR
        ldy     #>FPSCR
        jsr     FLD1R
        jmp     FMUL
.endproc

.proc   TOK_FP_SIN
        ldy     #2      ; Negative SIN: quadrant #2
        bit     FR0
        bmi     SINCOS
        ldy     #0      ; Positive SIN: quadrant #0
        .byte   $2C     ; Skip 2 bytes over next "LDY"
.endproc        ; Fall through

.proc   TOK_FP_COS
        ldy     #1      ; Positve/Negative COS: quadrant #1
.endproc        ; Fall trough

.proc   SINCOS
FPNORM=$DC00

        sty     tmp2    ; Store quadrant into tmp2

        ; Save integer stack
        sta     fp_tmp_a
        stx     fp_tmp_x

        ; Divide by 90° or PI/2
        .assert (>pi1_2) = (>fp_90) , error, "PI/2 and 90 fp constants in different pages!"
        ldx     DEGFLAG
        ldy     #>pi1_2
        jsr     FLD1R
        jsr     FDIV
        bcs     exit

        ; Get ABS of FR0
        lda     FR0
        and     #$7F
        sta     FR0
        cmp     #$40
        bcc     less_than_1     ; Small enough
        cmp     #$45
        bcs     exit            ; Too big
        tax

        lda     FR0-$40+1, x    ; Get "tens" digit
        and     #$10            ; if even/odd
        lsr
        lsr
        lsr                     ; get 0/2
        adc     tmp2            ; add to quadrant (C is clear here)
        adc     FR0-$40+1, x    ; and add the "ones" digit
        sta     tmp2

        ; Now, get fractional part by setting digits to 0
        lda     #0
:       sta     FR0-$40+1, x
        dex
        cpx     #$3F
        bne     :-

        jsr     FPNORM

less_than_1:

        ; Check if odd quadrant, compute FR0 = 1 - FR0
        lsr     tmp2
        bcc     no_mirror
        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FSUB
no_mirror:

        ; Compute FR0 * P(FR0^2)
        ldx     #<sin_coef
        ldy     #>sin_coef
        lda     #5
        jsr     eval_poly_x2

        ; Get sign into result, and clear carry
        asl     FR0
        beq     exit
        lsr     tmp2
        ror     FR0
exit:
        jmp     check_fp_err

.endproc


        ; Compute arc-tangent of FR0
        ; Uses table of coefficients on ROM, shorter code,
        ; reduced as:  ATN(x) = PI/2 - ATN(1/x)  if |x|>1.0
        ;
.proc TOK_FP_ATN
        ; Save integer stack
        sta     fp_tmp_a
        stx     fp_tmp_x

        lda     FR0
        asl
        ror     tmp2
        lsr
        sta     FR0
        asl
        bpl     small_arg

        ; Get 1/X
        jsr     FMOVE
        jsr     FP_SET_1
        jsr     FDIV
        jsr     eval_atn_poly
        ldx     #<pi1_2
        ldy     #>pi1_2
        jsr     FLD1R
        jsr     FSUB
        bcc     test_deg

small_arg:

        jsr     eval_atn_poly
test_deg:
        ; Convert to degrees if needed:
        lda     DEGFLAG
        cmp     #DEGFLAG_DEG
        bne     not_deg

        ldx     #<fp_180pi
        ldy     #>fp_180pi
        jsr     FLD1R
        jsr     FMUL
not_deg:
        ; Adds SIGN
        asl     FR0
        asl     tmp2
        ror     FR0
exit:
        jmp     check_fp_err

.endproc

.endif ; FASTBASIC_FP


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
        .word   TOK_LT, TOK_GT, TOK_NEQ, TOK_EQ
        ; Convert from int to bool
        .word   TOK_COMP_0
        ; Low level statements
        .word   TOK_POKE, TOK_DPOKE, TOK_MOVE, TOK_NMOVE, TOK_INC, TOK_DEC
        ; Graphic support statements
        .word   TOK_GRAPHICS, TOK_PLOT, TOK_DRAWTO, TOK_FILLTO
        ; Print statements
        .word   TOK_PRINT_NUM, TOK_PRINT_STR, TOK_PRINT_TAB, TOK_PRINT_EOL
        ; I/O
        .word   TOK_GETKEY, TOK_INPUT_STR, TOK_XIO, TOK_CLOSE, TOK_GET, TOK_PUT
        .word   TOK_BPUT, TOK_BGET
        ; Optimization - set's IO channel to 0
        .word   TOK_IOCHN0
        ; Jumps
        .word   TOK_JUMP, TOK_CJUMP, TOK_CALL, TOK_RET
        ; FOR loop support
        .word   TOK_FOR, TOK_FOR_START, TOK_FOR_NEXT, TOK_FOR_EXIT
        ; Arrays
        .word   TOK_DIM, TOK_USHL
        ; Strings
        .word   TOK_COPY_STR, TOK_VAL, TOK_CMP_STR
        ; Sound off - could be implemented as simple POKE expressions, but it's shorter this way
        .word   TOK_SOUND_OFF
        .word   TOK_PAUSE
        ; USR, calls ML routinr
        .word   TOK_USR_ADDR, TOK_USR_PARAM, TOK_USR_CALL

.ifdef FASTBASIC_FP
        ; Floating point computations
        .word   TOK_PRINT_FP
        .word   TOK_INT_FP, TOK_FP_VAL, TOK_FP_SGN, TOK_FP_ABS, TOK_FP_NEG, TOK_FLOAT
        .word   TOK_FP_DIV, TOK_FP_MUL, TOK_FP_SUB, TOK_FP_ADD, TOK_FP_STORE, TOK_FP_LOAD
        .word   TOK_FP_EXP, TOK_FP_EXP10, TOK_FP_LOG, TOK_FP_LOG10, TOK_FP_INT
        .word   TOK_FP_GEQ, TOK_FP_GT, TOK_FP_EQ
        .word   TOK_FP_IPOW, TOK_FP_RND, TOK_FP_SQRT, TOK_FP_SIN, TOK_FP_COS, TOK_FP_ATN
.endif ; FASTBASIC_FP

; vi:syntax=asm_ca65

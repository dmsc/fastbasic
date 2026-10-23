; Page-boundary regression test for token handlers.
;
; This file is appended to the compiler-generated assembly by fbtest for
; cross tests.  Each page starts with a JUMP back to the test at the end of
; that page.  The test's last immediate byte is at $xxFF.  A correct handler
; advances to the next page; a handler that misses the carry wraps to the
; current page start and loops until the test cycle limit is reached.
;
; The variable ID for A is taken from the generated assembly.

        .importzp       cptr, next_instruction
        .importzp       TOK_JUMP, TOK_BYTE, TOK_NUM
        .importzp       TOK_VAR_LOAD, TOK_VAR_STORE, TOK_VAR_ADDR
        .importzp       TOK_BYTE_PEEK, TOK_BYTE_PUT, TOK_NUM_POKE
        .importzp       TOK_CSTRING, TOK_EQ_BYTE, TOK_END
.ifdef FASTBASIC_FP
        .importzp       TOK_FLOAT
.endif

        .segment        "CODE"
        .export         PAGE_TEST
PAGE_TEST:
        lda     #<PAGE_START
        sta     cptr
        lda     #>PAGE_START
        sta     cptr+1
        jmp     next_instruction

        .segment        "ALIGNDATA"

        .align  256
PAGE_START:
        .byte   TOK_JUMP
        .word   test_byte
        .res    251, 0
test_byte:
        .byte   TOK_BYTE, 7

        .align  256
        .byte   TOK_JUMP
        .word   test_num
        .res    250, 0
test_num:
        .byte   TOK_NUM
        .word   300

        .align  256
        .byte   TOK_JUMP
        .word   test_var_load
        .res    251, 0
test_var_load:
        .byte   TOK_VAR_LOAD
        .byte   <((fb_var_A - __HEAP_RUN__) / 2)

        .align  256
        .byte   TOK_JUMP
        .word   test_var_store
        .res    251, 0
test_var_store:
        .byte   TOK_VAR_STORE
        .byte   <((fb_var_A - __HEAP_RUN__) / 2)

        .align  256
        .byte   TOK_JUMP
        .word   test_var_addr
        .res    251, 0
test_var_addr:
        .byte   TOK_VAR_ADDR
        .byte   <((fb_var_A - __HEAP_RUN__) / 2)

        .align  256
        .byte   TOK_JUMP
        .word   test_byte_peek
        .res    251, 0
test_byte_peek:
        .byte   TOK_BYTE_PEEK, 0

        .align  256
        .byte   TOK_JUMP
        .word   test_byte_put
        .res    251, 0
test_byte_put:
        .byte   TOK_BYTE_PUT, 'A'

        .align  256
        .byte   TOK_JUMP
        .word   test_num_poke
        .res    250, 0
test_num_poke:
        .byte   TOK_NUM_POKE
        .word   fb_var_A

        .align  256
        .byte   TOK_JUMP
        .word   test_cstring
        .res    249, 0
test_cstring:
        .byte   TOK_CSTRING, 2, 0, 0

        .align  256
        .byte   TOK_JUMP
        .word   test_eq_byte
        .res    251, 0
test_eq_byte:
        .byte   TOK_EQ_BYTE, 7

.ifdef FASTBASIC_FP
        .align  256
        .byte   TOK_JUMP
        .word   test_float
        .res    246, 0
test_float:
        .byte   TOK_FLOAT, 0, 0, 0, 0, 0, 0
.endif

        ; Correct continuation after the last test.
        .align  256
        .byte   TOK_BYTE_PUT, 'O'
        .byte   TOK_BYTE_PUT, 'K'
        .byte   TOK_BYTE_PUT, 155
        .byte   TOK_END

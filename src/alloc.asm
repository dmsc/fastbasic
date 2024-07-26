;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2024 Daniel Serpell
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


; Parser Memory functions
; -----------------------

; The memory areas are arranged as:
;  prog_ptr:    -> current program output buffer
;                 This has 0x100 free bytes at start of parsing a new line, to
;                 avoid calling "alloc_area" for each output byte.
;  prog_end
;
;  var_buf:     -> Variable name table, stores variable names and types,
;                  one byte for length, N bytes for the name and 1 byte for the
;                  type.
;  var_ptr
;
;  label_buf:   -> Label name table, stores PROC names and types. The format is
;                  the same as the variable name table, both are managed by the
;                  same functions.
;  label_ptr
;
;  laddr_buf:   -> Label address table, stores address of PROC and address
;                  of EXEC arguments, to be patched when PROC address is known.
;  laddr_ptr
;
;  mem_end:     -> End of used memory.
;
; Because areas are always contiguous, we have:
;    var_buf   == prog_end
;    label_buf == var_ptr
;    laddr_buf == label_ptr
;    mem_end   == laddr_ptr
;
; So, we store only 5 pointers.
;
; To allocate more memory for any area, we call "alloc_area_8" with A == amount
; of memory to allocate, X == end pointer to area to expand.
;

        .export         alloc_prog, alloc_laddr
        .export         parser_alloc_init, alloc_area_8

        .importzp       prog_ptr, laddr_ptr, mem_end, var_buf, tmp1, end_ptr
        .import         move_dwn, err_nomem
        .importzp       move_dwn_src, move_dwn_dst

.zeropage
save_x:  .res 1

mem_start = prog_ptr
prog_end  = var_buf

        ; Top of available memory
MEMTOP=         $2E5
        ; Allocation size
alloc_size=     tmp1

;----------------------------------------------------------
; Following routines are part of the parser/editor
        .code

        ; Increase program memory area by "opos" (size in bytes)
.proc alloc_prog
        .importzp       opos
        lda     opos
        ldx     #prog_ptr - mem_start
        .assert prog_ptr = mem_start, error, "Prog Ptr should be at mem start"
        stx     opos
        .byte   $2C   ; Skip 2 bytes over next "LDX"
.endproc        ; Fall through

.proc   alloc_laddr
        ldx     #laddr_ptr - mem_start
.endproc        ; Fall through

        ; Increase program memory area X by A (size in bytes)
        ; Returns with carry set on errors.
.proc alloc_area_8
        sta     alloc_size
        clc
        adc     mem_end
        tay

        lda     #0
        adc     mem_end+1

        cpy     MEMTOP
        sbc     MEMTOP+1
        bcc     mem_ok
        jmp     err_nomem
mem_ok:
        ; Move memory up.
        ;  X          : index to pointer to move from
        ;  alloc_size : amount to move up
        stx     save_x

        ;clc    ; C cleared from BCS above

        ;       Setup pointers
        lda     mem_start, x
        sta     move_dwn_src
        adc     alloc_size
        sta     move_dwn_dst
        lda     mem_start+1, x
        sta     move_dwn_src+1
        adc     #0
        sta     move_dwn_dst+1

        ; Get LEN into AX
        lda     mem_end
        sec
        sbc     mem_start, x
        pha
        lda     mem_end+1
        sbc     mem_start+1, x
        tax
        pla
        jsr     move_dwn

        ; Adjust pointers
        ldx     save_x

        ; Increase all pointers from "Y" to the last by AX
loop:   clc
        lda     mem_start, x
        adc     alloc_size
        sta     mem_start, x
        bcc     skip
        inc     mem_start + 1, x
skip:
        inx
        inx
        cpx     #mem_end - mem_start + 2
        bne     loop
        rts
.endproc

;----------------------------------------------------------
; Parser initialization here:
.proc   parser_alloc_init
        ; Init all pointers to AY, starting from "end_ptr"
        ldx     #(mem_end-end_ptr)
        ; Adds 256 bytes as program buffer
        iny
loop:
        sta     end_ptr, x
        sty     end_ptr+1, x
        dex
        dex
        bpl     loop
        ; Restore correct value of program start and end of source
        dec     prog_ptr+1
        dec     end_ptr+1
        rts
.endproc

; vi:syntax=asm_ca65

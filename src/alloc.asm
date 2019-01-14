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
;  laddr_buf:   -> Label address table, stores address of PROC of address
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

        .importzp       prog_ptr, laddr_ptr, mem_end, var_buf

        ; From runtime.asm
        .import         move_dwn_src, move_dwn_dst, move_dwn
        .importzp       tmp1
        ; From interpreter.asm
        .importzp       var_count


mem_start = prog_ptr
prog_end  = var_buf

        ; Top of available memory
MEMTOP=         $2E5
        ; Allocation size
alloc_size=     tmp1

;----------------------------------------------------------
; Following routines are part of the parser/editor
        .code

.proc   alloc_laddr
        ldx     #laddr_ptr - mem_start
.endproc        ; Fall through

        ; Increase program memory area X by A (size in bytes)
.proc alloc_area_8
        sta     alloc_size
        clc
        adc     mem_end
        tay

        lda     #0
        sta     alloc_size+1
        adc     mem_end+1

        cpy     MEMTOP
        sbc     MEMTOP+1
        bcs     rts_1

        ; Move memory up.
        ;  X          : index to pointer to move from
        ;  alloc_size : amount to move up
        stx     save_x+1

        ;       Setup pointers
        lda     mem_start, x
        sta     move_dwn_src
        clc
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
save_x: ldx     #0

.endproc        ; Fall through

        ; Increase all pointers from "Y" to the last by AX
.proc   add_pointers
loop:   clc
        lda     mem_start, x
        adc     alloc_size
        sta     mem_start, x
        inx
        lda     mem_start, x
        adc     alloc_size+1
        sta     mem_start, x
        inx
        cpx     #mem_end - mem_start + 2
        bne     loop
        clc
::rts_1:
        rts
.endproc


;----------------------------------------------------------
; Parser initialization here:
.proc   parser_alloc_init
        ; Init all pointers to AY
        ldx     #(mem_end-mem_start)
loop:
        sta     mem_start, x
        sty     mem_start+1, x
        dex
        dex
        bpl     loop
        ; Adds 256 bytes as program buffer
        ldx     #prog_end - mem_start
        ldy     #0
        sty     alloc_size
        iny
        sty     alloc_size+1
        bne     add_pointers
.endproc

        ; Increase program memory area by A (size in bytes)
.proc alloc_prog
        .importzp       opos
        lda     opos
        ; Move from "prog_end", up by "alloc_size"
        ldx     #prog_end - mem_start
        jsr     alloc_area_8
        ; Special case - we need to adjust prog_ptr, but we
        ; don't move that areas as it has the current parsed line.
        lda     prog_ptr
        clc
        adc     alloc_size
        sta     prog_ptr
        bcc     :+
        inc     prog_ptr+1
:       rts
.endproc

; vi:syntax=asm_ca65

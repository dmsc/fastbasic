;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017,2018 Daniel Serpell
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


; Memory functions
; ----------------

; The memory areas are arranged as:
;  prog_ptr:    -> current program output pos
;               Buffer zone (at least 0x100 free bytes)
;  array_buf:   STRING/ARRAY AREA
;  array_ptr:   -> next available pos
;  var_buf:     VARIABLE TABLE AREA (during parsing) and VARIABLE VALUE AREA
;               (during interpreting)
;  var_ptr:     -> next available pos
;  top_mem:     TOP OF MEMORY
;
        .export         alloc_prog, alloc_laddr
        .export         parser_alloc_init, alloc_area_8

        .importzp       prog_ptr, laddr_ptr, mem_end, array_ptr, var_buf

        ; From runtime.asm
        .import         move_dwn_src, move_dwn_dst, move_dwn
        .importzp       tmp1
        ; From interpreter.asm
        .importzp       var_count


mem_start = prog_ptr
prog_end  = var_buf
array_end = array_ptr
laddr_end = laddr_ptr

        ; Top of available memory
MEMTOP=         $2E5
        ; Allocation size
alloc_size=     tmp1

;----------------------------------------------------------
; Following routines are part of the parser/editor
        .code

.proc   alloc_laddr
        ldx     #laddr_end - mem_start
.endproc        ; Fall through

        ; Increase program memory area X by A (size in bytes)
alloc_area_8:
        ldy     #0
        ; Increase program memory area X by AY (size in bytes)
.proc   alloc_area
        sty     alloc_size+1
skip_y: sta     alloc_size

        clc
        adc     mem_end
        tay
        lda     alloc_size+1
        adc     mem_end+1
        cpy     MEMTOP
        sbc     MEMTOP+1
        bcs     rts_1

        ; Move memory up by "alloc_size"
        stx     save_x+1
        jsr     move_mem_up
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

        ; Move memory up.
        ;  Y          : index to pointer to move from
        ;  alloc_size : amount to move up
        ;
.proc   move_mem_up
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
        jmp     move_dwn
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
        jmp     add_pointers
.endproc

        ; Increase program memory area by A (size in bytes)
.proc alloc_prog
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

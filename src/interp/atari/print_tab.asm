;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2022 Daniel Serpell
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


; Print a tabulation (comma separator in print)
; ---------------------------------------------

        .import         putc, stack_l, print_str_tmp1
        .importzp       sptr, next_instruction, tmp1, tmp2

        .include "target.inc"

        .segment        "RUNTIME"

.proc   do_tab          ; Print spaces to advance:
        clc
        sbc     COLCRS
        bcs     ok
rep:
        adc     tmp2
        bcc     rep

ok:
        tay
:       lda     #$20
        jsr     putc
        dey
        bpl     :-
        rts
.endproc

.proc   EXE_PRINT_TAB   ; PRINT TAB up to column N
        sta     tmp2
        jsr     do_tab
        jmp     next_instruction
.endproc

.proc   EXE_PRINT_RTAB  ; PRINT RTAB, next string aligned to column N
        sta     tmp1    ; Save AX (string address)
        stx     tmp1+1

        lda     stack_l, y      ; Get TAB position
        sta     tmp2

        ldy     #0
        sec
        sbc     (tmp1), y       ; subtract string length

        jsr     do_tab

        inc     sptr
        jmp     print_str_tmp1  ; Print string in tmp1
.endproc

        .include "deftok.inc"
        deftoken "PRINT_TAB"
        deftoken "PRINT_RTAB"

; vi:syntax=asm_ca65

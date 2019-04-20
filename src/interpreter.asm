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


; The opcode interpreter
; ----------------------

        .exportzp       interpreter_cptr, sptr, cptr
        .exportzp       next_ins_incsp, next_instruction

        ; From jumptab.asm
        .import         __JUMPTAB_RUN__

        .include "atari.inc"

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
jump:   jmp     (__JUMPTAB_RUN__);5 = 27 cycles per call

.endproc

sptr                    =       interpreter::ldsptr+1
cptr                    =       interpreter::cload+1
next_instruction        =       interpreter::nxtins
next_ins_incsp          =       interpreter::nxt_incsp
interpreter_cptr        =       cptr

; vi:syntax=asm_ca65

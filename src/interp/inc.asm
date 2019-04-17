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


; Increment a memory location
; ---------------------------

        .importzp       saddr

        .include "toks.inc"

EXE_INCVAR:     ; VAR = VAR + 1
        get_var
.ifdef NO_SMCODE
        sta     saddr
        stx     saddr+1
.endif
        ; NOTE: Here, we have the address in SADDR and in the
        ;       AX register, but using Self-Modifying code it
        ;       is smaller and faster using AX.
.proc   EXE_INC ; *(AX) = *(AX) + 1
.ifdef NO_SMCODE
        ; This is too long, it misses INC A
        ldy     #0
        lda     (saddr),y
        clc
        adc     #1
        sta     (saddr),y
        bcc     :+              ; Longer, but much faster
        iny
        lda     (saddr),y
        adc     #0
        sta     (saddr),y
:
.else
        stx     loadH+2
        stx     loadL+2
        tax
loadL:  inc     $FF00, x
        bne     :+
loadH:  inc     $FF01, x
:
.endif
        sub_exit
.endproc

        deftoken "INC"
        deftoken "INCVAR"

; vi:syntax=asm_ca65

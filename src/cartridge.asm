;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2025 Daniel Serpell
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


; Cartridge capable interpreter
; -----------------------------

        ; Export to force include from linker
        .export         _FASTBASIC_CART_: absolute = 1
        ; From standalone.asm
        .import         start
        ; Linker vars
        .import         __CARTFLAGS__
        .import         __BSS_RUN__, __BSS_SIZE__
        .import         __INTERP_LOAD__, __INTERP_RUN__, __INTERP_SIZE__
        .import         __DATA_LOAD__, __DATA_RUN__, __DATA_SIZE__
        ; Move
        .import         move_dwn
        .importzp       move_source, move_dest

        .code
        ; Forces an error if compilation options allows self-modifying-code:
.ifndef NO_SMCODE
        .assert (start=0), error, "You must compile library with '--asm-define NO_SMCODE' to make cartridges."
.endif

cartridge_start:
        ; Copies ROM to RAM

        ; Copy ZP interpreter
        ldx     #<__INTERP_SIZE__
copy_interpreter:
        lda     __INTERP_LOAD__, x
        sta     <__INTERP_RUN__, x
        dex
        bpl     copy_interpreter

        .assert (__INTERP_RUN__ < $100), error, "Interpreter must be in ZP"
        .assert (__INTERP_SIZE__ < $80), error, "Interpreter must be less than 128 bytes"

        ; Copy the DATA segment
        lda     #<__DATA_LOAD__
        ldx     #>__DATA_LOAD__
        sta     move_source
        stx     move_source+1
        lda     #<__DATA_RUN__
        ldx     #>__DATA_RUN__
        sta     move_dest
        stx     move_dest+1
        lda     #<__DATA_SIZE__
        ldx     #>__DATA_SIZE__
        jsr     move_dwn

        jmp     start

        ; INIT not used
cartridge_init:
        rts

        ; Include the cartridge header
        .segment        "CARTHDR"

        .word   cartridge_start
        .byte   0
        .byte   <__CARTFLAGS__
        .word   cartridge_init

; vi:syntax=asm_ca65

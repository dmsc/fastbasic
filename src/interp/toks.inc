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

; Support macros for writing interpreter subroutines
; --------------------------------------------------


    ; Only used in the interpreter
    .ifndef FASTBASIC_ASM

        ; Include TOKEN definitions
        .include "../deftok.inc"

        .importzp       next_instruction, next_ins_incsp
        .macro use_cptr
            .importzp   cptr
        .endmacro

        .macro use_stack
            .importzp   sptr
            .import     stack_l, stack_h
        .endmacro

        .macro  sub_exit
            jmp next_instruction
        .endmacro

        .macro  sub_exit_incsp
            jmp next_ins_incsp
        .endmacro

        .macro  sub_exit_incsp_2
            .import     next_ins_incsp_2
            jmp next_ins_incsp_2
        .endmacro

        .macro  get_var
            .import     get_op_var
            jsr get_op_var
        .endmacro

    ; Only used in the native code compiler
    .else ; FASTBASIC_ASM

        .macro use_cptr
            .error "This token is interpreter only!"
        .endmacro

        .macro  get_var
            .error "Can't use get_var in native compiler!"
        .endmacro

        .macro use_stack
            .importzp   sptr
            .import     stack_l, stack_h
            ldy         sptr
        .endmacro

        .macro  deftoken arg
            .export         .ident (.concat ("EXE_", arg) )
        .endmacro

        .macro  sub_exit
            rts
        .endmacro

        .macro  sub_exit_incsp
            .importzp   sptr
            inc sptr
            rts
        .endmacro

        .macro  sub_exit_incsp_2
            .importzp   sptr
            inc sptr
            inc sptr
            rts
        .endmacro

    .endif ; FASTBASIC_ASM


    .segment        "RUNTIME"

; vi:syntax=asm_ca65

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

; Compiled header written from the IDE
; ------------------------------------

        .export BYTECODE_ADDR
        .exportzp ZP_INTERP_LOAD, ZP_INTERP_SIZE

        .include "atari.inc"

        ; Linker vars
        .import __INTERP_START__, __INTERP_SIZE__
        .import __JUMPTAB_RUN__, __RUNTIME_RUN__, __RUNTIME_SIZE__
        .import __DATA_SIZE__

        .import bytecode_start, start

        ; Interpreter locations exported as ZP to the BASIC sources
ZP_INTERP_LOAD = < __INTERP_START__
ZP_INTERP_SIZE = < __INTERP_SIZE__

        ; Start of relocated bytecode
BYTECODE_ADDR=  __RUNTIME_RUN__ + __RUNTIME_SIZE__ + __DATA_SIZE__

        ; Ensure that the Editor or Command Line bytecode starts at same address that
        ; compiled bytecode, so we have only one initialization
        .assert	BYTECODE_ADDR = bytecode_start, error, "Bytecode location differ in menu!"

        ; This is the header for the compiled binaries, included
        ; here to allow saving the resulting file.
        .export COMP_HEAD_1
COMP_HEAD_1:
        ; Atari binary header
        .byte   255, 255
        ; Chunk 1: Run address at "start"
        .word   RUNAD
        .word   RUNAD+1
        .word   start
        ; Chunk 2: interpreter at page 0
        .word   __INTERP_START__
        .word   __INTERP_START__ + __INTERP_SIZE__- 1

        .segment "PREHEAD"
        .export COMP_HEAD_2
COMP_HEAD_2:
        .word   __JUMPTAB_RUN__
        .word   0

        .code

        ; Number of bytes to write in RUNTIME + JUMPTAB segments
        .export COMP_RT_SIZE
COMP_RT_SIZE = __RUNTIME_RUN__ + __RUNTIME_SIZE__ + __DATA_SIZE__ - __JUMPTAB_RUN__ + 4

; vi:syntax=asm_ca65

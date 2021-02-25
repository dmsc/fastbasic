;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
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

        .export start
        .export heap_start
        .export BYTECODE_ADDR

        .exportzp ZP_INTERP_LOAD, ZP_INTERP_SIZE

        .include "atari.inc"

        ; Linker vars
        .import __BSS_RUN__, __BSS_SIZE__
        .import __INTERP_START__, __INTERP_SIZE__
        .import __JUMPTAB_RUN__, __RUNTIME_RUN__, __RUNTIME_SIZE__
        .import __RT_DATA_SIZE__

        .import interpreter_run, bytecode_start

        ; Interpreter locations exported as ZP to the BASIC sources
ZP_INTERP_LOAD = < __INTERP_START__
ZP_INTERP_SIZE = < __INTERP_SIZE__

        ; Start of HEAP - aligned to 256 bytes
heap_start=    ( __BSS_RUN__+__BSS_SIZE__ + 255 ) & $FF00

        ; Start of relocated bytecode
BYTECODE_ADDR=  __RUNTIME_RUN__ + __RUNTIME_SIZE__ + __RT_DATA_SIZE__

        ; Ensure that the Editor or Command Line bytecode starts at same address that
        ; compiled bytecode, so we have only one initialization
        .assert	BYTECODE_ADDR = bytecode_start, error, "Bytecode location differ in menu!"

        ; This is the header for the compiled binaries, included
        ; here to allow saving the resulting file.
        .export COMP_HEAD_1
COMP_HEAD_1:
        ; Atari binary header
        .byte   255, 255
        ; Chunk 1: Run address at "compiled_start"
        .word   RUNAD
        .word   RUNAD+1
        .word   compiled_start
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
COMP_RT_SIZE = __RUNTIME_RUN__ + __RUNTIME_SIZE__ + __RT_DATA_SIZE__ - __JUMPTAB_RUN__ + 4

        ; This is the runtime startup code, loads the editor.
        ; Note that this code is patched before writing to a file
        ; and copied into the resulting executables.
        .segment        "RUNTIME"
start:
compiled_start:
        lda     #<BYTECODE_ADDR
        ldx     #>BYTECODE_ADDR

        jsr     interpreter_run
        jmp     (DOSVEC)

; vi:syntax=asm_ca65

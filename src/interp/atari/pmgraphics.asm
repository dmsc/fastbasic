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


; PMGRAPHICS: P/M graphic setup
; -----------------------------

        .export         PMGBASE, PMGMODE
        .import         err_nomem
        .importzp       array_ptr, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_PMGRAPHICS
        and     #3      ; only two modes
        tax             ; Disable if 0
        beq     disable_pm

        ; Note: if A == 3, mask_tab will point to a 0,
        ; so we will have a MEMORY ERROR.
        ;
        ldy     #3              ; Load value for GRACTL
        lda     mask_tab-1,x    ; Get address mask
        and     MEMTOP+1
        clc                     ; Subtract to get P/M base
        adc     mask_tab-1,x
        cmp     array_ptr+1
        bcs     mem_ok
        jmp     err_nomem

disable_pm:
        tay     ; Store 0 in GRACTL
mem_ok:
        sta     pmgbase
        sta     PMBASE

        lda     SDMCTL
        and     #$e3
        ora     pmg_dmactl_tab,x
        sta     SDMCTL
        sty     GRACTL
        tya             ; bit 1 already set
        ora     GPRIOR
        and     #$c1
        sta     GPRIOR

        ; Note: when X = 0, mode is written an invalid
        ; value, but it won't matter as MODE is not used
        ; when P/M graphics are disabled.
        ldy     pmgmode_tab-1,x
        sty     pmgmode

        ; Reset GTIA registers (P/M position, sizes and hit)
        ldy     #17
        lda     #0
:       sta     HPOSP0, y
        dey
        bpl     :-

        jmp     next_instruction
.endproc

mask_tab:
        .byte       $f8,$fc     ; next is 0 from table bellow
pmg_dmactl_tab:
        .byte   $00,$1c,$0c
pmgmode_tab:
        .byte       $80,$40

        .bss
pmgbase:
        .byte 0
pmgmode:
        .byte 0

PMGBASE = pmgbase
PMGMODE = pmgmode

        .include "deftok.inc"
        deftoken "PMGRAPHICS"

; vi:syntax=asm_ca65

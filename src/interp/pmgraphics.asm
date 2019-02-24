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


; PMGRAPHICS: P/M graphic setup
; -----------------------------

        .export         PMGBASE, PMGMODE
        .import         err_nomem
        .importzp       array_ptr, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_PMGRAPHICS
        tax             ; Disable if 0
        beq     disable_pm
        and     #1      ; only two modes
        tax
        ; TODO: copied from AtBasic - optimize
        ldy     pmgmode_tab,x   ; Get mode
        lda     mask_tab,x      ; Get address mask
        and     MEMTOP+1
        clc                     ; Subtract to get P/M base
        adc     mask_tab,x
        cmp     array_ptr+1
        bcs     mem_ok
        jmp     err_nomem

disable_pm:
        txa     ; Set A,X and Y to 0, used to write register values
        tay
        clc
mem_ok:
        sta     pmgbase
        sta     PMBASE
        sty     pmgmode

        lda     SDMCTL
        and     #$e3
        bcc     skip_pmenable
        ora     pmg_dmactl_tab,x
        ldy     #3
skip_pmenable:
        sta     SDMCTL
        sty     GRACTL
        tya             ; bit 1 already set
        ora     GPRIOR
        and     #$c1
        sta     GPRIOR

        ; Reset GTIA registers (P/M position, sizes and hit)
        ldy     #17
        lda     #0
:       sta     HPOSP0, y
        dey
        bpl     :-

        jmp     next_instruction
.endproc

pmgbase:
        .byte 0
pmgmode:
        .byte 0
mask_tab:
        .byte   $fc,$f8
pmg_dmactl_tab:
        .byte   $0c,$1c
pmgmode_tab:
        .byte   $40,$80

PMGBASE = pmgbase
PMGMODE = pmgmode

        .include "../deftok.inc"
        deftoken "PMGRAPHICS"

; vi:syntax=asm_ca65

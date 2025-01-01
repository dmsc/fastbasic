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


; Graphics commands and I/O:
; GRAPHICS; DRAWTO (and FILLTO), GET and CLOSE
; --------------------------------------------

        .export         CIOV_CMD_A, CIOV_CMD, CIOV_IOERR
        .import         IOCHN_16
        .importzp       COLOR, IOCHN, IOERROR, next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_GRAPHICS    ; OPEN #6,12,MODE,"S:"
        ldx     #$60
        sta     ICAX2, x; Store BASIC mode into AUX2
        and     #$F0
        eor     #$1C    ; and flags into AUX1
        sta     ICAX1, x
        pha
        pha
        lda     #>device_s
        pha
        lda     #<device_s
        ldy     #OPEN
.endproc

CIOV_CMD_A:
        sta     ICBAL, x        ; Address
        pla
        sta     ICBAH, x
        pla                     ; Length
CIOV_CMD_L:
        sta     ICBLH, x
        pla
        sta     ICBLL, x
        tya                     ; Command
        ; Calls CIO with given command, stores I/O error and pops stack
CIOV_CMD:
        sta     ICCOM, x
        ; Calls CIOV, stores I/O error and pops stack
        jsr     CIOV
        ldx     #0      ; Needed for TOK_GET
CIOV_IOERR:
        sty     IOERROR
        jmp     next_instruction

device_s: .byte "S:", $9B

EXE_CLOSE:
        jsr     IOCHN_16
        lda     #CLOSE
        bne     CIOV_CMD

.proc   EXE_DRAWTO      ; CIO COMMAND in A
        ldy     COLOR
        sty     ATACHR
        ldx     #$60    ; IOCB #6
        bne     CIOV_CMD
.endproc

.proc   EXE_GET
        ldx     IOCHN
        lda     #0      ; Length = 0
        pha
        ldy     #GETCHR
        bne     CIOV_CMD_L
.endproc

        .include "deftok.inc"
        deftoken "CLOSE"
        deftoken "DRAWTO"
        deftoken "GET"
        deftoken "GRAPHICS"

; vi:syntax=asm_ca65

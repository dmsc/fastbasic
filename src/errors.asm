;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017 Daniel Serpell
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

; Parser error messages
; ---------------------

        .export         print_error

        ; From runtime.asm
        .import         putc


; Prints an error message
.proc   print_error
        tax
        ldy     #$FF
nxt:    iny
        lda     error_msg, y
        bpl     nxt
        dex
        bpl     nxt
        ; And print
ploop:  iny
        lda     error_msg, y
        pha
        and     #$7F
        jsr     putc
        pla
        bpl     ploop
        sec
        rts
.endproc

        ; Keep in line with error definitions
        .data
error_msg:
        err_count .set -1
.macro  def_error name, msg
        err_count .set err_count + 1
        ::name    = err_count
        .exportzp name
        .repeat .strlen(msg)-1, I
                .byte   .strat(msg, I)
        .endrepeat
        .byte   .strat(msg, .strlen(msg)-1) ^ $80
.endmacro
        .byte   $80
        def_error ERR_LOOP,     "bad loop error"
        def_error ERR_VAR,      "var not defined"
        def_error ERR_PARSE,    "parse error"
        def_error ERR_NO_ELOOP, "no end loop/proc/if"
        def_error ERR_LABEL,    "undef label"

.if (* - error_msg) > 255
        .error  "Error, too many error messages"
.endif
        .code

; vi:syntax=asm_ca65

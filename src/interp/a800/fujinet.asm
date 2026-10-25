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
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
;
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)

; FujiNet support
; ---------------

        .include        "atari.inc"

        .import         get_pointers, get_str_eol
        .importzp       move_dest, saddr

        .export         FUJI_NOPEN, FUJI_NOPEN_CONST, FUJI_COMMON

        .segment        "RUNTIME"

; Open a network connection.  SADDR points to the URL string variable
; slot.  get_pointers allocates the string if needed, so an empty
; variable works too.
.proc   FUJI_NOPEN
        jsr     get_pointers

        ldy     #0
        lda     (move_dest),y
        tay
        iny
        bne     lenok
        ; The string allocation has no byte after 255 characters.
        ; Truncate the last character so the URL is still terminated.
        ldy     #255
lenok:
        lda     #0
        sta     (move_dest),y

        ldx     move_dest
        ldy     move_dest+1
        inx
        bne     FUJI_SETBUF
        iny
.endproc        ; Fall through

.proc   FUJI_SETBUF
        stx     $304
        sty     $305
.endproc        ; Fall through

; Common FujiNet SIO call.  All FujiNet statements use device $71 and
; the same timeout.
.proc   FUJI_COMMON
        lda     #$71
        sta     $300
        lda     #$1F
        sta     $306
        jmp     SIOV
.endproc

; Constant strings are copied to LBUFF with an ATASCII EOL appended.
.proc   FUJI_NOPEN_CONST
        jsr     get_str_eol
        ldx     #<LBUFF
        ldy     #>LBUFF
        bne     FUJI_SETBUF
.endproc

; vi:syntax=asm_ca65

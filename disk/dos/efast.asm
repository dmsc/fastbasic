;
; Fast E: accelerator
; -------------------
;
; Written by DMSC, loosely based on HYP.COM by Doug Wokoun and John Harris.
;
        .global start, __AUTOSTART__

        .include "atari.inc"

        .zeropage
pntr:    .res 2

        .code
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; Installer: relocates handler to lowest memory available.
        ;
start:
        ; Search E: handler in HATABS
        ldy     #<HATABS+1-3
        lda     #'E'
search_e:
        iny
        iny
        iny
        cmp     -1+(HATABS & $FF00),y
        bne     search_e

        ; Check high-part of HATABS address
        lda     1+(HATABS & $FF00),y
        cmp     #>$C000
        bcs     install_ok

        ; Don't install over RAM based handler
        lda     #<error_msg
        jmp     print_msg

install_ok:
        ; copy EDITOR handler to new HATABS
        ldx     #$0F
copy_e: lda     EDITRV,x
        sta     handler_hatab,x
        dex
        bpl     copy_e

        ; Patch E: HATABS position in out handler
        sty     hatabs_l+3
        iny
        sty     hatabs_h+3

        ; Also patch real DOSINI and EDITOR PUT
        lda     DOSINI
        sta     handler_jdos+1
        lda     DOSINI+1
        sta     handler_jdos+2
        ldy     EDITRV+6
        ldx     EDITRV+7
        iny
        bne     :+
        inx
:       sty     jhand+1
        stx     jhand+2

        ; Patch new HATABS, stored in current MEMLO
        lda     MEMLO
        ldx     MEMLO+1
        sta     hatabs_l+1
        stx     hatabs_h+1
        sta     pntr
        stx     pntr+1

        ; And store our new PUT
        ; (note, C is set here, so adds 1 less)
        adc     #(handler_put-1 - handler_hatab) - 1
        bcc     :+
        inx
:       sta     handler_hatab+6
        stx     handler_hatab+7

        ; Store new DOSINI handler address
        sec
        adc     #(handler_jdos - handler_put)
        bcc     :+
        inx
:       sta     DOSINI
        stx     DOSINI+1

        ; And address of new MEMLO
        clc
        adc     #(handler_end - handler_jdos)
        sta     sMEMLOL+1

        ; If we adjusted X it means that in the reload handler
        ; we also need to increment X, so keeps the "INX" in the code
        bcs     :+
        cpx     pntr+1
        bne     :+
        ; We did not increment X, replace the INX with a NOP.
        lda     #234    ; NOP
        sta     sMEMLOH
:

        ; Copy our handler code to new position
copy_handler:
        ldy     #(handler_end - handler_put + 15)
cloop:  lda     handler_hatab,y
        sta     (pntr),y
        dey
        cpy     #$FF
        bne     cloop

        ; Store new MEMLO / HATAB
        jsr     load_hatab

        ; Reopen E:
        ldy     #CLOSE
        jsr     call_cio
        lda     #OPNIN | OPNOT
        sta     ICAX1
        ldy     #OPEN
        lda     #<dev_e
        jsr     call_cio_str
        ; Show message and end
        lda     #<install_msg

print_msg:
        ldy     #PUTREC
call_cio_str:
        ldx     #>error_msg
        sta     ICBAL
        stx     ICBAH
call_cio:
        sty     ICCOM
        ldx     #$01
        stx     ICBLH
        dex
        jmp     CIOV

        .assert (>install_msg) = (>error_msg), error, "messages must be in the same page"
        .assert (>install_msg) = (>dev_e), error, "e: must be in the same page"

install_msg:
        .byte   "E:Fast Installed", $9B
error_msg:
        .byte   "Can't install", $FD, $9B

dev_e:
        .byte   "E:", $9B

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ;       Installed handler
        ;

        ; File HEADER
        .segment "HANDHDR"
        .word   handler_put
        .word   handler_end - 1
        .segment "HANDLER"

        ; Handler device table
handler_hatab = handler_put - 16

        ; Handler PUT function
handler_put:
        ; Don't handle wrap at last column!
        ldx     COLCRS
        cpx     RMARGN
        bcs     jhand

        ; And don't handle in graphics modes
        ldx     DINDEX
        bne     jhand

        ; Check for control character:
        ;  $1B, $1C, $1D, $1E, $1F, $7D, $7E, $7F
        ;  $9B, $9C, $9D, $9E, $9F, $FD, $FE, $FF
        ;
        ; To ignore high bit, store in X the shifted character
        asl
        tay
        ; Restore full value in A
        ror

        cpy     #2*ATCLR ; chars >= $7D are special chars
        bcs     jhand
        cpy     #$C0     ; chars >= $60 don't need conversion
        bcs     conv_ok
        cpy     #$40     ; chars >= $20 needs -$20 (upper case and numbers)
        bcs     normal_char
        cpy     #2*ATESC ; chars <= $1B needs +$40 (control chars)
        bcc     ctrl_char

        ; Special character jump to old handler
jhand:  jmp     $FFFF

        ; Convert ATASCII to screen codes
ctrl_char:
        adc     #$61    ; Chars from $00 to $1F, add $40 (+$21, subtracted bellow)
normal_char:
        sbc     #$20    ; Chars from $20 to $5F, subtract $20
conv_ok:

        ; Check break and stop on START/STOP flag
wait_stop:
        ldy     BRKKEY
        beq     jhand
        ldy     SSFLAG
        bne     wait_stop
        ; From here onwards, Y = 0 always!

        ; Check if we need to recalculate cursor position
        cpx     OLDCOL
        bne     calc_adr
        ldx     ROWCRS
        cpx     OLDROW
        beq     skip_adr

        ; Clear current cursor position and calculate new cursor address
calc_adr:
        tax             ; Save character in X

        lda     OLDCHR  ; Clear cursor
        sta     (OLDADR),y

        sty     OLDADR+1        ; set OLDADR+1 to 0

        lda     ROWCRS  ; max =  23
        sta     OLDROW

        asl             ; max = 46
        asl             ; max = 92
        adc     ROWCRS  ; max = 115
        asl             ; max = 230
        asl             ; max = 460
        rol     OLDADR+1
        asl             ; max = 920
        rol     OLDADR+1

        adc     COLCRS  ; max = 959
        bcc     :+
        inc     OLDADR+1
        clc
:
        adc     SAVMSC
        sta     OLDADR
        lda     OLDADR+1
        adc     SAVMSC+1
        sta     OLDADR+1

        txa

skip_adr:
        ; Store new character
        sta     (OLDADR),y
        ; Go to next column
        inc     OLDADR
        bne     :+
        inc     OLDADR+1
:
        ; Read new character under cursor
        lda     (OLDADR),y
        sta     OLDCHR

        ldx     CRSINH
        bne     no_cursor
        ; Draw cursor
        eor     #$80
        sta     (OLDADR),y
no_cursor:

        ; Update column
        ldx     COLCRS
        inx
        stx     COLCRS
        stx     OLDCOL
        inc     LOGCOL

        ; Reset ESC flag
        sty     ESCFLG
        ; Return with Y = 1 (no error)
        iny
        rts

; Calls original DOSINI, adjust MEMLO and reinstall E: handler
handler_jdos:
        jsr     $FFFF

        ; Load HATABS value:
load_hatab:

hatabs_l:
        lda     #$00
        sta     HATABS+1
hatabs_h:
        ldx     #$00
        stx     HATABS+2

        ; Loads MEMLO value
sMEMLOL:lda     #$00
sMEMLOH:inx     ; This is replaced by a NOP if possible

        sta     MEMLO
        stx     MEMLO+1
        rts

; End of resident handler
handler_end:

; vi:syntax=asm_ca65

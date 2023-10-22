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
        sta     pntr
        stx     pntr+1

        ; Store new DOSINI handler address
        sta     DOSINI
        stx     DOSINI+1

        ; Address of new PUT is at start of handler
        ; (note, C is set here, so adds 1 less)
        adc     #(handler_put - 1 - handler_start - 1)
        bcc     :+
        inx
:       sta     handler_hatab+6
        stx     handler_hatab+7

        ; And store our new handler table
        clc
        adc     #(handler_hatab - handler_put + 1)
        bcc     :+
        inx
:       sta     hatabs_l+1
        stx     hatabs_h+1

        ; And address of new MEMLO
        clc
        adc     #(handler_end - handler_hatab)
        sta     sMEMLOL+1

        ; If we adjusted X it means that in the reload handler
        ; we also need to increment X, so keeps the "INX" in the code
        bcs     :+
        ; We did not increment X, replace the INX with a NOP.
        lda     #234    ; NOP
        sta     sMEMLOH
:

        ; Copy our handler code to new position
copy_handler:
        ldy     #(handler_end - handler_start)
cloop:  lda     handler_start-1,y
        dey
        sta     (pntr),y
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

dev_e:
install_msg:    ; NOTE: message must begin with "E:"
        .byte   "E:Fast Installed", $9B

error_msg:
        .byte   "Can't install", $FD, $9B


        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ;       Installed handler
        ;
handler_start:

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

        ; Handler PUT function
handler_put:
        ; Don't handle in graphics modes
        ldx     DINDEX
        bne     jhand

        ; Don't handle wrap at last column!
        ldx     COLCRS
        cpx     RMARGN
        bcs     jhand

        ; Check for control character:
        ;  $1B, $1C, $1D, $1E, $1F, $7D, $7E, $7F
        ;  $9B, $9C, $9D, $9E, $9F, $FD, $FE, $FF
        ;
        ; Store original in Y and shift A to remove high bit:
        tay
        asl
        cmp     #2*ATCLR
        bcs     jhandy  ; Skip $7D-$7F and $FD-$FF
        sbc     #$3F
        bpl     conv_ok ; $20-$5F and $A0-$DF are ok
        cmp     #$C0 + 2 * ATESC - 1
        bcs     jhandy  ; Skip $1B-$1F and $9B-$9F
        eor     #$40
conv_ok:
        cpy     #$80    ; Restore sign
        ror

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
        inc     COLCRS
        lda     COLCRS
        sta     OLDCOL
        inc     LOGCOL

        ; Reset ESC flag
        sty     ESCFLG
        ; Return with Y = 1 (no error)
        iny
        rts

; Calls original E: put
jhandy: tya
jhand:  jmp     $FFFF

        ; Handler device table
handler_hatab:

; End of resident handler
handler_end = handler_hatab + 16

; vi:syntax=asm_ca65

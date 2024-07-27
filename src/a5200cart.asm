;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2024 Daniel Serpell
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


; Startup and support code for the Atari 5200 port
; ------------------------------------------------

        .import         start, set_grmode, get_key
        ; Linker vars
        .import         __CART_PAL__
        .import         __BSS_RUN__, __BSS_SIZE__
        .import         __INTERP_LOAD__, __INTERP_RUN__, __INTERP_SIZE__
        .import         __DATA_LOAD__, __DATA_RUN__, __DATA_SIZE__
        ; Move
        .import         move_dwn
        .importzp       move_dwn_src, move_dwn_dst

        .exportzp       COLRSH, DINDEX, COLCRS, ROWCRS, SAVMSC
        .exportzp       BASIC_TOP, array_ptr
        .export         STICK0, STICK1, STICK2, STICK3
        .export         STRIG0, STRIG1, STRIG2, STRIG3
        .export         PTRIG0
        .export         STRIG0B, STRIG1B, STRIG2B, STRIG3B
        .export         CH
        .export         GPRIOR, MEMTOP
        .export         stack_start, line_buf

        .zeropage
        ; ZP locations to emulate joystick and keyboard
COLRSH: .res 1  ; Used as DLI pointer
DINDEX: .res 1  ; Display mode index

SAVMSC: .res 2
ROWCRS: .res 1
COLCRS: .res 2

        ; ZP locations used by FastBasic:
array_ptr:      .res    2       ; Top of array memory
BASIC_TOP=      array_ptr

        .data
        ; Emulate Atari 8-bit locations
        ; This have fixed locations because we need to optimize the
        ; generated code based in the address
        ; ** KEEP SYNCHRONIZED WITH SYNTAX FILE 'a5200.syn' **

STICK0 = $21C
STICK1 = $21D
STICK2 = $21E
STICK3 = $21F

STRIG0 = $220
STRIG1 = $221
STRIG2 = $222
STRIG3 = $223

STRIG0B = $224
STRIG1B = $225
STRIG2B = $226
STRIG3B = $227

        ; Make PTRIG() return the state of the secondary joystick button
PTRIG0 = STRIG0B

stack_start = $228      ; Stack is from $228 to $277
line_buf = $280         ; This is the same as "LBUFF" in the A800 version,
                        ; so it's used from $27F and up to $37F.

        ; Keyboard handling
        .data
KEYCURR: .byte 0

KEYOLD0: .byte $ff, $ff, $ff, $ff
KEYNEW0: .byte $ff, $ff, $ff, $ff

CH0:     .byte $ff, $ff, $ff, $ff
CH:      .byte $ff

GPRIOR:  .byte 0

MEMTOP:  .word $3fff

        .code
        ; Forces an error if compilation options allows self-modifying-code:
.ifndef NO_SMCODE
        .assert (start=0), error, "You must compile library with '--asm-define NO_SMCODE' to make cartridges."
.endif

        .include "target.inc"

cartridge_start:
        ; Update interrupt handlers
        sei
        lda     #$00        ; Disable all interrupts
        sta     NMIEN
        sta     IRQEN
        sta     SKCTL
        sta     DMACTL      ; Blank screen
        sta     SDMCTL

        lda     #2
        sta     CHACTL      ; Normal inverse video

sync:   lda     VCOUNT
        bne     sync

        lda     #<vbi_deferred
        ldx     #>vbi_deferred
        sta     VVBLKD
        stx     VVBLKD+1
        lda     #<kb_continue
        ldx     #>kb_continue
        sta     VKYBDF
        stx     VKYBDF+1

        lda     #$04
        sta     CONSOL      ;Speaker off, Pots enabled, port #1 selected

        ; Copies ROM to RAM

        ; Copy ZP interpreter
        ldx     #<__INTERP_SIZE__
copy_interpreter:
        lda     __INTERP_LOAD__, x
        sta     <__INTERP_RUN__, x
        dex
        bpl     copy_interpreter

        .assert (__INTERP_RUN__ < $100), error, "Interpreter must be in ZP"
        .assert (__INTERP_SIZE__ < $80), error, "Interpreter must be less than 128 bytes"

        ; Copy the DATA segment
        lda     #<__DATA_LOAD__
        ldx     #>__DATA_LOAD__
        sta     move_dwn_src
        stx     move_dwn_src+1
        lda     #<__DATA_RUN__
        ldx     #>__DATA_RUN__
        sta     move_dwn_dst
        stx     move_dwn_dst+1
        lda     #<__DATA_SIZE__
        ldx     #>__DATA_SIZE__
        jsr     move_dwn


        ; Initialize A8-equivalent registers
        lda     #$40
        sta     NMIEN       ;Enable NMI interrupts
        sta     IRQEN       ;Enable IRQ interrupts
        lda     #2
        sta     SKCTL       ;Enable keyboard scanning circuit (without debounce)
        cli

        ; Sets initial graphics mode
        lda     #0
        jsr     set_grmode

        ; Starts interpreter
        jsr     start

        ; Waits for key press
        jsr     get_key

        ; RESET
        jmp     ($FFFC)


    .proc vbi_deferred

center  =   228/2
range   =   80/2

        ldy     #0
        sty     COLRSH          ; Reset ATRACT COLOR SHIFTER, used by FB's DLI
        iny
        sty     SKCTL           ; Disable keyboard processing, to avoid spurious interrupts

        ldy     #6
        ;Read analog sticks and make it look like a digital stick
nextstick:
        lda     #0
        ldx     PADDL0, y       ; Read POT0 value (horizontal position)
        cpx     #center+range   ; Compare with right threshold
        rol                     ; Feed carry into digital stick value
        cpx     #center-range   ; Compare with left threshold
        rol                     ; Feed carry into digital stick value
        ldx     PADDL1, y       ; Read POT1 value (vertical position)
        cpx     #center+range   ; Compare with down threshold
        rol                     ; Feed carry into digital stick value
        cpx     #center-range   ; Compare with down threshold
        rol                     ; Feed carry into digital stick value
        eor     #%00001010      ; 0 indicates a press so the right/down values need to be inverted
        pha
        tya
        lsr
        tax
        pla
        sta     STICK0, x
        lda     TRIG0, x        ; Move trigger to shadow
        sta     STRIG0, x

        dey
        dey
        bpl     nextstick

        lda     GPRIOR
        sta     PRIOR

        ; Check last controller
        ldx     KEYCURR

        lda     KEYNEW0, x      ; Read current key state...
        cmp     KEYOLD0, x      ; ..and compare with old key
        sta     KEYOLD0, x      ; Store in old key
        beq     no_change       ; Key did not change state
        cmp     #$FF
        beq     no_change       ; Key is up, don't process

        ; New key pressed, pass to application
        sta     CH0, x

        ; And store as "global" key
        txa
        asl
        asl
        asl
        asl
        ora     CH0, x
        sta     CH

no_change:

        ; Check 2nd button state, bit 3 of SKSTAT
        lda     SKSTAT
        lsr
        lsr
        lsr
        and     #1
        sta     STRIG0B, x

        ; Prepare next keypad
        inx
        txa
        and     #3
        sta     KEYCURR
        tax
        ora     #4
        sta     CONSOL          ; Enable scan of keypad X
        lda     #$FF
        sta     KEYNEW0, x      ; Erase current key state

        ; Enable keyboard scanning and interrupts again
        ; This is needed as we use POKMSK (address 0) for FastBasic
        ; String support, so it must be set to 0.
        lda     #$40
        sta     IRQEN
        lda     #2
        sta     SKCTL

        ; Exit VBI
        pla
        tay
        pla
        tax
        pla
        rti
    .endproc


        ;Keyboard continue routine, IN: <A>=key code
    .proc kb_continue
        ldx     KEYCURR         ; Current keypad
        sta     KEYNEW0, x      ; Store into "new key"

        pla
        tay
        pla
        tax
        pla
        rti
    .endproc

        ; Include the cartridge header

        .segment        "CARTPAL"
.ifdef _PAL_
        .byte   2
.else
        .byte   0
.endif

        .segment        "CARTNAME"
        .byte   0,0,$55,$52,$50,$50,0,"supersystem",0,0

        .segment        "CARTYEAR"
        .byte   $58,$52

        .segment        "CARTENTRY"
        .word   cartridge_start

; vi:syntax=asm_ca65

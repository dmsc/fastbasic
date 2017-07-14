' P/M test program
RAMTOP = $6A   : SDMCTL = $22F  : PCOLR0 = $2C0
HPOSP0 = $D000 : GRACTL = $D01D : PMBASE = $D407
' Reserve memory at TOP
MemTop = Peek(RAMTOP) - 4
P0Mem  = $100 * MemTop + $200
oldPos = P0Mem
poke RAMTOP, MemTop

' Activate and configure P/M data
graphics 0
poke P0Mem, 0 : move P0Mem, P0Mem+1, 127 : ' Clears Memory
poke PCOLR0, $1F
poke SDMCTL, Peek(SDMCTL) ! 8
poke PMBASE, MemTop
poke GRACTL, 2

' P/M data and blank (to clear P/M)
DATA PMdata()  byte = $38,$44,$54,$44,$38
DATA PMclear() byte = $00,$00,$00,$00,$00

' Initial Conditions
xPos = 6400 : yPos = 2560
xSpd =   64 : ySpd =    0

do
 xPos = xPos + xSpd : yPos = yPos + ySpd
 ySpd = ySpd + 2
 if (ySpd > 0) and (yPos > 12800)
   ySpd = -ySpd
   xSpd = Rand(512) - 256
 endif
 if xSpd > 0
  if xPos > 25600 Then xSpd = -xSpd
 else
  if xPos <  6400 Then xSpd = -xSpd
 endif
 exec MovePm : ' Move P/M Graphics
loop

proc MovePm
 x = xPos / 128 : y = P0Mem + yPos / 128
 poke $D01A,$74 : ' Change background color
 pause 0
 poke HPOSP0, x
 move adr(PMclear), oldPos, 5
 move adr(PMdata),  y,      5
 oldPos = y
endproc

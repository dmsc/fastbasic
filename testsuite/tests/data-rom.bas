' Test DATA in ROM segments
? "Start"

DATA rfb() ROM = 1,2,3,4,5
DATA rfw() BYTE ROM = 1,2,3,4,5,6
DATA dfw() BYTE = 7, 8, 9
DATA other() [RUNTIME] = 128, 129, 130, 131

? rfb(0), rfb(1)
? rfw(0), other(1)
' Check that the DATA addresses are in different segments
? ABS(ADR(dfw) - ADR(rfw)) > 10


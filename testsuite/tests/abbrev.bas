' Test for function abbreviations
? "Start"
MEM=DPEEK($2E5) ' Get MEMTOP value
DPOKE 1536, 1234
? DPEEK 1536 * 2
? SGN ABS DPEEK 1536
? D.(1536) + D. 1536
? E. , CHR$ 65 , STR$ 65
E = 10
? E.
D = 3
? D.(1536) + D. 1536
A = -1
? ABSA, A.A
ABSA = 10
? ABSA
' PRINT TAB:
? 1 T. 5 3  ' This is parsed as ? 1 ; TAB(5) ; 3
? 1 T.5+3   ' This is parsed as ? 1 ; TAB(5) ; +3
? 1 T.(5+3) ' This is parsed as ? 1 ; TAB(5+3)
? 1 C.1+1   ' This is parsed as ? 1 ; COLOR(1) +1
? R.1+1     ' This is parsed as ? RTAB(1) +1
? "X"

' Test all abbreviations:

H = $600
.                 ' REM
-. ADR("123"),H,4 ' -MOVE
? P.H             ' PEEK
? D.H             ' DPEEK

BG. #0,H,6        ' BGET
D. H,$4241        ' DPOKE
BP. #0,H,6        ' BPUT

O.  #6,12,0,"S:"  ' OPEN

C.6               ' COLOR
PL.4,5            ' PLOT
DR.7,8            ' DRAWTO
FC.8              ' FCOLOR
FI.10,20          ' FILLTO
POS.15,30         ' POSITION
X.#6,17,0,0,"X"   ' XIO

CL. #6            ' CLOSE
G.0               ' GRAPHICS
LOC.1,2,B         ' LOCATE

DA.U()B.=1        ' DATA BYTE
DA.V()W.=256      ' DATA WORD

DE.A : ? A        ' DEC

DO                ' DO
  I.A<0           ' IF
    ? -A
  ELI.A=0         ' ELIF
    ? "X"
  EL.             ' ELSE
    EX.           ' EXIT
  E.              ' ENDIF
  INC A           ' INC
L.                ' LOOP

F.A=2T.5S.2       ' FOR TO STEP
  ? A
N.                ' NEXT

EXE.P1            ' EXEC

PR.P1             ' PROC
 ? "P1"
ENDP.             ' ENDPROC

GE.A : ? CHR$(A)  ' GET
IN.C$: ? C$       ' INPUT

P.H,5             ' POKE
MS.H+1,5,66       ' MSET
M.H,H+10,6        ' MOVE
?$(H+10)

T.                ' TIMER
PA.1              ' PAUSE
PA.               ' PAUSE 0
PRI.T.            ' PRINT TIME

R.                ' REPEAT
 ? "R"
U.1               ' UNTIL

A=2
W.A               ' WHILE
  ? "W";A
  DEC A
WE.               ' WEND

PU. #0,65         ' PUT

SE.0,0,0          ' SETCOLOR

PMG.1             ' PMGRAPHICS
PM.0,2            ' PMHPOS

S.0,100,10,4      ' SOUND
S.0               ' SOUND
S.                ' SOUND

DI.R(10),R1(10)B. ' DIM
?R(0)

DL.               ' DLI
DL.S.D=0I.0,0W.W.I.1 ' DLI SET INTO WSYNC

' Functions and DEG/RAD
? "FP-FUN"
DEG               ' DEG
?I.(SI.(0.01)*10000) ' INT SIN
RA.               ' RAD
?I.(SI.(0.01)*100)   ' INT SIN
?I.(CO.(0.2)*100) ' INT COS

? A.1.1           ' ABS FP
? AT.0            ' ATN
? SG.1.0          ' SGN FP
? EX.1            ' EXP10
? LO.10           ' LOG10
? SQ.4            ' SQR
? COS0            ' COS
? 0.0 + V."0.1"   ' VAL FP
? RN.>=0.0        ' RND


? "INT-FUN"
? N.N.N.1         ' NOT NOT NOT
? MEM-F.>8192     ' FRE()
? E.              ' ERR()
P.764,127
? K.              ' KEY()
? A.-10           ' ABS INT
? SG.4            ' SGN
P.$270,123
? PA.0            ' PADDLE
P.$27D,5
? PT.1            ' PTRIG
P.$27A,15
? S.2             ' STICK
P.$284,3
? STR.0           ' STRIG
? MEM-PM.0        ' PMADR
? R.1             ' RAND
' ? USR()         ' USR (can't abbreviate)
? ADR(R1)-ADR(R)  ' ADR (can't abbreviate)
? &R1-&R          ' ADR
? L."123"         ' LEN
? V."123"         ' VAL
? AS."123"        ' ASC

? "OPER"
? 1A.1;0A.1;0A.0  ' AND
? 1O.1;0O.1;0O.0  ' OR
? 1&1;0&1;0&0     ' INT-AND
? 1!1;0!1;0!0     ' INT-OR
? 1E.1;0E.1;0E.0  ' EXOR
? 13/5;13*5;13M.5 ' /, *, MOD
? E.E.E.          ' ERR() EXOR ERR()

END

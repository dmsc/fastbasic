' Test speed of block I/O versus
' line oriented I/O.

' Get free memory
DIM A(0) byte
max = FRE()

? "---------------"
? "Memory:", max

' Test BGET speed:
? "--- Read with BGET --"
? "Err:",
st = TIME
OPEN #1, 4, 0, "D:CARRERA3.BAS"
? ERR(),
BGET #1, ADR(A), max
? ERR(),
total = DPEEK($358)
CLOSE #1
? ERR()
? "Read:", total

' Count lines!
ptr  = ADR(A)
pend = ptr + total
lines = 0

WHILE ptr < pend
  IF PEEK(ptr) = $9b
    INC lines
  ENDIF
  INC ptr
WEND
et = TIME
? "Lines:", lines
? "Time:", et-st

' Test INPUT speed:
line$ = ""
lines = 0
? "--- Read with INPUT --"
? "Err:",
st = TIME
OPEN #1, 4, 0, "D:CARRERA3.BAS"
? ERR(),
WHILE ERR() < 128
  INPUT #1, line$
  INC lines
WEND
? ERR(),
CLOSE #1
? ERR()
et = TIME
? "Lines:", lines
? "Time:", et-st

' Test GET speed:
? "--- Read with GET --"
? "Err:",
st = TIME
OPEN #1, 4, 0, "D:CARRERA3.BAS"
? ERR(),

' Count lines while reading
total = 0
lines = 0
WHILE ERR() < 128
  GET #1, x
  IF x = $9b
    INC lines
  ENDIF
  INC total
WEND
? ERR(),
CLOSE #1
? ERR()

et = TIME
? "Read:", total
? "Lines:", lines
? "Time:", et-st


' Test some IO

dim A(0) byte
max = fre()
line$=""

? "---------------"
? "Mem:", max
? "--- Read with BGET --"
? "Err:",
st = time
open #1, 4, 0, "D:CARRERA3.BAS"
?err(),
bget #1, adr(A), max
?err(),
total = dpeek($358)
close #1
?err()
? "Read:", total

' Count lines!
ptr  = adr(A)
pend = ptr + total
lines = 0

while ptr < pend
  if peek(ptr) = $9b
    inc lines
  endif
  inc ptr
wend
et = time
? "Lines:", lines
? "Time:", et-st

lines = 0
? "--- Read with INPUT --"
? "Err:",
st = time
open #1, 4, 0, "D:CARRERA3.BAS"
?err(),
while err() < 128
  input #1, line$
wend
?err(),
close #1
?err()
et = time
? "Lines:", lines
? "Time:", et-st


' Test for "POKE" and "DPOKE" statements
? "Start"
dim A(10), B(1)
addr = Adr(A)

B(0) = 12345
for i=0 to 10
  dpoke addr+2*i, i*i
next i

for i=0 to 10
  ? A(i); " ";
next i
?

if B(0) <> 12345
  ? "corrupted B"
endif

xstr$="Test String"
addr = Adr(xstr$)

for i=1 to 10
  poke addr+i, 65 + i
next i

? xstr$

' Check POKE of constant numbers
POKE 80, 1
? PEEK(80)
POKE 1536, 2
? PEEK(1536)
DPOKE 80, 1234
? DPEEK(80)
DPOKE 1536, 1234
? DPEEK(1536)


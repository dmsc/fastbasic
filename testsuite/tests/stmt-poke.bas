' Test for "POKE" and "DPOKE" statements
? "Start"
dim A(10)
addr = Adr(A)

for i=0 to 9
  dpoke addr+2*i, i*i
next i

for i=0 to 9
  ? A(i); " ";
next i
?

xstr$="Test String"
addr = Adr(xstr$)

for i=1 to 10
  poke addr+i, 65 + i
next i

? xstr$


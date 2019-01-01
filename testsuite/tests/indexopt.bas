
A$="Hello World"

? A$
? ASC(A$) = 65
? A$

X = 3

? 1 + X + 1
? X + 1 + 2

for i=1 to LEN(A$)
  ? A$[i,1], PEEK(ADR(A$)+i), ASC(A$[i]),
  if i > 1
    ? ASC( A$[i-1][2] )
  else
    ?
  endif
next i

for i=1 to LEN(A$)
  ? ASC( A$[i,1])
next i




A$ = "Long string, filled with characters."
? A$

for i = 10 to 15
  mset Adr(A$) + i, 35 - 2 * i, i + Asc("A") - 10
  ? A$
next


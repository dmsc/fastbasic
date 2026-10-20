' POKE with a constant byte address and arbitrary value expression.
DIM A(5)
A(1) = 2

POKE 80, A(1) * 3
? PEEK(80)

POKE 80, 10 + 2
? PEEK(80)

POKE 80, A(1)
? PEEK(80)

' Multiple statements on one line must not be merged.
POKE 80, 7 : POKE 81, 9
? PEEK(80); " "; PEEK(81)

' A preceding DPOKE must stop the expression span.
DPOKE 80, 0 : POKE 81, 5
? PEEK(81)

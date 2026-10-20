' POKE with a symbolic byte address and arbitrary value expression.
DIM A(5)
A(1) = 2

POKE @@TMPCHR, A(1) * 5
? PEEK(@@TMPCHR)

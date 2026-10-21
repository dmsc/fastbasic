' Check peephole address increment/decrement rules.
DIM A
A = 10

DPOKE ADR(A), A + 1
? A

DPOKE ADR(A), A - 1
? A

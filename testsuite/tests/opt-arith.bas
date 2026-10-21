' Check peephole arithmetic rules.
DIM A
DIM B
DIM C
A = 10
B = 3
C = 2

? 7 - 2
? -(1 + 2)
? A / 1
? A * 1
? A * 4
? A * 256
? A - 0
? A - B - C
? A - B - 2
? A - 2 - B
? A - 2 - 3
A = A - 1
? A
' Reassociate a constant added after a subtraction or another addition.
? A - B + 7
? A + B + 7
? A + B + 300

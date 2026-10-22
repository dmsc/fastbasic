' Check peephole rules that remove a variable load after a store of the same
' variable, the accumulator is preserved by VAR_STORE.
DIM A, B, C, D
A = 1234 + 5
? A

B = 0
? B

' PUSH clobbers A, so a load after a push must not be removed
C = 7
D = C * C
? D

A = 300
B = A - A
C = A * A
? B; " "; C

' Stored value must also be correct after the preserved store
A = 40000
B = A
? A; " "; B

' The x + x rule must still apply when the variable was not just stored
? A
B = A + A
? B

' Check peephole boolean rules.
DIM A
DIM B
A = 1
B = 2

? (A = B)
? (A > B)
? ((A > B) OR (A = B))
IF (A OR B) THEN ? "or"
IF NOT (A = B) THEN ? "ne"
IF NOT (A <> B) THEN ? "eq"
IF NOT 1 THEN ? "bad"
? "done"
' De Morgan peephole on "NOT A AND B" conditions.
DIM C
A = 0
B = 1
C = 1
IF A = 0 AND B = C THEN ? "and-eq"
IF A = 0 AND B <> C THEN ? "bad-ne"
B = 2
IF A = 0 AND B = C THEN ? "bad-eq"
IF A = 0 AND B <> C THEN ? "and-ne"
? "done2"

' A PUSH that belongs to a call argument list must not be treated as the
' left operand of AND.
PROC Id X
  RETURN X
ENDPROC
A = 1
B = 1
C = 1
IF @Id(NOT A) AND B = C THEN ? "bad-call"
? "call-ok"

' Likewise, a PUSH from an arithmetic expression inside an array index must
' not be treated as the AND left operand.
DIM Q(10)
Q(1) = 0
Q(2) = 0
B = 0
C = 1
X = 1
Y = 1
IF Q((NOT B) + C) AND X = Y THEN ? "bad-array"
? "array-ok"

' Fused PUSH_BYTE + EQ must compare the full 16-bit left operand, and
' PUSH_BYTE + NEQ + CRET can be rewritten as EQ_BYTE + CNRET.
DIM V
V = 300
? (V = 44)
V = 44
? (V = 44)
? (V = 45)
? ((V = 44) + (V = 45))
? @Id(V = 44)

PROC CheckV
  IF V <> 155 THEN ? "neq-cret"
ENDPROC

V = 155
EXEC CheckV
V = 156
EXEC CheckV
V = 411
EXEC CheckV

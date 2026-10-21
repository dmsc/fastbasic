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

' Check peephole conditional-return rules.
DIM A
A = 1

PROC P
  IF A THEN RETURN
  ? "p"
ENDPROC

PROC Q
  IF NOT A THEN RETURN
  ? "q"
ENDPROC

@P
@Q

A = 0
@P
@Q
? "done"

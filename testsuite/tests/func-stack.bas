' Function calls inside a DIM expression use both the variable stack and
' the function-label stack.  They must share the same stack correctly.
PROC Three
  RETURN 3
ENDPROC

DIM A(@Three()) BYTE
A(2) = 7
? A(2)

PROC Show X
  ? X
ENDPROC

@Show @Three()

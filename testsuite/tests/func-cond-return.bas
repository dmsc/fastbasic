' A function only needs at least one RETURN; full path coverage is not checked.
PROC Maybe X
  IF X THEN RETURN 1
ENDPROC

? @Maybe(1)

' Check conditional RETURN 0 optimization with both branch directions.
' F returns a global so the same test covers zero, odd, even and 16-bit
' non-zero values.  The optimizer must keep COMP_0: a raw CALL/CRET would
' incorrectly return for values such as 2 or 256.

' Create the variable before the functions; DIM is the documented way
' to define a variable that is used as an rvalue in a PROC.
DIM V

PROC F
  RETURN V
ENDPROC

PROC GN
  IF NOT @F() : RETURN 0 : ENDIF
  RETURN 1
ENDPROC

PROC GP
  IF @F() : RETURN 0 : ENDIF
  RETURN 1
ENDPROC

V = 0
? @GN()
? @GP()

V = 1
? @GN()
? @GP()

V = 2
? @GN()
? @GP()

V = 256
? @GN()
? @GP()

V = -2
? @GN()
? @GP()

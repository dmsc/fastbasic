' RETURN inside FOR must remove the active FOR state before leaving.
PROC First N
  FOR I = 1 TO N
    RETURN N + 10
  NEXT I
  RETURN 0
ENDPROC

PROC Nested
  FOR I = 1 TO 2
    FOR J = 1 TO 2
      RETURN I * 10 + J
    NEXT J
  NEXT I
  RETURN 0
ENDPROC

? @First(3)
? @First(2)
? @Nested()

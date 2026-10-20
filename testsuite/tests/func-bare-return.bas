' Bare RETURN exits the current PROC and unwinds nested FOR loops.
PROC Early
  ? "early"
  RETURN
  ? "after"
ENDPROC

PROC Nested
  FOR I = 1 TO 2
    FOR J = 1 TO 2
      ? "loop"
      RETURN
    NEXT J
  NEXT I
  ? "after"
ENDPROC

@Early
@Nested
? "done"

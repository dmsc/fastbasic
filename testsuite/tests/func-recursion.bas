PROC Fact N
  IF N <= 1 THEN RETURN 1
  RETURN N * @Fact(N-1)
ENDPROC

? @Fact(5)

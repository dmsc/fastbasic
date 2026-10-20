PROC Add X
  RETURN X + 1
ENDPROC

PROC Mul X Y
  RETURN X * Y
ENDPROC

PROC Forty
  RETURN 42
ENDPROC

? @Add(4)
? @Add(5)
? @Mul(3,5)
? @Add(@Mul(2,3))
? @Add(1) + @Add(2)
? @Forty()

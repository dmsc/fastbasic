DIM B(3) BYTE
DIM W(3)

PROC Plus X
  RETURN X + 10
ENDPROC

PROC Twice X
  RETURN X + X
ENDPROC

B(1) = @Plus(5)
W(2) = @Plus(7)
B(2) = @Twice(@Plus(1))

? B(1)
? B(2)
? W(2)

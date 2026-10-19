' Test abbreviations of ENDPROC and ENDIF
PROC P1 X
  IF X > 1
    ? "BIG ";
  EN.
  ? X
EN.
PROC P2 X
  IF X = 1
    ? "ONE"
  ELIF X = 2
    ? "TWO"
  ELSE
    ? "MANY"
  E.
END.
PROC P3 X
  DO
    IF X > 2 THEN EXIT
    INC X
  LOOP
  IF X = 3
    ? "THREE"
  ENDI.
ENDP.
PROC P4:? "P4":EN.
? "Start"
@P1 1:@P1 5
@P2 1:@P2 2:@P2 3
@P3 0
@P4
IF 1
  ? "IF"
EN.

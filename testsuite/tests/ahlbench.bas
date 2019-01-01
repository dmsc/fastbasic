
' Based on AHL's simple benchmark
S%=0
FOR N=1 TO 100
 A%=N
 FOR I=1 TO 10
  A%=SQR(A%)
 NEXT I
 FOR I=1 TO 10
  A%=A%^2
 NEXT I
 S%=S%+A%
NEXT N

chk% = 5e-4
exec check

S%=0
FOR N=1 TO 100
 A%=N
 FOR I=1 TO 5
  A%=A%^0.4
 NEXT I
 FOR I=1 TO 5
  A%=A%^2.5
 NEXT I
 S%=S%+A%
NEXT N

chk% = 1e-4
exec check

S%=0
FOR N=1 TO 100
 A%=N/250.0
 FOR I=1 TO 10
  A%=SIN(A%)/COS(A%)
 NEXT I
 FOR I=1 TO 10
  A%=ATN(A%)
 NEXT I
 S%=S%+A%
NEXT N

S%=S%*250
chk% = 5e-5
exec check


proc check
  ? "Accuracy: ";
  accuracy% = ABS(1010-S%/5)
  if accuracy% < chk%
    ? "OK"
  else
    ? "BAD "; accuracy%
  endif
endproc

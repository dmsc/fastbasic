
A=1
IFA=0
 ? "OK"
' This should be parsed as a variable, not as ELSE A=1:
ELSEA=1
ENDIF

? A,ELSEA

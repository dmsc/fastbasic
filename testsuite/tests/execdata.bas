' Test for using a DATA array in EXEC parameter
DATA Arr() = 1234,5678
@Test Arr(0)
@Test Arr(1)
? "Ok"

PROC Test X
  ? X
ENDPROC


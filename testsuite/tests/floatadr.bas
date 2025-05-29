' Procedure to sum N elements of an array:
PROC SUM P N
  SUM% = 0
  WHILE N>0
    DEC N
    SUM% = SUM% + %(P)
    P = P + 6
  WEND
ENDPROC

DIM A%(2)
A%(0) = 0.125
A%(1) = 0.0625
A%(2) = 0.03125

@SUM &A%, 3
? SUM%

DATA B%() = -0.125, 0.0625, 0.03125
@SUM &B%, 3
? SUM%

X%=1234.5

@SUM &X%, 1
? SUM%

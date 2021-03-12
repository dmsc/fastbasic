' Test miscellaneous floating-point functions
? "Start"
A%=VAL("-0.123") : ? A%
A%=VAL("1E+10")  : ? A%
A%=12.45   : B=INT(A%) : ? ERR(),B
A%=12.50   : B=INT(A%) : ? ERR(),B
A%=-12.45  : B=INT(A%) : ? ERR(),B
A%=-12.50  : B=INT(A%) : ? ERR(),B
A%=32767.0 : B=INT(A%) : ? ERR(),B
A%=32767.5 : B=INT(A%) : ? ERR(),B
A%=65535.5 : B=INT(A%) : ? ERR(),B

A%=8E+97 : A% = A%+2E+97 : X%=0 : @check
A%=2 : A% = A%^280 : X%=1.94266889E+84 : @check         ' Valid
A%=2 : A% = A%^329 : X%=0 : @check                      ' Overflow on square
A%=5 : A% = A%^141 : X%=0 : @check                      ' Overflow on multiplication
A%=2 : A% = A%^-30 : X%=9.31322574615E-10 : @check      ' Valid small
A%=2 : A% = A%^-326 : X%=0 : @check                     ' Underflow -> 0
A%=2 : A% = A%^0   : X%=1 : @check                      ' One

A%=2  : A% = SQR(A%) : X%=1.41421356237 : @check
A%=-2 : A% = SQR(A%) : X%=-2            : @check
A%=0  : A% = SQR(A%) : X%=0             : @check

' Many random numbers
FOR I=0 TO 199 : A%=RND() : IF A%<0 OR A%>=1 THEN EXIT : NEXT
? I

DEG
A%=ATN(1)  : X%=45 : @check
A%=SIN(1)  : X%=.01745240643728 : @check
A%=SIN(-1) : X%=-.01745240643728 : @check
A%=COS(1)  : X%=.99984769515639 : @check
A%=COS(-1) : X%=.99984769515639 : @check
A%=COS(1E12) : X%=0 : @check                    ' Arg too big
RAD
A%=ATN(1)    : X%=.78539816339 : @check
A%=SIN(1)    : X%=.841470984807896: @check
A%=SIN(-1)   : X%=-.841470984807896: @check
A%=COS(1)    : X%=.54030230586814 : @check
A%=COS(-1)   : X%=.54030230586814 : @check
A%=COS(1234) : X%=-.798549        : @check




PROC check
  ? ERR(),
  X% = (A% - X%)/X%
  IF X% < -0.000001 OR X% > 0.000001
    ? "BAD", A%
  ELSE
    ? "OK"
  ENDIF
ENDPROC

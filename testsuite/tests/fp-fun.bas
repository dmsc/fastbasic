' Test floating-point functions
? "Start"
A%=0
? SGN(1.1)
? SGN(-1.1)
? SGN(-A%)
? EXP(0)
? LOG(1)
? LOG10(10)
? EXP10(1)
? ABS(-1.1)
? ABS(1.1)
? ABS(A%)
? ABS(-A%)
? SQR(100.0)
? SQR(16.0)
? SQR(81.0)
? "VAL"
? 0.0 + VAL("1.1")
? 0.0 + VAL("1E+10")
? 0.0 + VAL("-1E-10")
RAD
? "RAD"
? ATN(0)
? INT(ATN(1) * 1000000 - 785398)
? INT(ATN(-1) * 1000000 + 785398)
? INT(ATN(2) * 1000000 - 1107149)
? SIN(0)
? INT(SIN(0.0001) * 1000000000 - 100000)
? INT(SIN(0.1)    * 10000000   - 998334)
? INT(SIN(100)    * 1000000    + 506366)
? COS(0)
DEG
? "DEG"
? INT(ATN(1)   * 1000000  - 45000000)
? INT(SIN(100) * 10000000 -  9848078)
? INT(COS(100) * 10000000 +  1736482)


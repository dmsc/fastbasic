' Test comparisons:
a=1234
? "INTEGER TESTS"
? "1 < : "; : if 1234 < a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 < : "; : if  980 < a  : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 < : "; : if 1297 < a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 > : "; : if 1234 > a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 > : "; : if  980 > a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 > : "; : if 1297 > a  : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 <=: "; : if 1234 <= a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 <=: "; : if  980 <= a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <=: "; : if 1297 <= a : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 >=: "; : if 1234 >= a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 >=: "; : if  980 >= a : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 >=: "; : if 1297 >= a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 = : "; : if 1234 = a  : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 = : "; : if  980 = a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 = : "; : if 1297 = a  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <>: "; : if 1234 <> a : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 <>: "; : if  980 <> a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <>: "; : if 1297 <> a : ? "PASS" : ELSE : ? "FAIL" : ENDIF

x% = 12.34
? "FP TESTS"
? "1 < : "; : if 12.34 <  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 < : "; : if  0.98 <  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 < : "; : if  1134 <  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 > : "; : if 12.34 >  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 > : "; : if  0.98 >  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 > : "; : if  1134 >  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 <=: "; : if 12.34 <= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 <=: "; : if  0.98 <= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <=: "; : if  1134 <= x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 >=: "; : if 12.34 >= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 >=: "; : if  0.98 >= x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 >=: "; : if  1134 >= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 = : "; : if 12.34 =  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 = : "; : if  0.98 =  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 = : "; : if  1134 =  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <>: "; : if 12.34 <> x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 <>: "; : if  0.98 <> x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <>: "; : if  1134 <> x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF

s$ = "Hello"
? "STR TESTS"
? "1 < : "; : if "Hello" <  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 < : "; : if "Hell"  <  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 < : "; : if "Hold"  <  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "4 < : "; : if "Hellos" < s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "5 < : "; : if "Hall"  <  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 > : "; : if "Hello" >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 > : "; : if "Hell"  >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 > : "; : if "Hold"  >  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "4 > : "; : if "Hellos" > s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "5 > : "; : if "Hall"  >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <=: "; : if "Hello" <= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 <=: "; : if "Hell"  <= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <=: "; : if "Hold"  <= s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 >=: "; : if "Hello" >= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 >=: "; : if "Hell"  >= s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 >=: "; : if "Hold"  >= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 = : "; : if "Hello" =  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 = : "; : if "Hell"  =  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 = : "; : if "Hold"  =  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <>: "; : if "Hello" <> s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 <>: "; : if "Hell"  <> s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <>: "; : if "Hold"  <> s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF

? "BOOL EXPR TESTS"
x0 = 0 : x1 = 1 : x256 = 256
? "AND/OR:  "; : if x0 and x1 or x1: ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "OR/AND:  "; : if x1 or x1 and x0: ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/AND: "; : if NOT x0 AND x0  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/AND: "; : if NOT (x0 and x0): ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/NOT: "; : if NOT ((NOT x0)) : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/NOT: "; : if NOT NOT x0     : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/NOT: "; : if x1 = NOT NOT a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/+:   "; : if NOT x0 + x1    : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "(NOT)/+: "; : if (NOT x0) + x1  : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "conv:    "; : if x256           : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "par:     "; : if (x0<x1)        : ? "PASS" : ELSE : ? "FAIL" : ENDIF


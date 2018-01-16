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


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


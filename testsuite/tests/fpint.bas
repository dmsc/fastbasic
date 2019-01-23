
a% = 0.1        : exec pconv
a% = 0.5        : exec pconv
a% = 123.499    : exec pconv
a% = 123.500    : exec pconv
a% = 32767.4999 : exec pconv
a% = 32767.5000 : exec pconv

proc pconv
  i1 = int(a%)  : e1 = err()
  i2 = int(-a%) : e2 = err()
  ? a%, i1, e1, i2, e2
endproc

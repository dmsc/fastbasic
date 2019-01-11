' Test floating point comparisons
? "Start"

for i=0 to 10
  x% = 0.1 * i
  ? x%, x% < 0.5 , x% <= 0.5 , x% = 0.5, x% >= 0.5 , x% > 0.5
next i

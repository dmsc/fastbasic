' Test for floating point arrays
? "Start"
dim A%(5), Fib%(300)

Fib%(0) = 1
Fib%(1) = 1
for i=0 to 5
  A%(i) = i * 0.1
next
? Fib%(0), A%(5)

' Calculate fibonacci sequence
for i=2 to 300
  Fib%(i) = Fib%(i-1) + Fib%(i-2)
next
? Fib%(300)
? adr(Fib%) - adr(A%)


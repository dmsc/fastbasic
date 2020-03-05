' Test for statement "CLR"
? "Start"

n = 0
f = fre()

' Dim inside a PROC to call multiple times
proc dima
  ? "---- DIM "; n; " ----"
  ? "Before: "; f-fre()
  dim a(n)
  ? "After: "; f-fre()
endproc

n=10 : exec dima
n=10 : exec dima

? "---- CLR ----"
clr

? f, n, adr(a)

f = fre()
n=100 : exec dima


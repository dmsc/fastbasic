
start_time = TIME
' AHL'S SIMPLE BENCHMARK
FOR N=1 TO 100
 A%=N
 FOR I=1 TO 10
  A%=SQR(A%):R%=R%+RND()
 NEXT I
 FOR I=1 TO 10
  A%=A%^2:R%=R%+RND()
 NEXT I
 S%=S%+A%
NEXT N

PRINT "ACCURACY ";ABS(1010-S%/5)
PRINT "RANDOM ";ABS(1000-R%)
end_time = TIME
SC = end_time - start_time
? SC/60;" SECONDS"


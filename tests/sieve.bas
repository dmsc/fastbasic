? "Starting!"
NumIter = 1
sTime = TIME
DIM A(8190) Byte
FOR Iter= 1 TO NumIter
  Count = 0
  FOR I = 0 TO 8190
    A(I) = 1
  NEXT I
  FOR I = 0 TO 8190
    IF A(I)
      Prime = I + I + 3
      FOR K = I + Prime TO 8190 STEP Prime
        A(K) = 0
      NEXT K
      INC Count
    ENDIF
  NEXT I
NEXT Iter

eTime = TIME
? "End."
? "Elapsed time: "; eTime-sTime; " in "; NumIter; " iterations."
? "Found "; Count; " primes."

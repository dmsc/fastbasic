' Calculate PI to 254 digits
' ==========================

' Uses Machin formula:
'  Pi/4 = 4 * ATAN(1/5) - ATAN(1/239)
'
' The calculation is done in base 100,
' to simplify the code and printing.

' The arrays store two digits on each
' location (from 00 to 99).
DIM P(130), T(130) BYTE, SV(130) BYTE

' Arguments to procedures bellow
ZERO=0

' Precision in digit pairs
Q=127

' Start measuring time
STIME=TIME

' Cleanup numbers
FOR I=0 TO Q
 P(I) = 0
 T(I) = 0
NEXT

' Calculate ATAN(1/5), positive:
PRINT "A(1/5):";
EXEC ARCTAN_SMALL 1, 5
PRINT

' Multiply by 4
EXEC MUL4

' Calculate ATAN(1/239), negative:
PRINT "A(1/239):";
EXEC ARCTAN 0, 239
PRINT

' Multiply all by 4
EXEC MUL4

' Get calculation end time
ETIME=TIME

' Show our value of PI
EXEC SHOW

ETIME=ETIME-STIME
PRINT "Elapsed time: ";ETIME/60;" s"

END

'-------------------------------------
' Prints number on P()
'
PROC SHOW
 PRINT "PI=";P(0);".";
 FOR I=1 TO Q-1
  S=P(I)
  IF S<10
   PRINT "0";S;
  ELSE
   PRINT S;
  ENDIF
 NEXT
 PRINT
ENDPROC

'-------------------------------------
' Calculate ATAN(1/AT), adding the
' result to P()
'
PROC ARCTAN AS AT
 T(0)=1
 ZERO=0
 EXEC DIV AT
 EXEC SAVE_T
 N=1
 REPEAT
  EXEC ADDSUB
  EXEC RESTORE_T
  EXEC DIV AT
  EXEC DIV AT
  EXEC SAVE_T
  EXEC CHKZERO
  N=N+2
  EXEC DIV N
  PRINT ".";
 UNTIL ZERO<0
ENDPROC

'-------------------------------------
' Calculate ATAN(1/AT), with AT a small
' number (so that AT*AT*100 < 32768),
' adding the result to P().
'
PROC ARCTAN_SMALL AS AT
 T(0)=1
 ZERO=0
 EXEC DIV AT
 EXEC SAVE_T
 N=1
 AT=AT*AT
 REPEAT
  EXEC ADDSUB
  EXEC RESTORE_T
  N=N+2
  EXEC DIV AT
  EXEC CHKZERO
  EXEC SAVE_T
  EXEC DIV N
  PRINT ".";
 UNTIL ZERO<0
ENDPROC

'-------------------------------------
' ADDs or SUBs T() to P(), depending
' on AS.
'
PROC ADDSUB
 IF AS
  AS=0
  EXEC ADD
 ELSE
  AS=1
  EXEC SUB
 ENDIF
ENDPROC

'-------------------------------------
' Checks if T() is zero, to stop
' the series.
'
PROC CHKZERO
 ZERO=-1
 FOR I=0 TO Q
  IF T(I)
   ZERO=I
   EXIT
  ENDIF
 NEXT
ENDPROC

'-------------------------------------
' Adds T() to P(), so P()=P()+T()
'
PROC ADD
 FOR J=Q TO ZERO STEP -1
  S=P(J)+T(J)
  IF S>99
   INC P(J-1)
   S=S-100
  ENDIF
  P(J)=S
 NEXT
 FOR J=ZERO-1 TO 0 STEP -1
  S=P(J)
  IF S>99
   INC P(J-1)
   S=S-100
   P(J)=S
  ELSE
   EXIT
  ENDIF
 NEXT
ENDPROC

'-------------------------------------
' Subtract T() from P(), so P()=P()-T()
'
PROC SUB
 FOR J=Q TO ZERO STEP -1
  S=P(J)-T(J)
  IF S<0
   DEC P(J-1)
   S=S+100
  ENDIF
  P(J)=S
 NEXT
 FOR J=ZERO-1 TO 0 STEP -1
  S=P(J)
  IF S<0
   DEC P(J-1)
   S=S+100
   P(J)=S
  ELSE
   EXIT
  ENDIF
 NEXT
ENDPROC

'-------------------------------------
' Multiplies T() by the small number
' MULTI, only works if MULTI*100<32768
'
PROC MUL MULTI
 C=0
 FOR I=Q TO 0 STEP -1
  B = T(I) * MULTI + C
  T(I) = B MOD 100
  C = B / 100
 NEXT
ENDPROC

'-------------------------------------
' Divides T() by the small number DIVI,
' only works if DIVI*100<32768
'
PROC DIV DIVI
 C=0
 FOR I=ZERO TO Q
  B = 100 * C + T(I)
  T(I) = B / DIVI
  C = B MOD DIVI
 NEXT
ENDPROC

'-------------------------------------
' Divides P() by 4. UNUSED!
'
PROC DIV4
 C=0
 FOR I=0 TO Q
  B = 100 * C + P(I)
  D = B MOD 4
  P(I) = B / 4
 NEXT
ENDPROC

'-------------------------------------
' Multiplies P() by 4.
'
PROC MUL4
 C=0
 FOR I=Q TO 0 STEP -1
  B = P(I) * 4 + C
  C = B / 100
  P(I) = B MOD 100
 NEXT
ENDPROC

'-------------------------------------
' Saves the value of T
'
PROC SAVE_T
 MOVE ADR(T), ADR(SV), Q+1
ENDPROC

'-------------------------------------
' Restores the value of T
'
PROC RESTORE_T
 MOVE ADR(SV), ADR(T), Q+1
ENDPROC



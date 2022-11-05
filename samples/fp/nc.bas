' -- #FUJINET NETCAT Example --

' Default unit # for connection
CONN=2
MODE=12
TRANS=0

' RX Buffer
DIM BUF(8192) BYTE

' Procedures '''''''''''''''''''''''''
PROC BANNER
 PRINT "** NETCAT IN FASTBASIC **"
 PRINT
ENDPROC

PROC GETCONN
 URL$="N:"
 INPUT "URL: ", C$
 URL$=+C$
 INPUT "TRANS (0=none, 1=CR, 2=LF, 3=CR/LF): ", TRANS
ENDPROC

PROC INTCLR
 POKE $D302, PEEK($D302) & 127
ENDPROC

PROC CONNECT
 PRINT "Connecting to:"
 PRINT URL$
 NOPEN CONN,MODE,TRANS,URL$
 NSTATUS CONN
ENDPROC

PROC IN
 ' Clear interrupt and get status
 @INTCLR
 NSTATUS CONN

 ' Check if we need to read data
 BW = DPEEK($02EA)
 WHILE BW
  ' Needs to handle the case where
  ' BW > 32767, giving negative.
  IF BW > 8192 OR BW < 000
   LN = 8192
  ELSE
   LN = BW
  ENDIF

  NGET CONN,&BUF, LN
  BPUT #0, &BUF, LN
  BW = BW - LN
 WEND
ENDPROC

PROC OUT
 GET K
 NPUT CONN, &K, 1
ENDPROC

PROC NC
 DO
  IF PEEK($D302) & 128
   @IN
  ENDIF

  IF PEEK($02EC) = 0
   PRINT "Disconnected."
   NCLOSE CONN
   EXIT
  ENDIF

  IF KEY() THEN @OUT
 LOOP
ENDPROC

''''''''''''''''''''''''
' Main Program

POKE 65,0 ' quiet SIO

@BANNER
@GETCONN
@CONNECT

IF SErr() <> 1
  NSTATUS CONN
  PRINT "Could not Make Connection"
  PRINT "ERROR- "; PEEK($02ED)
  NCLOSE CONN
ELSE
  PRINT "Connected!"
  @NC
ENDIF

POKE 65,3 ' noisy SIO

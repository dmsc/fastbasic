' -- #FUJINET NETCAT Example --

' Default unit # for connection
CONN=2
MODE=12
TRANS=0

' URL for connection
URL$=""

' RX Buffer
DIM BUF(8192) BYTE

' Procedures '''''''''''''''''''''''''

PROC BANNER

PRINT "** NETCAT IN FASTBASIC **"$9B
ENDPROC

PROC GETCONN
  DO 

    INPUT "URL: ",URL$

    C$=URL$[1,2]

    IF C$="N:"
      EXIT
    ENDIF 

  LOOP

  INPUT "TRANS (0=none, 1=CR, 2=LF, 3=CR/LF): ",TRANS
  
ENDPROC

PROC INTCLR
  POKE $D302, PEEK($D302) & 127
ENDPROC

PROC CONNECT

  PRINT "Connecting to:"
  PRINT URL$

  NOPEN CONN,MODE,TRANS,URL$
  @INTCLR
  NSTATUS CONN
  
ENDPROC

PROC IN
  NSTATUS CONN
  BW = DPEEK($02EA)

  IF BW = 0
    EXIT
  ENDIF

  IF BW > 8192
    BW = 8192
  ENDIF 

  NGET CONN,&BUF,BW
  
  FOR I=0 TO BW-1
    PRINT CHR$(BUF(I));
  NEXT I
  
ENDPROC

PROC OUT
  GET K
  NPUT CONN,&K,1
  POKE $2FC,255
ENDPROC

PROC NC

  DO

    IF PEEK($D302) & 128
      @IN
      @INTCLR
    ENDIF
    
    IF PEEK($02EC) = 0
      PRINT "Disconnected."
      NCLOSE CONN
      EXIT
    ENDIF

    IF PEEK($02FC) <> 255
      @OUT
    ENDIF
    
  LOOP

ENDPROC

' Main Program '''''''''''''''''''''''

POKE 65,0

@BANNER
@GETCONN
@CONNECT

IF SErr() <> 1
  NSTATUS CONN
  PRINT "Could not Make Connection"
  PRINT "ERROR- ";PEEK($02ED)
  NCLOSE CONN
ELSE
  PRINT "Connected!"
  @NC
ENDIF

POKE 65,3


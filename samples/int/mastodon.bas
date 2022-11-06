' A Mastodon Client in FastBASIC

' N: Unit to use
unit=8

' URL to Mastodon Server
url$="N:HTTPS://oldbytes.space/api/v1/timelines/public?limit=1"$9B

' QUERY string
query$=""

' QUERY result
DIM result(1024) BYTE

' JSON channel mode
JSON_MODE=1

' PROCEDURES '''''''''''''''''''''''''

PROC nprinterror
   NSTATUS unit
   PRINT "ERROR- ";PEEK($02ED)
ENDPROC

PROC nsetchannelmode mode
   SIO $71, unit, $FC, $00, 0, $1F, 0, 12, JSON_MODE
ENDPROC

PROC nparsejson
   SIO $71, unit, $50, $00, 0, $1f, 0, 12, 0
ENDPROC

PROC njsonquery
   SIO $71, unit, $51, $80, &query$+1, $1f, 256, 12, 0 
ENDPROC

PROC showresult
   @njsonquery
   NSTATUS unit

   IF PEEK($02ED) > 128
      PRINT "Could not fetch query:"
      PRINT query$
      EXIT
   ENDIF

   BW=DPEEK($02EA)
   NGET unit,&result,BW
   BPUT #0,&result,BW
ENDPROC

PROC mastodon
     ' Open connection
     NOPEN unit, 12, 0, url$

     ' If not successful, then exit.
     IF SErr()<>1
     	PRINT "Could not open connection."
        @nprinterror
	EXIT
     ENDIF

     ' Change channel mode to JSON
     @nsetchannelmode JSON_MODE

     ' Ask FujiNet to parse JSON
     @nparsejson

     ' If not successful, then exit.
     IF SErr()<>1
       PRINT "Could not parse JSON."
       @nprinterror
       EXIT
     ENDIF

     ' Show latest post
     query$="N:/0/account/display_name"$9B
     @showresult
     query$="N:/0/created_at"$9B
     @showresult
     query$="N:/0/content"$9B 
     @showresult

     NCLOSE unit

     PRINT "" 
     PRINT " ---- "
     PRINT ""

ENDPROC

PROC waitabit
     TIMER
     DO 
        IF TIME > 1800
           EXIT
        ENDIF
     LOOP
ENDPROC

' MAIN PROGRAM '''''''''''''''''''''''

DO

  @mastodon
  @waitabit

LOOP

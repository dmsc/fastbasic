'
' A text editor in FastBasic - dmsc - 2017
' ----------------------------------------
'

' Allows "exit" to terminate
do

' Initializes E: device
close #0 : open #0, 12, 0, "E:"
poke @@LMARGN, $00
poke @KEYREP, 3

' M/L routines
data CountLines() byte = $68,$68,$AA,$68,$85,$FD,$68,$85,$FC,$68,$85,$FF,$68,$85,$FE,$E6,$FC,
data              byte = $E6,$FD,$A0,$00,$B1,$FE,$C6,$FC,$D0,$04,$C6,$FD,$F0,$0D,$E6,$FE,$D0,
data              byte = $02,$E6,$FF,$C9,$9B,$D0,$EC,$CA,$10,$E9,$A5,$FE,$A6,$FF,$60

' We store an array with the location of each block of 10 lines, for faster scrolling
dim LineAdr(256), ScrAdr(24), ScrLen(24)
' And an array with the current line being edited
dim EditBuf(256) byte

FileName$ = "D:HELP.TXT"

' MemStart if the start of available memory, used as a buffer for the file data
dim MemStart(0)

' Init pointers:
MemEnd = Adr(MemStart)
'  Logical cursor position (in the file):
line = 0    : column = 0
'  Screen cursor position:
scrLine = 0 : scrColumn = 0
'  Line at top of screen, divided by 8
hline = 0
'  Column at left of screen, and last "updated" column
hDraw = 0
'  Last updated line
lDraw = 0
'  Current line length
linLen = 0
'  Not currently editing a line
edited = 0

' Loads initial file
exec LoadFile
FileName$ ="D:UNTITLED.BAS"

escape = 0
do
  ' Key reading loop
  get key
  ' Special characters:
  '   27 ESC            ok
  '   28 UP             ok
  '   29 DOWN           ok
  '   30 LEFT           ok
  '   31 RIGHT          ok
  '  125 CLR SCREEN (shift-<) or (ctrl-<)
  '  126 BS CHAR        ok
  '  127 TAB
  '  155 CR             ok
  '  156 DEL LINE (shift-bs)   ok
  '  157 INS LINE (shift->)
  '  158 CTRL-TAB
  '  159 SHIFT-TAB
  '  253 BELL (ctrl-2)
  '  254 DEL CHAR (ctrl-bs)    ok
  '  255 INS CHAR (ctrl->)
  if (key<>$9B) and (escape or ( ((key & 127) >= $20) and ((key & 127) < 125)) )
    ' Process normal keys
    escape = 0
    if linLen > 126
      put @@ATBEL : ' ERROR, line too long
    else
      exec InsertChar
      inc column
      if linLen = column and scrColumn < peek(@@RMARGN)-1
        inc scrColumn
        poke @DSPFLG, 1
        put key
        poke @DSPFLG, 0
      else
        hDraw = -1
        exec DrawCurrentLine
      endif
    endif
  else
    '--------------------------------
    ' Keyboard handling
    '
    '--------- Return ---------------
    if key = $9B
      ' Ads an CR char and terminate current line editing.
      exec InsertChar
      exec SaveLine
      ' Split current line at this point
      ScrLen(scrLine) = column
      inc column
      newLen = linLen - column
      newPtr = ScrAdr(scrLine) + column
      ' Go to column 0
      column = 0
      ' Adjust all page pointers
      exec FillPagePointers
      if scrLine > 21
        scrLine = scrLine - 8
        inc hLine
        exec RedrawScreen
      else
        ' Redraw old line
        hDraw = 0
        y = scrLine
        ptr = ScrAdr(y)
        lLen = ScrLen(y)
        exec DrawLine
        ' Go to next line
        inc line
        inc scrLine
        ' Move screen down!
        pos. 0, scrLine+1
        poke @DSPFLG, 0
        put 157
        ' Adjust all screen pointers
        for y = 21 to scrLine step -2
          lLen = ScrLen(y)
          ptr  = ScrAdr(y)
          inc y
          ScrLen(y) = lLen
          ScrAdr(y) = ptr
        next y
        ' Save new line position
        inc y
        ScrAdr(y) = newPtr
        ScrLen(y) = newLen
        lDraw = y
        hDraw = -1
        exec ChgLine
      endif
    '
    '--------- Delete Line ----------
    elif key = 156
      ' Go to beginning of line
      column = 0
      ' Delete line from screen
      pos. 0, scrLine+1
      poke @DSPFLG, 0
      put 156
      ' Delete from entire file!
      ptr = ScrAdr(scrLine)
      nptr = ptr + ScrLen(scrLine) + 1
      move nptr, ptr, MemEnd - nptr
      MemEnd = MemEnd - nptr + ptr
      ' Redraw screen
      exec FillPagePointers
      if LineAdr(hline) = 0
        hline = hline - 1
        scrLine = scrLine + 9
        exec RedrawScreen
      else
        nptr = ScrAdr(scrLine)
        for y = scrLine to 22
          ptr = nptr
          nptr = USR(adr(CountLines), ptr, MemEnd - ptr, 0)
          lLen = nptr - ptr - 1
          ScrLen(y) = lLen
          ScrAdr(y) = ptr
          if y = scrLine
            exec DrawLine
          endif
        next y
        edited = 0
        hDraw = -1
        lDraw = 22
        exec ChgLine
      endif
    '
    '--------- Backspace ------------
    elif key = 126
      if column > 0
        column = column - 1
        exec DeleteChar
      endif
    '
    '--------- Del Char -------------
    elif key = 254
      if column < linLen
        exec DeleteChar
      endif
    '
    '--------- Control-E (END) ------
    elif key = $05
      column = linLen
      exec DrawCurrentLine
    '
    '--------- Control-A (HOME) -----
    elif key = $01
      column = 0
      exec DrawCurrentLine
    '
    '--------- Left -----------------
    elif key = $1F
      if column < linLen
        inc column
        if scrColumn < peek(@@RMARGN)-1
          inc scrColumn
          put key
        else
          exec DrawCurrentLine
        endif
      endif
    '
    '--------- Right ----------------
    elif key = $1E
      if column > 0
        column = column - 1
        if scrColumn > 1
          scrColumn = scrColumn - 1
          put key
        else
          exec DrawCurrentLine
        endif
      endif
    '
    '--------- Control-U (page up)---
    elif key = $15
      hline = hline - 2
      scrLine = 0
      exec RedrawScreen
    '
    '--------- Control-V (page down)-
    elif key = $16
      hline = hline + 2
      scrLine = 22
      exec RedrawScreen
    '
    '--------- Down -----------------
    elif key = $1D
      if linLen >= 0
        if scrLine < 22
          inc line
          inc scrLine
          exec ChgLine
        else
          inc hline
          scrLine = scrLine - 8
          exec RedrawScreen
        endif
      endif
    '
    '--------- Up -------------------
    elif key = $1C
      if line > 0
        if scrLine > 0
          line = line - 1
          scrLine = scrLine - 1
          exec ChgLine
        else
          hline = hline - 1
          scrLine = scrLine + 8
          exec RedrawScreen
        endif
      endif
    '
    '--------- Control-Q (exit) -----
    elif key = $11
      exec SaveLine
      exec AskSaveFile
      exit
    '
    '--------- Control-S (save) -----
    elif key = $13
      exec SaveLine
      exec AskSaveFile
      exec ShowInfo
    '
    '--------- Control-R (run) -----
    elif key = $12
      exec SaveLine
      ' Compile main file
      poke MemEnd, $9B
      pos. 1,0
      ? "úù Parsing:";
      pos. 11,0
      line = USR( @compile_buffer, Adr(MemStart), MemEnd ) - 1
      column = peek( @@bmax )
      get key
      hLine = line / 10
      scrLine = line mod 10
      exec RedrawScreen
    '
    '--------- Control-N (new) -----
    elif key = $0E
      exec AskSaveFile
      FileName$="D:"
      MemEnd = Adr(MemStart)
      exec FillPagePointers
      column = 0
      line = 0
      scrLine = 0
      exec RedrawScreen
    '
    '--------- Control-L (load) -----
    elif key = $0C
      poke @DSPFLG, 0
      pos. 0, 0
      ? "úù Load?";
      exec InputFileName
      if key = 155
        exec LoadFile
      else
        exec ShowInfo
      endif
    '
    '--------- Control-Z (undo) -----
    elif key = $1A
      if edited
        edited = 0
        hDraw = -1
        exec CopyToEdit
        exec DrawCurrentLine
      else
        put @@ATBEL
      endif
    '
    '--------- Escape ---------------
    elif key = $1B
      escape = 1
    else
      ' Unknown Control Key
    endif
  endif
loop

exit
loop

'-------------------------------------
' Insert a character over the cursor
'
PROC InsertChar
  edited = line + 1
  inc linLen
  ptr = Adr(EditBuf) + column
  -move ptr, ptr+1, linLen - column
  poke ptr, key
ENDPROC

'-------------------------------------
' Deletes the character over the cursor
'
PROC DeleteChar
  edited = line + 1
  linLen = linLen - 1
  ptr = Adr(EditBuf) + column
  move ptr+1, ptr, linLen - column
  hDraw = -1
  exec DrawCurrentLine
ENDPROC

'-------------------------------------
' Save line being edited
'
PROC SaveLine
  if edited
    ' Move file memory to make room for new line
    ptr  = ScrAdr(lDraw)
    llen = ScrLen(lDraw)
    dif  = linLen - llen
    nptr = ptr + linLen
    ptr = ptr + llen
    if nptr < ptr
      move  ptr, nptr, MemEnd - ptr
    elif nptr > ptr
      -move ptr, nptr, MemEnd - ptr
    endif
    MemEnd = MemEnd + dif
    ' Copy new line
    ptr  = ScrAdr(lDraw)
    move Adr(EditBuf), ptr, linLen
    ' Adjust all pointers
    ScrLen(lDraw) = linLen
    for y = (edited + 11) / 10 to 255
      if LineAdr(y)
        LineAdr(y) = LineAdr(y) + dif
      else
        Exit
      endif
    next y
    for y = lDraw + 1 to 22
      ScrAdr(y) = ScrAdr(y) + dif
    next y
    ' End
    edited = 0
  endif
ENDPROC

'-------------------------------------
' Copy current line to edit buffer
'
PROC CopyToEdit
  linPtr = ScrAdr(scrLine)
  linLen = ScrLen(scrLine)

  ' Get column in range
  if column > linLen
    if linLen >= 0
      column = linLen
    else
      column = 0
    endif
  endif

  ' Copy line to 'Edit' buffer, if not too long
  if linLen > 127
    linLen = 127
  endif
  if linLen > 0
    move linPtr, Adr(EditBuf), linLen
  else
    poke Adr(EditBuf), $9b
  endif
ENDPROC

'-------------------------------------
' Change current line.
'
PROC ChgLine

  exec SaveLine

  ' Restore last line, if needed
  if hDraw <> 0
    y = lDraw
    ptr = ScrAdr(y)
    lLen = ScrLen(y)
    hDraw = 0
    exec DrawLine
  endif

  ' Keep new line in range
  while ScrLen(scrLine) < 0
    line = line - 1
    scrLine = scrLine - 1
  wend

  exec CopyToEdit

  ' Print status
  pos. 35, 0 : ? line;
  put $12

  ' Redraw line
  hDraw = 0
  exec DrawCurrentLine

ENDPROC

proc PutBlanks
  for max = max to 1 step -1 : put 32 : next max
endproc

'-------------------------------------
' Draws line 'Y' scrolled by hDraw
'
PROC DrawLine

  poke @DSPFLG, 1
  poke @CRSINH, 1

  pos. 0, y+1
  ptr = ptr + hdraw
  max = peek(@@RMARGN) - 1
  if lLen < 0
    put $FD
    exec PutBlanks
    poke @@OLDCHR, $00
  else
    if hDraw
      lLen = lLen - hDraw
      put $9E
    else
      inc max
    endif

    if lLen > max
      bput #0, ptr, max
      poke @@OLDCHR, $DF
    else
      if lLen > 0
        bput #0, ptr, lLen
      endif
      if lLen < max
        max = max - lLen
        exec PutBlanks
      endif
      poke @@OLDCHR, $00
    endif
  endif
ENDPROC

'-------------------------------------
' Draws current line from edit buffer
' and move cursor to current position
'
PROC DrawCurrentLine

  hColumn = 0
  scrColumn = column

  while scrColumn >= peek(@@RMARGN)
    hColumn = hColumn + 8
    scrColumn = column - hColumn + 1
  wend

  if hDraw <> hColumn

    hDraw = hColumn
    y = scrLine
    ptr = Adr(EditBuf)
    lLen = linLen
    exec DrawLine

  endif
  lDraw = scrLine

  poke @DSPFLG, 0
  poke @CRSINH, 0
  pos. scrColumn, scrLine
  put 29
ENDPROC

'-------------------------------------
' Redraws entire screen
'
PROC RedrawScreen

  exec SaveLine

  ' Get new current line
  while LineAdr(hline) = 0
    hline = hline - 1
  wend
  if hline < 0
    hline = 0
  endif
  line = 10 * hline + scrLine

  ' Print screen
  poke @CRSINH, 1
  poke @DSPFLG, 0
  put 125
  exec ShowInfo
  ptr = LineAdr(hline)
  hdraw = 0
  y = 0
  while y < 23
    nptr = USR(adr(CountLines), ptr, MemEnd - ptr, 0)
    lLen = nptr - ptr - 1
    ScrLen(y) = lLen
    ScrAdr(y) = ptr
    exec DrawLine
    ptr = nptr
    inc y
  wend
  exec ChgLine
ENDPROC

'-------------------------------------
' Prints line info and changes line
'
PROC ShowInfo
  pos. 0, 0
  for max=1 to peek(@@RMARGN) : put $12 : next max
  poke @@OLDCHR, $52
  pos. 2, 0 : ? FileName$;"(";MemEnd-Adr(MemStart);")";
  pos. scrColumn, scrLine
  put 29
ENDPROC

'-------------------------------------
' Calculate all page pointers
'
PROC FillPagePointers
  ptr = adr(MemStart)
  if MemEnd = ptr
    poke ptr, $9b
    MemEnd = MemEnd + 1
  endif
  y = 0
  while ptr <> MemEnd and y < 255
    LineAdr(y) = ptr
    inc y
    ptr = USR(adr(CountLines), ptr, MemEnd - ptr, 9)
  wend
  ' Fill two more slots with 0 to signal end of file
  LineAdr(y) = 0
  inc y
  LineAdr(y) = 0
ENDPROC

'-------------------------------------
' Gets a filename with minimal line editing
'
PROC InputFilename
  ' Show current filename:
  pos. 6, 0: ? FileName$;
  do
    get key
    if key = 27
      exit
    elif key = 155
      pos. 6, 0
      poke @CH, 12: ' Force ENTER
      input #0, FileName$
      exit
    elif key >= 30 and key <= 124 or key = 126
      put key
    endif
  loop
ENDPROC

'-------------------------------------
' Shows file error
'
PROC FileError
  pos. 1,0
  ? "ERROR: "; err(); " (press any key)";
  put @@ATBEL
  close #1
  get key
ENDPROC

'-------------------------------------
' Save edited file
'
PROC AskSaveFile
  poke @DSPFLG, 0
  pos. 0, 0
  ? "úù Save?";
  exec InputFileName
  if key <> 155
    ' Don't save
    exit
  endif

  open #1, 8, 0, FileName$
  if err() < 128
    ' Open ok, write dile
    bput #1, Adr(MemStart), MemEnd - Adr(MemStart)
    if err() < 128
      ' Save ok, close
      close #1
      if err() < 128 then Exit
    endif
  endif

  exec FileError
ENDPROC

'-------------------------------------
' Save edited file
'
PROC LoadFile

  open #1, 4, 0, FileName$
  if err() < 128
    bget #1, Adr(MemStart), fre()
    if err() = 136
      MemEnd = dpeek($358) + adr(MemStart)
      close #1
    endif
  endif

  if err() > 127
    exec FileError
  endif

  exec FillPagePointers
  column = 0
  line = 0
  scrLine = 0
  edited = 0
  exec RedrawScreen

ENDPROC


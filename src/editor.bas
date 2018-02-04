'
' A text editor in FastBasic - dmsc - 2017
' ----------------------------------------
'

'-------------------------------------
' Array definitions
dim ScrAdr(24), ScrLen(24)
' And an array with the current line being edited
dim EditBuf(128) byte

' We start with the help file.
FileName$ = "D:HELP.TXT"

' MemStart: the start of available memory, used as a buffer for the file data
dim MemStart(0)
' MemEnd: the end of the current file, initialized to MemStart.
MemEnd = Adr(MemStart)

' NOTE: variables already are initialized to '0' in the runtime.
' line:
' column:       Logical cursor position (in the file)
' scrLine:
' scrColumn:    Cursor position in the screen
' hDraw:        Column at left of screen, and last "updated" column
' lDraw:        Number of the line last drawn, and being edited.
' linLen:       Current line length.
' edited:       0 if not currently editing a line
' ScrAdr():     Address in the file of screen line
' ScrLen():     Length of screen line


'-------------------------------------
' Shows file error
'
PROC FileError
  pos. 1,0
  ? "ERROR: "; err(); " (press any key)˝";
  close #1
  get key
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
      key = 0
      exit
    elif key >= 30 and key <= 124 or key = 126
      put key
    endif
  loop
ENDPROC

'-------------------------------------
' Save compiled file
'
PROC SaveCompiledFile
  ' Save original filename
  move Adr(FileName$), Adr(EditBuf), 128
  poke Adr(FileName$) + Len(FileName$), $58

  pos. 0, 0
  ? "úù Name?";
  exec InputFileName
  if key
    ' Don't save
    exit
  endif

  open #1, 8, 0, FileName$
  if err() < 128
    ' Open ok, write header
    bput #1, @COMP_HEAD_1, 6
    bput #1, @@__INTERP_START__, @@__INTERP_SIZE__
    bput #1, @COMP_HEAD_2, 4
    bput #1, @__JUMPTAB_RUN__, @COMP_RT_SIZE
    bput #1, MemEnd + 1, dpeek(@COMP_END) - MemEnd
    if err() < 128
      bput #1, @COMP_TRAILER, 6
      ' Save ok, close
      close #1
    endif
  endif

  if err() > 127
    exec FileError
  endif

  ' Restore original filename
  move Adr(EditBuf), Adr(FileName$), 128
ENDPROC

'-------------------------------------
' Save edited file
'
PROC AskSaveFile
  exec SaveLine
  pos. 0, 0
  ? "úù Save?";
  exec InputFileName
  if key
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
' Load file into editor
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

  column = 0
  line = 0
  scrLine = 0
  edited = 0
  exec RedrawScreen

ENDPROC

'-------------------------------------
' Compile (and run) file
PROC CompileFile
  ' Compile main file
  exec SaveLine
  poke MemEnd, $9B
  pos. 1,0
  ? "úù Parsing: ";
  if USR( @compile_buffer, key, Adr(MemStart), MemEnd+1)
    ' Parse error, go to error line
    line = dpeek(@@linenum) - 1
    column = peek( @@bmax )
    if line < 10
      scrLine = line
    else
      scrLine = 10
    endif
    get key
  elif key
    exec SaveCompiledFile
  else
    get key
  endif
  line = line - scrLine
  exec InitScreen
  exec RedrawScreen
ENDPROC

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
  exec ForceDrawCurrentLine
ENDPROC

'-------------------------------------
' Draws current line from edit buffer
' and move cursor to current position
'
PROC ForceDrawCurrentLine
  hDraw = -1
  exec DrawCurrentLine
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
    exec DrawLinePtr

  endif
  lDraw = scrLine

  pos. scrColumn, scrLine
  put 29
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
    exec DrawLineOrig
  endif

  ' Keep new line in range
  while ScrLen(scrLine) < 0
    line = line - 1
    scrLine = scrLine - 1
  wend

  exec CopyToEdit

  ' Print status
  pos. 32, 0 : ? line;
  put $12

  ' Redraw line
  hDraw = 0
  exec DrawCurrentLine

ENDPROC

proc PutBlanks
  for max = max to 1 step -1 : put 32 : next max
endproc

'-------------------------------------
' Draws line 'Y' from file buffer
'
PROC DrawLineOrig
  ptr = ScrAdr(y)
  lLen = ScrLen(y)
  hDraw = 0
  exec DrawLinePtr
ENDPROC

'-------------------------------------
' Draws line 'Y' scrolled by hDraw
' with data from ptr and lLen.
'
PROC DrawLinePtr

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

  poke @DSPFLG, 0
  poke @CRSINH, 0

ENDPROC

'-------------------------------------
' Prints line info and changes line
'
PROC ShowInfo
  pos. 0, 0
  for max=1 to peek(@@RMARGN) : put $12 : next max
  poke @@OLDCHR, $52
  pos. 2, 0 : ? FileName$;
  pos. scrColumn, scrLine
  put 29
ENDPROC

'-------------------------------------
' Scrolls screen Down (like page-up)
PROC ScrollDown
  ' Don't scroll if already at beginning of file
  if Adr(MemStart) = ScrAdr(0) then Exit

  ' Scroll screen image inserting a line
  poke @CRSINH, 1
  pos. 0, 1
  put 157
  ' Move screen pointers
  -move adr(ScrLen), adr(ScrLen)+2, 44
  -move adr(ScrAdr), adr(ScrAdr)+2, 44
  ' Get first screen line by searching last '$9B'
  llen = 0
  for ptr = ScrAdr(0) - 2 to Adr(MemStart) step -1
    if peek(ptr) = $9B then Exit
  next ptr
  inc ptr
  ScrLen(0) = ScrAdr(0) - ptr - 1
  ScrAdr(0) = ptr

  ' Adjust line
  dec line

  ' Draw first line
  y = 0
  exec DrawLineOrig

ENDPROC

'-------------------------------------
' Calls 'CountLines
PROC CountLines
  nptr = USR(@Count_Lines, ptr, MemEnd - ptr)
ENDPROC

'-------------------------------------
' Scrolls screen Up (like page-down)
PROC ScrollUp
  ' Don't scroll if already in last position
  if MemEnd = ScrAdr(1) then Exit

  ' Scroll screen image deleting the first line
  poke @CRSINH, 1
  pos. 0, 1
  put 156
  ' Move screen pointers
  move adr(ScrLen)+2, adr(ScrLen), 44
  move adr(ScrAdr)+2, adr(ScrAdr), 44

  ' Get last screen line length by searching next EOL
  ptr = ScrAdr(22) + ScrLen(22) + 1
  exec CountLines
  ScrAdr(22) = ptr
  ScrLen(22) = nptr - ptr - 1

  ' Draw last line
  y = 22
  exec DrawLineOrig
ENDPROC

'-------------------------------------
' Moves the cursor down 1 line
PROC CursorDown
  if scrLine = 22
    exec SaveLine
    exec ScrollUp
  else
    inc scrLine
  endif
  inc line
ENDPROC

'-------------------------------------
' Moves the cursor up 1 line
PROC CursorUp
  if scrLine
    dec scrLine
    dec line
  else
    exec SaveLine
    exec ScrollDown
  endif
ENDPROC

'-------------------------------------
' Redraws entire screen
'
PROC RedrawScreen

  exec CheckEmptyBuf

  ' Search given line
  ptr = Adr(MemStart)
  for y=1 to line
   exec CountLines
   if nptr = MemEnd
     '  Line is outside of current file, go to last line
     line = y - 1
     exit
   endif
   ptr = nptr
  next y

  ' Draw all screen lines
  put 125
  exec ShowInfo
  hdraw = 0
  y = 0
  while y < 23
    exec CountLines
    lLen = nptr - ptr - 1
    ScrLen(y) = lLen
    ScrAdr(y) = ptr
    exec DrawLinePtr
    ptr = nptr
    inc y
  wend

  line = line + scrLine

  exec ChgLine
ENDPROC

'-------------------------------------
' Fix empty buffer
PROC CheckEmptyBuf
  if MemEnd = adr(MemStart)
    poke adr(MemStart), $9b
    MemEnd = MemEnd + 1
  endif
ENDPROC

'-------------------------------------
' Initializes E: device
PROC InitScreen
  close #0 : open #0, 12, 0, "E:"
  poke @@LMARGN, $00
  poke @KEYREP, 3
ENDPROC

'-------------------------------------
' Main Program
'

' Loads initial file, and change the filename
exec InitScreen
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
        exec ForceDrawCurrentLine
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
      ' Scroll screen if we are in the last line
      if scrLine > 21
        exec ScrollUp
        dec scrLine
      endif
      ' Redraw old line
      hDraw = 0
      y = scrLine
      exec DrawLineOrig
      ' Go to next line
      inc line
      inc scrLine
      ' Move screen down!
      poke @CRSINH, 1
      pos. 0, scrLine+1
      put 157
      ' Move screen pointers
      -move Adr(ScrLen) + scrLine * 2, Adr(ScrLen) + (scrLine+1) * 2, (22 - scrLine) * 2
      -move Adr(ScrAdr) + scrLine * 2, Adr(ScrAdr) + (scrLine+1) * 2, (22 - scrLine) * 2
      ' Save new line position
      ScrAdr(scrLine) = newPtr
      ScrLen(scrLine) = newLen
      lDraw = scrLine
      hDraw = -1
      exec ChgLine
    '
    '--------- Delete Line ----------
    elif key = 156
      ' Go to beginning of line
      column = 0
      ' Delete line from screen
      poke @CRSINH, 1
      pos. 0, scrLine+1
      put 156
      ' Delete from entire file!
      ptr = ScrAdr(scrLine)
      nptr = ptr + ScrLen(scrLine) + 1
      move nptr, ptr, MemEnd - nptr
      MemEnd = MemEnd - nptr + ptr
      exec CheckEmptyBuf
      ' Scroll screen if we are in the first line
      if scrLine = 0 and ptr = MemEnd
        exec ScrollDown
      endif
      nptr = ScrAdr(scrLine)
      for y = scrLine to 22
        ptr = nptr
        exec CountLines
        ScrLen(y) = nptr - ptr - 1
        ScrAdr(y) = ptr
      next y
      y = scrLine
      exec DrawLineOrig
      edited = 0
      lDraw = 22
      hDraw = -1
      exec ChgLine
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
      for i=0 to 18
        exec CursorUp
      next i
      exec ChgLine
    '
    '--------- Control-V (page down)-
    elif key = $16
      for i=0 to 18
        exec CursorDown
      next i
      exec ChgLine
    '
    '--------- Down -----------------
    elif key = $1D
      exec CursorDown
      exec ChgLine
    '
    '--------- Up -------------------
    elif key = $1C
      exec CursorUp
      exec ChgLine
    '
    '--------- Control-Q (exit) -----
    elif key = $11
      exec AskSaveFile
      put 125
      end
    '
    '--------- Control-S (save) -----
    elif key = $13
      exec AskSaveFile
      exec ShowInfo
    '
    '--------- Control-R (run) -----
    elif key = $12
      key = 0
      exec CompileFile
    '
    '--------- Control-W (write compiled file) -----
    elif key = $17
      key = 1
      exec CompileFile
    '
    '--------- Control-N (new) -----
    elif key = $0E
      exec AskSaveFile
      FileName$="D:"
      MemEnd = Adr(MemStart)
      poke MemEnd, $9B
      column = 0
      line = 0
      scrLine = 0
      exec RedrawScreen
    '
    '--------- Control-L (load) -----
    elif key = $0C
      pos. 0, 0
      ? "úù Load?";
      exec InputFileName
      if key
        exec ShowInfo
      else
        exec LoadFile
      endif
    '
    '--------- Control-Z (undo) -----
    elif key = $1A
      if edited
        edited = 0
        exec CopyToEdit
        exec ForceDrawCurrentLine
      else
        put @@ATBEL
      endif
    '
    '--------- Escape ---------------
    elif key = $1B
      escape = 1
   'else
      ' Unknown Control Key
    endif
  endif
loop

' vi:syntax=tbxl

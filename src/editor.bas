'
' FastBasic - Fast basic interpreter for the Atari 8-bit computers
' Copyright (C) 2017-2020 Daniel Serpell
'
' This program is free software; you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation, either version 2 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License along
' with this program.  If not, see <http://www.gnu.org/licenses/>
'
' In addition to the permissions in the GNU General Public License, the
' authors give you unlimited permission to link the compiled version of
' this file into combinations with other programs, and to distribute those
' combinations without any restriction coming from the use of this file.
' (The General Public License restrictions do apply in other respects; for
' example, they cover modification of the file, and distribution when not
' linked into a combine executable.)


' A text editor / IDE in FastBasic
' --------------------------------
'

'-------------------------------------
' Array definitions
dim ScrAdr(24)
' And an array with the current line being edited
''NOTE: Use page 6 ($600 to $6FF) to free memory instead of a dynamic array
'dim EditBuf(256) byte
EditBuf = $600

' We start with the help file.
FileName$ = "D:HELP.TXT"

' MemStart: the start of available memory, used as a buffer for the file data
dim MemStart(-1) byte
' MemEnd: the end of the current file, initialized to MemStart.
MemEnd = Adr(MemStart)

' NOTE: variables already are initialized to '0' in the runtime.
' topLine:      Line at the top of the screen
' column:       Logical cursor position (in the file)
' scrLine:      Cursor line in the acreen
' scrColumn:    Cursor column in the screen
' hDraw:        Column at left of screen, and last "updated" column
' lDraw:        Number of the line last drawn, and being edited.
' linLen:       Current line length.
' edited:       0 if not currently editing a line
' ScrAdr():     Address in the file of screen line

'-------------------------------------
' Main Program
'

' Loads initial file, and change the filename
exec InitScreen
exec LoadFile
FileName$ ="D:"

' escape = 0  ' already initialized to 0
do
  ' Key reading loop
  exec ProcessKeys
loop



'-------------------------------------
' Gets a filename with minimal line editing
'
PROC InputFilename
  ' Show current filename:
  ? "? "; FileName$;
  do
    get key
    if key <= 27
      exit
    elif key = 155
      pos. 6, 0
      poke @CH, 12: ' Force ENTER
      input ; FileName$
      key = 0
      exit
    elif key >= 30 and key <= 124 or key = 126
      put key
    endif
  loop
  exec ShowInfo
ENDPROC

'-------------------------------------
' Compile (and run) file
PROC CompileFile
  ' Compile main file
  exec SaveLine
  poke MemEnd, $9B
  pos. 1,0
  ? "úùParsing: ";
  if USR( @compile_buffer, key, Adr(MemStart), MemEnd+1)
    ' Parse error, go to error line
    topLine = dpeek(@@linenum) - 11
    column = peek( @@bmax )
    scrLine = 10
    if topLine < 0
      scrLine = scrLine + topLine
      topLine = 0
    endif
    get key
  elif key
    exec SaveCompiledFile
  else
    get key
    sound
    exec InitScreen
  endif
  exec CalcRedrawScreen
ENDPROC

'-------------------------------------
' Deletes the character over the cursor
'
PROC DeleteChar
  fileSaved = 0
  edited = 1
  linLen = linLen - 1
  move 1 + EditBuf + column, EditBuf + column, linLen - column
  exec ForceDrawCurrentLine
ENDPROC

'-------------------------------------
' Draws current line from edit buffer
' and move cursor to current position
'
PROC ForceDrawCurrentLine
  hDraw = 1
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
    scrColumn = 1 + column - hColumn
  wend

  if hDraw <> hColumn

    hDraw = hColumn
    y = scrLine
    ptr = EditBuf
    lLen = linLen
    exec DrawLinePtr

  endif
  lDraw = scrLine

  pos. scrColumn, scrLine
  put 29
ENDPROC

'-------------------------------------
' Insert a character over the cursor
'
PROC InsertChar
  fileSaved = 0
  edited = 1
  ptr = EditBuf + column
  -move ptr, ptr+1, linLen - column
  poke ptr, key
  inc linLen
ENDPROC

'-------------------------------------
' Undo editing current line
PROC UndoEditLine
  edited = 0
  put @@ATBEL
  exec CopyToEdit
  exec ForceDrawCurrentLine
ENDPROC

'-------------------------------------
' Save line being edited
'
PROC SaveLine
  if edited
    ' Move file memory to make room for new line
    nptr = ScrAdr(lDraw) + linLen
    ptr = ScrAdr(lDraw+1) - 1
    newPtr = nptr - ptr

    ' Check if we have enough space in the buffer for the new file
    ' TODO: This check will fail if the buffer is bigger than 32kB,
    '       because the right side will be negative.
    if newPtr > dpeek(@MEMTOP) - MemEnd
      exec UndoEditLine
      exit
    endif

    MemEnd = MemEnd + newPtr
    if newPtr < 0
      move  ptr, nptr, MemEnd - nptr
    elif newPtr > 0
      -move ptr, nptr, MemEnd - nptr
    endif

    ' Copy new line
    move EditBuf, ScrAdr(lDraw), linLen
    ' Adjust all pointers
    y = lDraw
    repeat
      inc y
      ScrAdr(y) = ScrAdr(y) + newPtr
    until y > 22
    ' End
    edited = 0
  endif
ENDPROC

'-------------------------------------
' Copy current line to edit buffer
'
PROC CopyToEdit
  ptr = ScrAdr(scrLine)
  linLen = ScrAdr(scrLine+1) - ptr - 1

  ' Get column in range
  if column > linLen
    column = linLen
    if linLen < 0
      column = 0
    endif
  endif

  ' Copy line to 'Edit' buffer, if not too long
  if linLen > 255
    linLen = 255
  endif
  if linLen > 0
    move ptr, EditBuf, linLen
  else
    poke EditBuf, $9b
  endif
ENDPROC

'-------------------------------------
' Save edited file
'
PROC AskSaveFile
  exec SaveLine
  pos. 0, 0
  ? "úùSave";
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
      if err() < 128
        fileSaved = 1
        Exit
      endif
    endif
  endif

  exec FileError
ENDPROC

'-------------------------------------
' Shows file error
'
PROC FileError
  pos. 0,0
  ? err(); " ERROR, press a key˝";
  close #1
  get key
  exec ShowInfo
ENDPROC

'-------------------------------------
' Prints line info and changes line
'
PROC ShowInfo
  ' Print two "-", then filename, then complete with '-' until right margin
  pos. 0, 0 : ? "";
  ? FileName$;
  repeat : put $12 : until peek(@@RMARGN) = peek(@@COLCRS)
  ' Fill last character
  poke @@OLDCHR, $52
  ' Go to cursor position
  pos. scrColumn, scrLine
  put 29
ENDPROC

'-------------------------------------
' Ask to save a file if it is changed
' from last save.
PROC AskSaveFileChanged
  key = 0
  while not fileSaved
   exec AskSaveFile
   ' ESC means "don't save, cancel operation"
   if key = 27
     exit
   endif
   ' CONTROL-C means "don't save, lose changes"
   if key = 3
     key = 0
     exit
   endif
  wend
ENDPROC

'-------------------------------------
' Moves the cursor down 1 line
PROC CursorDown
  exec SaveLine
  if scrLine = 22
    exec ScrollUp
  else
    inc scrLine
  endif
ENDPROC

'-------------------------------------
' Moves the cursor up 1 line
PROC CursorUp
  exec SaveLine
  if scrLine
    dec scrLine
  else
    exec ScrollDown
  endif
ENDPROC

'-------------------------------------
' Scrolls screen Down (like page-up)
PROC ScrollDown
  ' Don't scroll if already at beginning of file
  if not topLine then Exit

  ' Scroll screen image inserting a line
  poke @CRSINH, 1
  pos. 0, 1
  put 157
  ' Move screen pointers
  -move adr(ScrAdr), adr(ScrAdr)+2, 46
  ' Get first screen line by searching last '$9B'
  ptr = ScrAdr(0) - 1
  while ptr <> Adr(MemStart) and peek(ptr-1) <> $9B
    dec ptr
  wend
  ScrAdr(0) = ptr

  ' Adjust top line
  dec topLine

  ' Draw first line
  y = 0
  exec DrawLineOrig

ENDPROC

'-------------------------------------
' Draws line 'Y' from file buffer
'
PROC DrawLineOrig
  ptr = ScrAdr(y)
  lLen = ScrAdr(y+1) - ptr - 1
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
      max = max - lLen
      exec PutBlanks
      poke @@OLDCHR, $00
    endif
  endif

  poke @DSPFLG, 0
  poke @CRSINH, 0

ENDPROC

proc PutBlanks
  while max : put 32 : dec max : wend
endproc


'-------------------------------------
' Calls 'CountLines
PROC CountLines
' This code is too slow in FastBasic, so we use machine code
'  nptr = ptr
'  while nptr <> MemEnd
'    inc nptr
'    if peek(nptr-1) = $9b then exit
'  wend
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
  move adr(ScrAdr)+2, adr(ScrAdr), 46

  ' Increment top-line
  inc topLine

  ' Get last screen line length by searching next EOL
  ptr = ScrAdr(23)
  exec CountLines
  ScrAdr(23) = nptr

  ' Draw last line
  y = 22
  exec DrawLineOrig
ENDPROC

'-------------------------------------
' Load file into editor
'
PROC LoadFile

  MemEnd = adr(MemStart)
  open #1, 4, 0, FileName$
  if err() < 128
    bget #1, Adr(MemStart), dpeek(@MEMTOP) - Adr(MemStart)
  endif

  ' Load ok only if error = 136 (EOF found)
  if err() = 136
    MemEnd = dpeek($358) + adr(MemStart)
  else
    exec FileError
  endif
  close #1

  exec RedrawNewFile
ENDPROC

'-------------------------------------
' Redraw screen after new file
'
PROC RedrawNewFile
  fileSaved = 1
  column = 0
  topLine = 0
  scrLine = 0
  exec CalcRedrawScreen
ENDPROC

'-------------------------------------
' Calculate screen start and redraws entire screen
'
PROC CalcRedrawScreen

  exec CheckEmptyBuf

  ' Search given line
  ptr = Adr(MemStart)
  y = 0
  while y < topLine
   exec CountLines
   if nptr = MemEnd
     '  Line is outside of current file, go to last line
     topLine = y
     exit
   endif
   ptr = nptr
   inc y
  wend

  ScrAdr(0) = ptr
  exec RedrawScreen
ENDPROC

'-------------------------------------
' Redraws entire screen
'
PROC RedrawScreen
  ' Draw all screen lines
  cls
  exec ShowInfo
  hdraw = 0
  y = 0
  ptr = ScrAdr(0)
  while y < 23
    exec CountLines
    lLen = nptr - ptr - 1
    exec DrawLinePtr
    ptr = nptr
    inc y
    ScrAdr(y) = ptr
  wend

  exec ChgLine
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
  while scrLine and ScrAdr(scrLine) = MemEnd
    scrLine = scrLine - 1
  wend

  exec CopyToEdit

  ' Print status
  pos. 32, 0 : ? 1 + topLine + scrLine;
  put $12

  ' Redraw line
  hDraw = 0
  exec DrawCurrentLine

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
' RETURN key, splits line at position
'
PROC ReturnKey
  ' Ads an CR char and terminate current line editing.
  exec InsertChar
  exec SaveLine
  ' Scroll screen if we are in the last line
  if scrLine > 21
    exec ScrollUp
    dec scrLine
  endif
  ' Split current line at this point
  newPtr = ScrAdr(scrLine) + column + 1

  ' Save current screen line
  y = scrLine

  ' Go to next line
  inc scrLine

  ' Move screen pointers
  ptr = adr(ScrAdr) + scrLine * 2
  -move ptr, ptr + 2, (23 - scrLine) * 2
  ' Save new line position
  dpoke ptr, newPtr

  ' Go to column 0
  column = 0

  ' Redraw old line up to the new EOL
  hDraw = 0
  exec DrawLineOrig

  ' Move screen down!
  poke @CRSINH, 1
  pos. 0, scrLine + 1
  put 157

  ' And redraw new line to be edited
  lDraw = scrLine
  hDraw = 1
  exec ChgLine
ENDPROC

'-------------------------------------
' Inserts a normal key to the file
'
PROC InsertNormalKey
    ' Process normal keys
    escape = 0
    if linLen > 254
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
ENDPROC

'-------------------------------------
' Deletes current line
'
PROC DeleteLine
  ' Mark file as changed
  fileSaved = 0
  ' Go to beginning of line
  column = 0
  ' Delete line from screen
  poke @CRSINH, 1
  pos. 0, scrLine+1
  put 156
  ' Delete from entire file!
  ptr = ScrAdr(scrLine)
  nptr = ScrAdr(scrLine+1)
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
    ScrAdr(y+1) = nptr
  next y
  y = scrLine
  exec DrawLineOrig
  edited = 0
  lDraw = 22
  hDraw = 1
  exec ChgLine
ENDPROC

'-------------------------------------
' Deletes char to the left of current
'
PROC DoBackspace
    if column > 0
      column = column - 1
      exec DoDeleteKey
    endif
ENDPROC

'-------------------------------------
' Process DELETE key
'
PROC DoDeleteKey
  if column < linLen
    exec DeleteChar
  else
    ' Mark file as changed
    fileSaved = 0
    exec SaveLine
    ' Manually delete the EOL
    ptr = ScrAdr(scrLine+1)
    move ptr, ptr - 1, MemEnd - ptr
    MemEnd = MemEnd - 1
    ' Redraw
    exec RedrawScreen
  endif
ENDPROC

'-------------------------------------
' Sets mark position to current line
'
PROC SetMarkPosition
  markPos = topLine + scrLine
ENDPROC

'-------------------------------------
' Copies a line from the mark position
'
PROC CopyFromMArk
    ' Simulate a cursor-down, so that the line is pasted
    ' after the current one.
    exec CursorDown

    ' Search mark line address. We can't store the address of
    ' the line, as any edit could invalidate that.
    nptr = Adr(MemStart)
    y = 0
    while y <= markPos and nptr <> MemEnd
      ptr = nptr
      exec CountLines
      inc y
    wend

    ' The source line is from PTR to NPTR, insert this
    ' after current line, so get the length to copy
    newPtr = nptr - ptr

    ' Increment the mark position by one
    inc markPos

    ' But if we are copying to a position before the mark
    if markPos > topLine + scrLine
      ' we need to increment again,
      inc markPos
      ' and adjust the source pointer
      ptr = nptr
    endif

    ' Get address of current line
    nptr = ScrAdr(scrLine)

    ' Check if we have enough space in the buffer for the new file
    ' TODO: This check will fail if the buffer is bigger than 32kB,
    '       because the right side will be negative.
    if newPtr <= dpeek(@MEMTOP) - MemEnd

      ' Make space for the new line
      -move nptr, nptr + newPtr, MemEnd - nptr

      ' Copy new line to here
      move ptr, nptr, newPtr

      ' Update the new memory ending
      MemEnd = MemEnd + newPtr

      ' Mark file as changed
      fileSaved = 0

      exec RedrawScreen
    endif

ENDPROC

'-------------------------------------
' Reads a key and process
PROC ProcessKeys
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

  '--------- Return Key - can't be escaped
  if key = $9B
    exec ReturnKey

  elif (escape or ( ((key & 127) >= $20) and ((key & 127) < 125)) )
    exec InsertNormalKey
  '--------------------------------
  ' Command keys handling
  '
  '
  '--------- Delete Line ----------
  elif key = 156
    exec DeleteLine
  '
  '--------- Backspace ------------
  elif key = 126
    exec DoBackspace
  '
  '--------- Del Char -------------
  elif key = 254
    exec DoDeleteKey
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
      dec column
      if scrColumn > 1
        dec scrColumn
        put key
      else
        exec DrawCurrentLine
      endif
    endif
  '
  '--------- Control-U (page up)---
  elif key = $15
    ' To use less code, reuse "key" variable
    ' as loop counter, so instead of looping
    ' from 0 to 18, loops from key=$15 to $15+18=$27
    repeat
      exec CursorUp
      inc key
    until key>$27
    exec ChgLine
  '
  '--------- Control-V (page down)-
  elif key = $16
    ' To use less code, reuse "key" variable
    ' as loop counter, so instead of looping
    ' from 0 to 18, loops from key=$16 to $16+18=$28
    repeat
      exec CursorDown
      inc key
    until key>$28
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
    exec AskSaveFileChanged
    if not key
      cls
      end
    endif
  '
  '--------- Control-S (save) -----
  elif key = $13
    exec AskSaveFile
  '
  '--------- Control-R (run) -----
  elif key = $12
    key = 0 ' key = 0 -> run
    exec CompileFile
  '
  '--------- Control-W (write compiled file) -----
  elif key = $17
    ' key <> 0 -> save
    exec CompileFile
  '
  '--------- Control-N (new) -----
  elif key = $0E
    exec AskSaveFileChanged
    if not key
      FileName$="D:"
      MemEnd = Adr(MemStart)
      exec RedrawNewFile
    endif
  '
  '--------- Control-L (load) -----
  elif key = $0C
    exec AskSaveFileChanged
    if not key
      pos. 0, 0
      ? "úùLoad";
      exec InputFileName
      if not key
        exec LoadFile
      endif
    endif
  '
  '--------- Control-Z (undo) -----
  elif key = $1A
    exec UndoEditLine
  '
  '--------- Control-M (set mark) -----
  elif key = $0D
    exec SetMarkPosition
  '--------- Control-C (copy from mark) -----
  elif key = $03
    exec CopyFromMark
  '
  '--------- Escape ---------------
  elif key = $1B
    escape = 1
 'else
    ' Unknown Control Key
  endif
ENDPROC

'-------------------------------------
' Save compiled file
'
PROC SaveCompiledFile
  ' Save original filename
  move Adr(FileName$), EditBuf, 128
  poke Len(FileName$) + Adr(FileName$), $58

  pos. 0, 0
  ? "úùName";
  exec InputFileName
  if key
    ' Don't save
    exit
  endif

  open #1, 8, 0, FileName$
  if err() < 128
    ' Open ok, write header
    bput #1, @COMP_HEAD_1, 12
    bput #1, @@__INTERP_START__, @@__INTERP_SIZE__
    bput #1, @__PREHEAD_RUN__, @COMP_RT_SIZE
    ' Note, the compiler writes to "NewPtr" the end of program code
    bput #1, MemEnd + 1, NewPtr - MemEnd
    if err() < 128
      ' Save ok, close
      close #1
    endif
  endif

  if err() > 127
    exec FileError
  endif

  ' Restore original filename
  move EditBuf, Adr(FileName$), 128
ENDPROC

' vi:syntax=fastbasic

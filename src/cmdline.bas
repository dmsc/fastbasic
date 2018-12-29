'
' Command line compiler in FastBasic - dmsc - 2018
' ------------------------------------------------
'

' Init filename, allocates space for one string
FileName$ = ""

' MemStart: the start of available memory, used as a buffer for the file data
dim MemStart(0)
' MemEnd: the end of the current file, initialized to MemStart.
MemEnd = Adr(MemStart)

'-------------------------------------
' Shows file error
'
PROC FileError
  ? "FILE ERROR: "; err()
  put $FD
  ? "Press any key to exit."
  close #1
  get i
  end
ENDPROC

'-------------------------------------
' Adds "D:" and extension to file name
'
PROC InputFileName
  input " File Name? "; FileName$
  if Len(FileName$) < 3 OR Asc(FileName$[2]) <> $3A OR Asc(FileName$[3]) <> $3A
    ' Don't use string operations to avoid allocations!!!
    -move Adr(FileName$) + 1, Adr(FileName$) + 3, Len(FileName$)
    poke Adr(FileName$), peek(Adr(FileName$)) + 2
    poke Adr(FileName$) + 1, $44
    poke Adr(FileName$) + 2, $3A
  endif
ENDPROC

'-------------------------------------
' Save compiled file
'
PROC SaveCompiledFile

  ? "Output";
  exec InputFileName

  if not Len(FileName$) then exit

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

ENDPROC

'-------------------------------------
' Load file into editor
'
PROC LoadFile

  ? "BASIC";
  exec InputFileName

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

ENDPROC

'-------------------------------------
' Compile file
PROC CompileFile
  ' Compile main file
  poke MemEnd, $9B
  ? "Compiling..."
  if USR( @compile_buffer, Adr(MemStart), MemEnd+1)
    ' Parse error, show
    ? " at line "; dpeek(@@linenum) - 1; " column "; peek( @@bmax )
  else
    exec SaveCompiledFile
  endif
ENDPROC

'-------------------------------------
' Main Program
'

? "FastBasic Compiler v3.6"
exec LoadFile

exec CompileFile


' vi:syntax=tbxl

'
' FastBasic - Fast basic interpreter for the Atari 8-bit computers
' Copyright (C) 2017-2019 Daniel Serpell
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

' Command line compiler in FastBasic
' ----------------------------------

' Init filename, allocates space for one string
FileName$ = ""

' MemStart: the start of available memory, used as a buffer for the file data
dim MemStart(-1) byte
' MemEnd: the end of the current file, initialized to MemStart.
MemEnd = Adr(MemStart)
NewPtr = 0

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
  if Len(FileName$) < 3 OR (Asc(FileName$[2]) <> $3A AND Asc(FileName$[3]) <> $3A)
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
    ' Note, the compiler writes to "NewPtr" the end of program code
    bput #1, MemEnd + 1, NewPtr - MemEnd
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
    ? " at line "; dpeek(@@linenum); " column "; peek( @@bmax )
  else
    exec SaveCompiledFile
  endif
ENDPROC

'-------------------------------------
' Main Program
'

? "FastBasic Compiler %VERSION%"
exec LoadFile

exec CompileFile


' vi:syntax=tbxl

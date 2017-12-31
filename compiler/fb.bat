@echo off
set basfile=%1
set asmfile=%~d1%~p1%~n1.asm
set xexfile=%~d1%~p1%~n1.xex
C:\cc65\fb\fastbasic-fp %basfile% %asmfile% || exit /b %errorlevel%
C:\cc65\bin\cl65 -t atari -C C:\cc65\fb\fastbasic.cfg %asmfile% -o %xexfile% C:\cc65\fb\fastbasic-fp.lib || exit /b %errorlevel%

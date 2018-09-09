@echo off
setlocal

:: Set initial values
set cc65=C:\cc65\bin\
set fb=fastbasic-int
set fbpath=%~dp0
set fbname=%~n0

:: Loop over arguments
set prog=
set opts=
set extra=

:readargs
 if "%~1"=="" goto :endargs
 set opt=%1
 if "%opt%"=="-h" call :usage & exit /b
 if "%opt:~0,3%"=="-X:" set extra=%extra% %opt:~3% & goto :nextarg
 if "%opt:~0,3%"=="-S:" set extra=%extra% --start-addr %opt:~3% & goto :nextarg
 if "%opt:~0,1%"=="-" set opts=%opts% %~1 & goto :nextarg
 if /i "%~x1"==".asm" set extra=%extra% %~1 & goto :nextarg
 if /i "%~x1"==".o"   set extra=%extra% %~1 & goto :nextarg
 if not "%prog%"=="" call :error specify only one basic file & exit /b
 set prog=%~nx1
 set basfile=%~dpnx1
 set asmfile=%~dpn1.asm
 set xexfile=%~dpn1.xex
 set lblfile=%~dpn1.lbl
:nextarg
 shift
goto :readargs

:endargs

:: Check arguments
if "%prog%"=="" call :error no input file & exit /b
if not exist %basfile% call :error input file '%prog%' does not exists & exit /b
if "%basfile%"=="%asmfile%" call :error input file '%prog%' same as ASM file & exit /b
if "%basfile%"=="%xexfile%" call :error input file '%prog%' same as XEX file & exit /b
if "%basfile%"=="%lblfile%" call :error input file '%prog%' same as LBL file & exit /b

echo Compiling '%prog%' to assembler.
%fbpath%%fb% %opts% %basfile% %asmfile% || exit /b %errorlevel%
echo Assembling '%asmfile%%extra%' to XEX file.
%cc65%cl65 -tatari -C %fbpath%fastbasic.cfg -g %asmfile% %extra% -o %xexfile% -Ln %lblfile% %fbpath%%fb%.lib || exit /b %errorlevel%

exit /b

:error
echo %fbname%: error, %*
echo Try '%fbname% -h' for help.'
exit /b

:usage
%fbpath%%fb% -h
exit /b


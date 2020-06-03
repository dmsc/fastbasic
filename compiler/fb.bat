@echo off
setlocal

:: Set initial values
set fb=fastbasic-fp
set fbpath=%~dp0
set fbname=%~n0
set cfgfile=%fbpath%fastbasic.cfg
set asminc=%fbpath%asminc

:: Loop over arguments
set prog=
set opts=
set extra=
set asmopt=-I%asminc% -tatari -g

:readargs
 if "%~1"=="" goto :endargs
 set opt=%~1
 if "%opt%"=="-h" call :usage & exit /b
 if "%opt:~0,3%"=="-X:" set asmopt=%asmopt% %opt:~3%& goto :nextarg
 if "%opt:~0,3%"=="-S:" set extra=%extra% --start-addr %opt:~3%& goto :nextarg
 if "%opt:~0,3%"=="-C:" set cfgfile=%opt:~3%& goto :nextarg
 if "%opt:~0,1%"=="-" set opts=%opts% %~1& goto :nextarg
 if /i "%~x1"==".asm" set exasm=%~dpnx1& goto :addasm
 if /i "%~x1"==".s"   set exasm=%~dpnx1& goto :addasm
 if /i "%~x1"==".o"   set extra=%extra% %~1& goto :nextarg
 if not "%prog%"=="" call :error specify only one basic file & exit /b
 set prog=%~nx1
 set basfile=%~dpnx1
 set asmfile=%~dpn1.asm
 set xexfile=%~dpn1.xex
 set lblfile=%~dpn1.lbl
 set objfile=%~dpn1.o
:nextarg
 shift
goto :readargs

:addasm
set obj=%~dpn1.o
echo Assembling '%opt%' to '%obj%'
set extra=%extra% %obj%
%fbpath%ca65 %asmopt% -o %obj% %exasm% || exit /b %errorlevel%
goto :nextarg

:endargs

:: Check arguments
if "%prog%"=="" call :error no input file & exit /b
if not exist %basfile% call :error input file '%prog%' does not exists & exit /b
if "%basfile%"=="%asmfile%" call :error input file '%prog%' same as ASM file & exit /b
if "%basfile%"=="%xexfile%" call :error input file '%prog%' same as XEX file & exit /b
if "%basfile%"=="%lblfile%" call :error input file '%prog%' same as LBL file & exit /b

echo Compiling '%prog%' to assembler.
%fbpath%%fb% %opts% %basfile% %asmfile% || exit /b %errorlevel%
echo Assembling '%asmfile%' to object file.
%fbpath%ca65 %asmopt% -o %objfile% %asmfile% || exit /b %errorlevel%
echo Linking '%objfile%%extra%' to XEX file.
%fbpath%ld65 -C %cfgfile% %objfile% %extra% -o %xexfile% -Ln %lblfile% %fbpath%%fb%.lib || exit /b %errorlevel%

exit /b

:error
echo %fbname%: error, %*
echo Try '%fbname% -h' for help.'
exit /b

:usage
%fbpath%%fb% -h
exit /b


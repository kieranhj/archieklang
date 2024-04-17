@echo off

echo Start build...
if EXIST build\archieklang.bin del /Q build\archieklang.bin
if NOT EXIST build mkdir build

if "%2"=="" (
	echo "Usage: make.bat <folder> <mod filename>"
	exit /b 1
)

echo Splitting MOD %1\%2...
bin\SplitMod.exe %1\%2

if %ERRORLEVEL% neq 0 (
	echo Failed to split MOD.
	exit /b 1
)

ren "%1\%2.smp" music.mod.smp
ren "%1\%2.trk" music.mod.trk

if EXIST %1\script.txt (
echo Generating code...
python bin\akp2arc.py %1\script.txt -o %1\arcmusic.asm

if %ERRORLEVEL% neq 1 (
	echo Failed to generate ArchieKlang code.
	exit /b 1
)
)

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -I%1 -opt-adr -o build\archieklang.bin archieklang.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Copying files...
set HOSTFS=..\arculator\hostfs
copy build\archieklang.bin "%HOSTFS%\archieklang,ff8"

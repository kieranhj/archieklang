@echo off

echo Start build...
if EXIST build\archieklang.bin del /Q build\archieklang.bin
if NOT EXIST build mkdir build

echo Generating code...
python bin\akp2arc.py columbia\script.txt -o build\arcmusic.asm

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -opt-adr -o build\archieklang.bin archieklang.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Copying files...
set HOSTFS=..\arculator\hostfs
copy build\archieklang.bin "%HOSTFS%\archieklang,ff8"

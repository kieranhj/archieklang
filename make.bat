@echo off

echo Start build...
if EXIST build\archieklang.bin del /Q build\archieklang.bin
if NOT EXIST build mkdir build

echo Generating code...
python bin\akp2arc.py columbia\script.txt -o build\arcmusic.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to generate ArchieKlang code.
	exit /b 1
)

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -opt-adr -o build\archieklang.bin archieklang.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

bin\Shrinkler.exe -b -p -d -z -3 build\archieklang.bin build\archieklang.shri

if %ERRORLEVEL% neq 0 (
	echo Failed to Shrinkle binary.
	exit /b 1
)

echo Assembling loader...
bin\vasmarm_std_win32.exe -L build\loader.txt -m250 -Fbin -opt-adr -o build\loader.bin lib\loader.asm

echo Copying files...
set HOSTFS=..\arculator\hostfs
copy build\loader.bin "%HOSTFS%\archieklang,ff8"

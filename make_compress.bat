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

del build\music.mod.smp
del build\music.mod.trk
move "%1\%2.smp" build
move "%1\%2.trk" build
ren "build\%2.smp" music.mod.smp
ren "build\%2.trk" music.mod.trk

if EXIST %1\script.txt (
echo Generating code...
python bin\akp2arc.py %1\script.txt -o %1\arcmusic.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to generate ArchieKlang code.
	exit /b 1
)
)

copy "%1\Isamp.raw" build

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -I%1 -opt-adr -o build\archieklang.bin archieklang.asm

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

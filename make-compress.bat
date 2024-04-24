@echo off

echo Start build...
if EXIST build\archieklang.bin del /Q build\archieklang.bin
if NOT EXIST build mkdir build

if "%1"=="" (
	echo "Usage: make.bat <mod filename>"
	exit /b 1
)

echo Splitting MOD '%1'...
copy "songs\%1" build

bin\SplitMod.exe "build\%1"

if %ERRORLEVEL% neq 0 (
	echo Failed to split MOD.
	exit /b 1
)

del build\music.mod.*
ren "build\%1.smp" music.mod.smp
ren "build\%1.trk" music.mod.trk
ren "build\%1.i" music.mod.i

echo Generating code...
python bin\akp2arc.py scripts\%1.txt -o build\arcmusic.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to generate ArchieKlang code.
	exit /b 1
)

if EXIST "imported\%1.raw" (
    echo Copying imported samples...
    copy "imported\%1.raw" build\Isamp.raw
    set DEFINE=-D_EXTERNAL_SAMPLES=1
) else (
    set DEFINE=-D_EXTERNAL_SAMPLES=0
)

echo .byte "%1" > build\modname.i

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fbin -Ibuild %DEFINE% -opt-adr -o build\archieklang.bin archieklang.asm

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

# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# make.bat builds one song from songs\ and copies the binary to ..\arculator\hostfs\archieklang,ff8.
# Pick the song with: make SONG=Virgill-amigahub.mod
SONG ?= Rhino2.mod
.PHONY: all build compress songs help
all: build

build:
	cmd /c .\make.bat $(SONG)

compress:
	cmd /c .\make-compress.bat $(SONG)

songs:
	@dir /b songs

help:
	@echo make [SONG=x.mod]           - build songs\$(SONG) and copy it to ..\arculator\hostfs\archieklang,ff8 (make.bat)
	@echo make compress [SONG=x.mod]  - same, Shrinkler-packed with a loader (make-compress.bat)
	@echo make songs                  - list the MODs in the songs folder
	@echo make help                   - this list
	@echo Needs: Python 3 with the 'parse' package (py -3 -m pip install parse)

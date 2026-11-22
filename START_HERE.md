# archieklang: start here

ArchieKlang: a port of Virgill's AmigaKlang soft synth to the Acorn Archimedes. A Python script (`bin/akp2arc.py`) turns an AmigaKlang patch script into ARM assembler that generates the MOD's samples at init time; the test player assembles it with vasm.

| | |
|---|---|
| GitHub | https://github.com/kieranhj/archieklang (public) |
| Upstream | port of AmigaKlang (Virgill) and Aklang2Asm (Dan/Lemon) |
| Local path | D:\archie\mine\archieklang (moved from OneDrive\Archie\Repos\archieklang on 2026-11-22) |
| Branch | main; other branches: wip/cast-short-madness, wip/log-extend (1 unmerged commit each, 2024-04/05, pushed) |
| Last commit | 2024-06-07: Remove call to divide and replace with const. |

## What's in here

- `archieklang.asm` (player/test harness), `lib/`; `bin/akp2arc.py` (converter), `bin/SplitMod.exe`, vasm, Shrinkler.
- `songs/*.mod` with matching `scripts/*.mod.txt` (AmigaKlang patch tables) and optional `imported/*.mod.raw` samples.
- `examples/`, `patches/`, `ref/`.
- `make.bat <mod>` and `make-compress.bat <mod>`.

## Build and run

- `make` (new wrapper): `make.bat $(SONG)`, default `SONG=Rhino2.mod`; `make SONG=Virgill-amigahub.mod` for another; `make compress`, `make songs`, `make help`.
- Works (2026-11-22): `akp2arc.py` (already Python 3) needs the Python package `parse`, installed on 2026-11-22 with `py -3 -m pip install --user parse` (parse 1.22.4). `make` builds Rhino2 end to end.
- On success it writes `build\archieklang.bin` and copies it to `..\arculator\hostfs\archieklang,ff8`; run that in Arculator.

## Local changes

- Untracked: `.vscode/` (editor settings).
- No stashes; the two wip branches above are small experiments.

## Status and next steps

- Used in the ArchieKlang Announcetro (aklang, NOVA 2024) and archie-verse (`lib/archi-klang`). Last work fixed sample buffer overruns and added Rhino / Virgill tunes. No TODO/plan file found.

## See also

- `README.md`; `D:\archie\mine\aklang`, `D:\archie\mine\archie-verse`.

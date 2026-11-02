# Windows CMake (PC2023 follow-up — copy-paste)

Original iverilog + `sim/verilator/` Make paths are **unchanged**. This file is only for `cmake-system/` / `cmake-conan/` on Wei’s worker.

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Conan | **2.34** (cmake-conan tree only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** — not a random unofficial drop |
| Engine | **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |

## withlimon layout

Extract to a **short path without spaces** (withlimon’s example is `D:\verilator`):

```
D:\verilator\
  bin\verilator_bin.exe     PE32+ engine  ← CMake/PowerShell drive this
  bin\verilator.exe         same PE, renamed copy
  bin\verilator.bat         sets VERILATOR_ROOT, then verilator.exe
  bin\verilator             Perl driver, **no extension** — do not invoke
  include\                  (also mirrored under share\verilator\include\)
  README_WINDOWS.txt
```

The withlimon tarball does **not** ship `verilator-config.cmake`. Shared helper `cmake/TinyRiscvSim.cmake` uses bundled `cmake/verilator-config.fallback.cmake` in that case.

MSYS2 unpack of the same tarball: `C:\msys64\mingw64\bin\verilator_bin.exe`.

Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` — that file is a Perl wrapper with a `.exe` suffix (not a PE). CMake, `build_sim.ps1`, and the Conan recipe MZ-check `verilator_bin.exe` and walk from `VERILATOR_ROOT=share/verilator` up to `mingw64\bin`.

## Environment (once)

User environment:

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

Optional: Conan 2.34 on PATH for `cmake-conan`. RISC-V GCC is optional: without it CMake still builds the Verilator model and smokes `tests/isa/generated/rv32ui-p-add.bin`.

## cmake-system (no Conan)

From cmd / PowerShell (worker checkout):

```bat
cd /d D:\CursorWorker\tinyriscv
cd cmake-system
powershell -File .\build_sim.ps1
```

Or by hand (Ninja + MSVC, or Ninja + MinGW — CMake picks the compiler):

```bat
set VERILATOR_ROOT=D:\verilator
set PATH=%VERILATOR_ROOT%\bin;%PATH%
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --config Release --target sim
cmake --build build-system --config Release --target sim-fail
ctest --test-dir build-system -C Release --output-on-failure
```

`build_sim.ps1` searches `VERILATOR_ROOT\bin\verilator_bin.exe`, then `D:\verilator\bin\verilator_bin.exe`, then `C:\msys64\mingw64\bin\verilator_bin.exe`.

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

The script `conan export`s `recipes/verilator` (withlimon 5.052 tarball, or the local `D:\verilator` / MSYS2 kit if present) and configures with `conan_provider.cmake`. `conan install` uses `--no-remote` so a password-prompting extra remote cannot block the local recipe.

Profile file in-tree: `cmake-conan/profiles/windows-msvc`. Override:

```bat
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release -DCONAN_HOST_PROFILE=profiles/windows-msvc -DCONAN_BUILD_PROFILE=profiles/windows-msvc
```

## MSVC `-fcoroutines*`

`cmake/TinyRiscvSim.cmake` `include(CheckCXXCompilerFlag)` before every `verilate()`, then strips GCC-only `-fcoroutines*` from the target on MSVC. withlimon is a GCC/MinGW-built engine; the **generated C++** is compiled with whatever CMake selected (MSVC or g++). `tb_verilator.cpp` already provides `sc_time_stamp()`; the fail-harness uses `cmake/sc_time_stamp.cpp` because MSVC has no weak ELF symbols.

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not point `VERILATOR=` at the Perl driver.
- Do not change `sim/verilator/Makefile` or the CPU RTL. This tree only wraps that TB.

Linux proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Re-run `build_sim.ps1` on PC2023 — same withlimon PE / `verilator_bin.exe` / MSVC `-fcoroutines*` rules; Windows proof is a follow-up ([`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md)).

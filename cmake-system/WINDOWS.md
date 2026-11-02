# Windows CMake (PC2023 — copy-paste)

Original iverilog + `sim/verilator/` Make paths are **unchanged**. This file is only for `cmake-system/` / `cmake-conan/` on Wei’s worker.

## PC2023 PASS (`develop` `4dd5b21`)

Both CMake trees are green on worker **PC2023**. Engine is always the withlimon **`verilator_bin.exe` PE** (here the MSYS2 MinGW64 copy). Never the extensionless Perl `verilator`.

| Tree | SHA | Engine | Result |
|------|-----|--------|--------|
| **cmake-system** | `4dd5b21` | withlimon PE `verilator_bin.exe` under MSYS2 MinGW64 | PASS (earlier in the same campaign) |
| **cmake-conan** | `4dd5b21` | `C:\msys64\mingw64\bin\verilator_bin.exe` | PASS, `build_sim.ps1` EXIT 0; ctest **3/3** (`tinyriscv_fw_setup`, `sim_tinyriscv`, `sim-fail`) |

cmake-conan extras (warning only, not a fail): firmware fallback to `tests/isa/generated/rv32ui-p-add.bin`; CMake-Conan “C compiler is not defined”. Log on the proof machine: `D:\CursorWorker\windows-proof-logs\tinyriscv-cmake-conan-20261102-170948.log`.

Details: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md), [`../cmake-conan/WINDOWS_PASS_EVIDENCE.md`](../cmake-conan/WINDOWS_PASS_EVIDENCE.md).

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Conan | **2.34.0** (`cmake-conan` tree only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** — not a random unofficial drop |
| Engine | **`verilator_bin.exe`** (PE32+, MZ). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |
| PC2023 PE used | `C:\msys64\mingw64\bin\verilator_bin.exe` |
| Host C++ | Whatever CMake selected (typically VS 2022 / **MSVC** when `-G` is omitted on this worker; Ninja + MinGW also works). `PreferUnixGcc.cmake` is Unix-only. |

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

MSYS2 unpack of the same tarball — this is what PC2023 used:

- Use **`C:\msys64\mingw64\bin\verilator_bin.exe`** (PE).
- Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` — that file is a Perl wrapper with a `.exe` suffix (not a PE).

CMake, `build_sim.ps1`, and the Conan recipe MZ-check `verilator_bin.exe` and walk from `VERILATOR_ROOT=share/verilator` up to `mingw64\bin`.

## Environment (once)

User environment (withlimon tree). Skip `D:\verilator` if you only have the MSYS2 PE; `build_sim.ps1` finds `C:\msys64\mingw64\bin\verilator_bin.exe` next.

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

Optional: Conan 2.34 on PATH for `cmake-conan`. RISC-V GCC is optional (see firmware below).

## cmake-system (no Conan)

From cmd / PowerShell (worker checkout):

```bat
cd /d D:\CursorWorker\tinyriscv
cd cmake-system
powershell -File .\build_sim.ps1
```

Or by hand (`-G` omitted: CMake picks the default generator, typically Visual Studio 17 2022 / MSVC on PC2023):

```bat
set PATH=C:\msys64\mingw64\bin;%PATH%
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --config Release --target sim
cmake --build build-system --config Release --target sim-fail
ctest --test-dir build-system -C Release --output-on-failure
```

`build_sim.ps1` searches `D:\verilator\bin\verilator_bin.exe`, then `C:\msys64\mingw64\bin\verilator_bin.exe`, then `$VERILATOR_ROOT\bin` and parents (skips Perl wrappers).

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

The script `conan export`s `recipes/verilator` (local `D:\verilator` / MSYS2 kit if present, else withlimon **5.052** tarball) and configures with `conan_provider.cmake`. `conan install` uses `--no-remote` so a password-prompting extra remote cannot block the local recipe.

Profile file in-tree: `cmake-conan/profiles/windows-msvc`. Default is `auto-cmake` (CMake-detected compiler). Override:

```bat
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release -DCONAN_HOST_PROFILE=profiles/windows-msvc -DCONAN_BUILD_PROFILE=profiles/windows-msvc
```

## MSVC / MinGW (what this tree actually does)

- Verilator **engine** is the withlimon / MSYS2 **MinGW-built PE**. Host **C++** is MSVC or MinGW, whichever CMake selected. `cmake/PreferUnixGcc.cmake` does not run on Windows.
- `cmake/TinyRiscvSim.cmake` `include(CheckCXXCompilerFlag)` before every `verilate()`, then strips GCC-only `-fcoroutines*` from the target on **MSVC**.
- `sim/verilator/tb_verilator.cpp` is portable C++ (`cstdint` / `cstdio`); it already provides `sc_time_stamp()`. There are no extra `#if _WIN32` guards in that TB — none are needed.
- The `sim-fail` harness uses `cmake/sc_time_stamp.cpp` because MSVC has no weak ELF symbols (`VL_ATTR_WEAK` is empty).
- Both `CMakeLists.txt` files declare `project(... LANGUAGES CXX)` only. cmake-conan may print CMake-Conan **“C compiler is not defined”** — non-fatal (see below).
- GNU make is **not** required to verilate or to run `sim` / `ctest`.

## Firmware without RISC-V GCC

Without `riscv64-unknown-elf-gcc` (or xpack) **and** GNU make, CMake still **verilates and links** the SoC model. Smoke `inst.data` then comes from committed `tests/isa/generated/rv32ui-p-add.bin` (still `TEST_PASS`). CMake prints a **WARNING**, not a fail — that is the PC2023 cmake-conan path.

Preferred image remains `tests/example/simple` when the RISC-V toolchain is on PATH (same as [`../LEARNING.md`](../LEARNING.md)).

## Operator surprises (non-fatal)

| Message | Meaning |
|---------|---------|
| `TinyRiscvSim: no RISC-V toolchain and no simple.bin` / fallback `rv32ui-p-add.bin` | Warning only. Model still builds; `sim` / ctest still PASS. |
| `CMake-Conan: The C compiler is not defined.` | Warning only. `project()` is `LANGUAGES CXX`; Verilator is a tool_require. Do not treat as a configure failure. |

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not point `VERILATOR=` at the Perl driver.
- Do not invoke `share\verilator\bin\verilator_bin.exe` (Perl wrapper with a `.exe` suffix).
- Do not change `sim/verilator/Makefile` or the CPU RTL. This tree only wraps that TB.

Linux proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Windows proof: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md), [`../cmake-conan/WINDOWS_PASS_EVIDENCE.md`](../cmake-conan/WINDOWS_PASS_EVIDENCE.md).

# cmake-conan — Conan 2 + 本地 Verilator recipe

与 [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) 相同的双树之二。CMakeLists 与 `cmake-system/` 共用 [`../cmake/TinyRiscvSim.cmake`](../cmake/TinyRiscvSim.cmake)；依赖通过 Conan 2 提供。

Does **not** change iverilog or `sim/verilator/` Make.

## Layout

| Path | Role |
|------|------|
| `CMakeLists.txt` | `PreferUnixGcc` → export local recipe → `conan_provider.cmake` → `TinyRiscvSim` |
| `conanfile.py` | `tool_requires("verilator/5.052")` + CMakeDeps build context |
| `conan_provider.cmake` | Vendored [conan-io/cmake-conan](https://github.com/conan-io/cmake-conan) develop2 |
| `recipes/verilator/` | Local recipe: **withlimon** tarball / `D:\verilator` on Windows; system kit on Linux |
| `profiles/linux-gcc` | Linux GCC 13 |
| `profiles/windows-msvc` | VS2022 / MSVC 193 (optional override; default is `auto-cmake`) |
| `build_sim.ps1` | PC2023 helper |

Targets are the same as cmake-system (`sim`, `sim-fail`). See [`../cmake-system/README.md`](../cmake-system/README.md) and [`../CMAKE.md`](../CMAKE.md).

## Linux

Needs Conan 2 (`pip install conan==2.34.0`) and a system Verilator kit (`apt install verilator`). The local recipe **packages the system kit** (does not rebuild Verilator from source).

```bash
export PATH="$HOME/.local/bin:$PATH"   # if pip --user
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
cmake --build build-conan --target sim-fail
ctest --test-dir build-conan --output-on-failure
```

If Conan is missing, use `cmake-system/` instead; this tree still ships.

Linux VM evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).

## Windows (PC2023 PASS)

| Item | Value |
|------|--------|
| Worker | `D:\CursorWorker` |
| SHA | `develop` **`4dd5b21`** |
| Conan | **2.34.0** |
| Verilator | [withlimon/verilator-windows](https://github.com/withlimon/verilator-windows) **`verilator_bin.exe`** at `C:\msys64\mingw64\bin\verilator_bin.exe` |
| Result | `.\build_sim.ps1` EXIT 0; ctest **3/3 Passed** (`tinyriscv_fw_setup`, `sim_tinyriscv`, `sim-fail`) |

```powershell
cd cmake-conan
.\build_sim.ps1
```

Full copy-paste: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md). The recipe prefers `D:\verilator` if present, otherwise the MSYS2 prefix / withlimon **5.052** tarball. Always the PE `verilator_bin.exe` — never extensionless Perl `verilator`. `conan install` uses `--no-remote` so extra remotes cannot prompt for a password.

MSVC: `CheckCXXCompilerFlag` before `verilate()`, then strip `-fcoroutines*`. Host C++ is MSVC or MinGW (CMake’s default generator); the engine is still the MinGW-built PE.

Non-fatal on this proof: no RISC-V toolchain → firmware fallback `tests/isa/generated/rv32ui-p-add.bin` (WARNING); CMake-Conan “C compiler is not defined” (`LANGUAGES CXX` only). Evidence: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md).

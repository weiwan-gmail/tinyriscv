# cmake-system Windows PASS evidence (PC2023)

Recorded on worker **PC2023**, checkout `D:\CursorWorker\tinyriscv`, `develop` tip **`4dd5b21`**. Linux VM proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Operator copy-paste: [`WINDOWS.md`](WINDOWS.md).

| Item | Value |
|------|--------|
| Tree | `cmake-system/` (machine Verilator, no Conan) |
| SHA | **`4dd5b21`** (`Add cmake-system + cmake-conan dual-tree`) |
| Engine | withlimon **`verilator_bin.exe` PE** under MSYS2 MinGW64 (`C:\msys64\mingw64\bin\verilator_bin.exe`) |
| Result | **PASS** (earlier in the same Windows campaign as cmake-conan) |

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-system
powershell -File .\build_sim.ps1
```

Shared harness (`cmake/TinyRiscvSim.cmake`) registers ctest `tinyriscv_fw_setup`, `sim_tinyriscv`, `sim-fail`. Engine must be the PE (MZ `4D5A`), never extensionless Perl `verilator` and never `share\verilator\bin\verilator_bin.exe`.

cmake-conan on the same tip (ctest 3/3, log path): [`../cmake-conan/WINDOWS_PASS_EVIDENCE.md`](../cmake-conan/WINDOWS_PASS_EVIDENCE.md).

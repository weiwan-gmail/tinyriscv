# cmake-conan Windows PASS evidence (PC2023)

Recorded **2026-11-02** on worker **PC2023**, checkout `D:\CursorWorker\tinyriscv`, `develop` tip **`4dd5b21`**. Linux VM proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Operator copy-paste: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md). cmake-system Windows PASS (same SHA): [`../cmake-system/WINDOWS_PASS_EVIDENCE.md`](../cmake-system/WINDOWS_PASS_EVIDENCE.md).

| Item | Value |
|------|--------|
| Tree | `cmake-conan/` (Conan 2 + local `verilator/5.052` recipe) |
| SHA | **`4dd5b21`** (`Add cmake-system + cmake-conan dual-tree`) |
| Conan | **2.34.0** |
| Engine | withlimon PE **`C:\msys64\mingw64\bin\verilator_bin.exe`** |
| Command | `cmake-conan\build_sim.ps1` |
| Result | **EXIT 0**; ctest **3/3 Passed** (`tinyriscv_fw_setup`, `sim_tinyriscv`, `sim-fail`) |
| Log | `D:\CursorWorker\windows-proof-logs\tinyriscv-cmake-conan-20261102-170948.log` |

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

Local recipe `verilator/5.052` **packages** the PE kit (no Autotools rebuild). Always `verilator_bin.exe` — never extensionless Perl `verilator`.

## Non-fatal (do not treat as fail)

- **Firmware fallback:** no RISC-V toolchain on this box. CMake warned and used committed `tests/isa/generated/rv32ui-p-add.bin` for `inst.data`. Still `TEST_PASS`; not a ctest failure.
- **CMake-Conan “C compiler is not defined”:** `project(tinyriscv_sim_conan LANGUAGES CXX)` does not enable C. Vendored `conan_provider.cmake` may print that WARNING. Configure / build / ctest still succeeded.

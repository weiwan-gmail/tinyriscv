# cmake-system — 系统 Verilator（无 Conan）

与 [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) 相同的双树之一：这里只用**本机已安装的 Verilator**，不跑 Conan。

Does **not** change iverilog, `tests/example/*/Makefile`, or `sim/verilator/` Make. Shared helpers: [`../cmake/TinyRiscvSim.cmake`](../cmake/TinyRiscvSim.cmake). Overview: [`../CMAKE.md`](../CMAKE.md).

## Targets

| Target | What |
|--------|------|
| `sim_tinyriscv` | Same C++ TB as `sim/verilator/` (`tb_verilator.v` + `tb_verilator.cpp` + `rtl.f`) |
| `sim` | Build firmware `inst.data`, run TB, expect `TEST_PASS` / exit 0 |
| `sim-fail` | Identity `fail_probe` with a wrong golden; `ExpectFail.cmake` succeeds only on `FAIL` |

## Linux

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
cmake --build build-system --target sim-fail
ctest --test-dir build-system --output-on-failure
```

Unix 上 `PreferUnixGcc.cmake` 在 `project()` 前优先选 `g++`/`gcc`。

Linux VM evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).

## Windows (PC2023)

[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows) + **`verilator_bin.exe`**. Never the extensionless Perl `verilator`.

```powershell
cd cmake-system
.\build_sim.ps1
```

Copy-paste notes: [`WINDOWS.md`](WINDOWS.md). PC2023 proof is a follow-up: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md).

## Firmware without RISC-V GCC

CMake still **verilates and links** the SoC model. Smoke `inst.data` then comes from `tests/isa/generated/rv32ui-p-add.bin` (committed). Preferred image is `tests/example/simple` when `riscv64-unknown-elf-gcc` (or xpack) is on PATH — same as [`../LEARNING.md`](../LEARNING.md).

# cmake-system PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu 24.04, x86_64).

| Tool | Version |
|------|---------|
| CMake | 3.28.3 (Ninja 1.11.1) |
| g++ | 13.3.0 (`PreferUnixGcc`) |
| Verilator | 5.020 (Debian 5.020-1), `verilator_bin` at `/bin/verilator_bin`, kit `/usr/share/verilator` |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |
| Conan | not used in this tree |

Windows PC2023 (withlimon `verilator_bin.exe` under MSYS2 MinGW64, worker `D:\CursorWorker`, same tip **`4dd5b21`**) **PASS**: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md). PE / MSVC notes: [`WINDOWS.md`](WINDOWS.md).

## Make paths still green

`sim/verilator/Makefile` and iverilog scripts were **not** edited.

```bash
make -C sim/verilator sim
# TEST_PASS  cycles=2888 sim_time=58260 ns  exit 0

python3 sim/sim_new_nowave.py tests/example/simple/simple.bin inst.data
# TEST_PASS  ($finish at 57890000 1ps)
```

## cmake-system

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
cmake --build build-system --target sim-fail
ctest --test-dir build-system --output-on-failure
```

Configure:

```
-- PreferUnixGcc: CMAKE_CXX_COMPILER=/usr/bin/g++
-- TinyRiscvSim: VERILATOR_BIN=/bin/verilator_bin
-- TinyRiscvSim: VERILATOR_ROOT=/usr/share/verilator
-- TinyRiscvSim: firmware tests/example/simple/simple.bin (/usr/bin/riscv64-unknown-elf-gcc)
-- Executing Verilator...
-- Configuring done
```

`--target sim` (same C++ TB as `make -C sim/verilator sim`):

```
test running (Verilator, max_cycles=2000000)...
~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~
~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~
~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~
~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~
~~~~~~~~~ #####   ######       #       #~~~~~~~~~
~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~
~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~
cycles=2888 sim_time=58260 ns
```

Cycle count matches the Make path and [`../docs/logs/04-verilator-simple.txt`](../docs/logs/04-verilator-simple.txt).

`--target sim-fail` (inject-and-catch):

```
-- sim-fail stdout:
FAIL intentional mismatch (cmake sim-fail harness)
-- sim-fail: caught expected FAIL (exit 1)
```

`ctest --output-on-failure`: 3/3 passed (`tinyriscv_fw_setup`, `sim_tinyriscv`, `sim-fail`).

## Firmware fallback (no RISC-V toolchain)

If `riscv64-unknown-elf-gcc` is missing, CMake still **builds** `sim_tinyriscv` and uses committed `tests/isa/generated/rv32ui-p-add.bin`. Same binary on this TB:

```
test running (Verilator, max_cycles=2000000)...
~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~
cycles=461 sim_time=9720 ns
```

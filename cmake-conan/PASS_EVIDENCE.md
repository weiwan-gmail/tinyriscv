# cmake-conan PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu 24.04, x86_64). Shared helpers are [`../cmake/TinyRiscvSim.cmake`](../cmake/TinyRiscvSim.cmake); this tree is a thin wrapper. cmake-system Linux proof: [`../cmake-system/PASS_EVIDENCE.md`](../cmake-system/PASS_EVIDENCE.md).

| Tool | Version |
|------|---------|
| CMake | 3.28.3 (Ninja 1.11.1) |
| g++ | 13.3.0 (PreferUnixGcc; `conan profile detect` guessed clang, provider used **auto-cmake → gcc 13**) |
| Verilator | local recipe `verilator/5.052` **packaged the system 5.020 kit** (did not rebuild from source) |
| Conan | **2.34.0** (`pip install --user conan==2.34.0`) — same major/minor as PC2023 |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |

Windows PC2023 (Conan **2.34.0** + withlimon `verilator_bin.exe` at `C:\msys64\mingw64\bin\verilator_bin.exe`, same tip **`4dd5b21`**) **PASS** — `build_sim.ps1` EXIT 0, ctest 3/3: [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md).

## Configure

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
```

Conan install used in-tree `recipes/verilator` (`tool_requires("verilator/5.052")`). Package folder supplied `VERILATOR_ROOT` / `include/verilated.h`.

```
======== Installing packages ========
-------- Installing package verilator/5.052 ...
Calling package()
package(): Packaged 1 '.cmake' file: verilator-config.cmake
...
Install finished successfully
-- TinyRiscvSim: Conan package folder /home/ubuntu/.conan2/p/b/veril.../p
-- TinyRiscvSim: VERILATOR_BIN=.../p/bin/verilator_bin
-- TinyRiscvSim: VERILATOR_ROOT=.../p
-- TinyRiscvSim: firmware tests/example/simple/simple.bin (/usr/bin/riscv64-unknown-elf-gcc)
-- Executing Verilator...
-- Configuring done
```

## sim / sim-fail / ctest

```bash
cmake --build build-conan --target sim
cmake --build build-conan --target sim-fail
ctest --test-dir build-conan --output-on-failure
```

`--target sim`:

```
test running (Verilator, max_cycles=2000000)...
~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~
cycles=2888 sim_time=58260 ns
```

`--target sim-fail`:

```
FAIL intentional mismatch (cmake sim-fail harness)
-- sim-fail: caught expected FAIL (exit 1)
```

`ctest`: 3/3 passed.

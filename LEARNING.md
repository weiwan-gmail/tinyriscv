# tinyriscv learning index / 学习入口

Primary tutorial (Chinese, for Wei): **[docs/TUTORIAL_zh.md](docs/TUTORIAL_zh.md)**  
Shorter English summary: **[docs/TUTORIAL.md](docs/TUTORIAL.md)**  
Proven command logs: **[docs/logs/](docs/logs/)**

This fork (`weiwan-gmail/tinyriscv`, work on `develop`) keeps the original iverilog + Python flow and adds a **minimal Verilator C++ testbench**. The CPU RTL is not rewritten. Upstream Gitee’s `verilator` branch is a different SoC (OBI bus, new JTAG) and is **not** merged here.

## Exact commands (reproduced in `docs/logs/`)

Install tools (Ubuntu/Debian):

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf python3 build-essential
```

`TOOLCHAIN_PREFIX` is the RISC-V GCC prefix (including the trailing dash). On this box it auto-detects as `riscv64-unknown-elf-`. Override if needed:

```bash
export TOOLCHAIN_PREFIX=riscv64-unknown-elf-
# xpack example:
# export TOOLCHAIN_PREFIX=$HOME/.local/xPacks/riscv-none-elf-gcc/.../bin/riscv-none-elf-
```

### 1) Build the simplest C example

```bash
make -C tests/example/simple toolchain-info
make -C tests/example/simple
# produces tests/example/simple/simple.bin
```

### 2) Icarus Verilog (iverilog) sim — expect `TEST_PASS`

```bash
python3 sim/sim_new_nowave.py tests/example/simple/simple.bin inst.data
```

### 3) Verilator C++ sim — expect `TEST_PASS` and exit code 0

```bash
make -C sim/verilator sim
```

Optional CMake dual-tree (same TB, Make path unchanged): [`CMAKE.md`](CMAKE.md).

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
# expect TEST_PASS and exit 0, same as make -C sim/verilator sim
```

If the RISC-V toolchain is missing, CMake still builds the Verilator model and smokes `tests/isa/generated/rv32ui-p-add.bin`. Windows (PC2023 / withlimon `verilator_bin.exe`) is a follow-up.

### Hello-world UART (`tests/example/uart_tx`, no separate `hello/` tree)

```bash
make -C tests/example/uart_tx
python3 sim/sim_new_nowave.py tests/example/uart_tx/uart_tx.bin inst.data
make -C sim/verilator PROG=../../tests/example/uart_tx/uart_tx.bin EXPECT_UART=hello sim
```

## How to read PASS / FAIL

Firmware (`-DSIMULATION`) uses RISC-V integer registers:

| Register | ABI | Meaning |
|----------|-----|---------|
| `x26` | `s10` | `1` = program finished (`start.S` after `main`) |
| `x27` | `s11` | `1` = pass (`set_test_pass()`), `0` = fail |

SoC ports (active-low copies, see `rtl/soc/tinyriscv_soc_top.v`): `over = ~x26`, `succ = ~x27`.

- **PASS**: stdout contains `TEST_PASS` (ASCII “PASS” banner). Verilator process exits `0`.
- **FAIL**: `TEST_FAIL`. Verilator exits `1`. `x3` is the ISA test number when using `tests/isa`.
- **Timeout**: `Time Out.` (iverilog) or `TEST_TIMEOUT` (Verilator, exit `2`).

## Next cores to read

After this tree: **picorv32** (compact Verilog RV32, compare memory bus vs RIB) then **FemtoRV** (documented teaching SoCs). See the last section of [docs/TUTORIAL_zh.md](docs/TUTORIAL_zh.md).

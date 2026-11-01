# sim — 仿真脚本

Linux 下请用 **python3**（本仓库脚本已改为 `#!/usr/bin/env python3`）。

默认 **不** 生成 VCD（加快仿真）。若要用 gtkwave 看波形：

```bash
DUMP_WAVE=1 python3 sim_new_nowave.py ../tests/example/simple/simple.bin inst.data
gtkwave tinyriscv_soc_tb.vcd
```

## compile_rtl.py

编译 RTL + testbench 为 `out.vvp`。

```bash
python3 compile_rtl.py ..
```

## sim_new_nowave.py

把 `.bin` 转成 `inst.data`，编译 RTL，用 iverilog/vvp 跑仿真。

```bash
# Linux
python3 sim_new_nowave.py ../tests/example/simple/simple.bin inst.data
python3 sim_new_nowave.py ../tests/isa/generated/rv32ui-p-add.bin inst.data

# Windows
python sim_new_nowave.py ..\tests\example\simple\simple.bin inst.data
```

成功时 stdout 会出现 `TEST_PASS`。

## sim_default_nowave.py

对已经存在的 `inst.data` 做仿真（不重新转 bin）。

```bash
python3 sim_default_nowave.py
```

## test_all_isa.py

测试 `../tests/isa/generated` 下全部指令 `.bin`。

```bash
python3 test_all_isa.py
```

## Verilator（C++ harness）

见 [verilator/README.md](verilator/README.md) 与仓库根目录 [LEARNING.md](../LEARNING.md)。

```bash
make -C verilator sim
```

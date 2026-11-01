加减乘除运算例程（仿真入门用）。

```bash
make                       # 或 make TOOLCHAIN_PREFIX=riscv64-unknown-elf-
# 然后在 sim/ 下：
python3 sim_new_nowave.py ../tests/example/simple/simple.bin inst.data
make -C ../../sim/verilator sim
```

详见 [docs/TUTORIAL_zh.md](../../../docs/TUTORIAL_zh.md)。
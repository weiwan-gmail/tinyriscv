# Verilator co-simulation

Minimal C++ testbench for the **existing** tinyriscv RTL on `develop` / `master`.
This is not a port of the upstream Gitee `verilator` branch (that branch rewrites
the bus, JTAG, and SoC). Firmware is the same `inst.data` image used by iverilog.

## Commands

```bash
# from repo root, after building a C example:
make -C tests/example/simple
make -C sim/verilator sim

# UART hello-world example (uart_tx):
make -C tests/example/uart_tx
make -C sim/verilator PROG=../../tests/example/uart_tx/uart_tx.bin EXPECT_UART=hello sim
```

Pass/fail matches the iverilog testbench: `over` is `~x26`, `succ` is `~x27`.
The C++ process returns 0 on `TEST_PASS`, 1 on `TEST_FAIL` / UART mismatch, 2 on timeout.

串口发送例程（打印 `hello world`，仿真时作为 hello 例程）。

`-DSIMULATION` 已打开：发完串口后 `set_test_pass()` 并返回，testbench 可以结束。

```bash
make -C tests/example/uart_tx
make -C sim/verilator PROG=../../tests/example/uart_tx/uart_tx.bin EXPECT_UART=hello sim
```
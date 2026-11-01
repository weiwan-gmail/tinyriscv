# Proven simulation logs

Captured on Ubuntu with Icarus Verilog 12.0, Verilator 5.020, and
`riscv64-unknown-elf-gcc` 13.2.0. These are raw command transcripts, not
hand-written expected output.

| File | What |
|------|------|
| `01-inspect.txt` | Repo map, reset PC, `start.S` x26/x27, tool versions |
| `02-build-simple.txt` | `TOOLCHAIN_PREFIX` detect + `make -C tests/example/simple` |
| `03-iverilog-simple.txt` | `TEST_PASS` for `simple.bin` |
| `04-verilator-simple.txt` | `TEST_PASS` for the same `simple.bin` |
| `05-iverilog-uart_tx.txt` | `TEST_PASS` for UART hello firmware |
| `05-verilator-uart_tx.txt` | `TEST_PASS` + `UART_EXPECT_PASS: found "hello"` |

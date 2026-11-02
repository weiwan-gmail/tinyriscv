# cmake-system Windows PASS evidence (PC2023 follow-up)

**Not run on PC2023 yet.** Linux VM proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).

Follow-up on worker **PC2023**, checkout `D:\CursorWorker\tinyriscv`:

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-system
powershell -File .\build_sim.ps1
```

Expected: same withlimon **`verilator_bin.exe`** PE (MZ `4D5A`), MSVC `-fcoroutines*` strip, `TEST_PASS` from `sim_tinyriscv`, `sim-fail` inject-and-catch. Rules: [`WINDOWS.md`](WINDOWS.md).

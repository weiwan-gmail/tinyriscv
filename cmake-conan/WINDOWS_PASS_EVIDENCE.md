# cmake-conan Windows PASS evidence (PC2023 follow-up)

**Not run on PC2023 yet.** Linux VM proof: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). cmake-system notes: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md).

Follow-up on worker **PC2023**, Conan **2.34** + withlimon PE:

```bat
cd /d D:\CursorWorker\tinyriscv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

Expected: local recipe `verilator/5.052` packages the PE kit (no Autotools rebuild); `TEST_PASS` + `sim-fail`.

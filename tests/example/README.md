本目录下都是C语言程序的例程。

目录介绍：

**gpio**: 该目录是控制GPIO输出的例程，每500ms翻转一下GPIO的电平。

**include**: 公共头文件目录。

**lib**: 公共函数目录。

**simple**: 简单的加减乘除运算测试例程。

**timer_int**: 定时器中断测试例程。

**uart_tx**: 串口发送测试例程，向串口发送hello world字符串。

本目录下所有的.c和.S文件是所有例程的公共文件，每一个例程都需要用到它们。

交叉编译工具链通过 `common.mk` 里的 **`TOOLCHAIN_PREFIX`** 选择（可自动探测 `riscv64-unknown-elf-` 等）。仿真与 Verilator 步骤见仓库根目录 [LEARNING.md](../../LEARNING.md)。
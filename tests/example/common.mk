# Portable RISC-V GNU toolchain selection.
#
# TOOLCHAIN_PREFIX is the compiler prefix, including any directory and the
# trailing dash. Examples:
#   TOOLCHAIN_PREFIX=riscv64-unknown-elf-
#   TOOLCHAIN_PREFIX=riscv-none-elf-
#   TOOLCHAIN_PREFIX=riscv-none-embed-
#   TOOLCHAIN_PREFIX=/opt/riscv/bin/riscv32-unknown-elf-
#
# Detection order if TOOLCHAIN_PREFIX is unset:
#   1. TOOLCHAIN_PREFIX from the environment
#   2. First of riscv64-unknown-elf- / riscv-none-elf- / riscv32-unknown-elf-
#      / riscv-none-embed- found on PATH
#   3. Legacy bundled Windows path under tools/gnu-mcu-eclipse-... (original
#      Baidu-disk layout from upstream README)
#
# Usage:
#   make
#   make TOOLCHAIN_PREFIX=riscv64-unknown-elf-

TOOLCHAIN_DIR ?= ../../..

ifndef TOOLCHAIN_PREFIX
  ifneq ($(shell command -v riscv64-unknown-elf-gcc 2>/dev/null),)
    TOOLCHAIN_PREFIX := riscv64-unknown-elf-
  else ifneq ($(shell command -v riscv-none-elf-gcc 2>/dev/null),)
    TOOLCHAIN_PREFIX := riscv-none-elf-
  else ifneq ($(shell command -v riscv32-unknown-elf-gcc 2>/dev/null),)
    TOOLCHAIN_PREFIX := riscv32-unknown-elf-
  else ifneq ($(shell command -v riscv-none-embed-gcc 2>/dev/null),)
    TOOLCHAIN_PREFIX := riscv-none-embed-
  else ifneq ($(wildcard $(TOOLCHAIN_DIR)/tools/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64/bin/riscv-none-embed-gcc$(EXE_EXT)),)
    TOOLCHAIN_PREFIX := $(abspath $(TOOLCHAIN_DIR)/tools/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64/bin)/riscv-none-embed-
  else
    $(error No RISC-V toolchain found. Install gcc-riscv64-unknown-elf or xpack riscv-none-elf-gcc, then re-run with TOOLCHAIN_PREFIX=<prefix>, e.g. TOOLCHAIN_PREFIX=riscv64-unknown-elf-)
  endif
endif

RISCV_GCC     := $(TOOLCHAIN_PREFIX)gcc
RISCV_AS      := $(TOOLCHAIN_PREFIX)as
RISCV_GXX     := $(TOOLCHAIN_PREFIX)g++
RISCV_OBJDUMP := $(TOOLCHAIN_PREFIX)objdump
RISCV_GDB     := $(TOOLCHAIN_PREFIX)gdb
RISCV_AR      := $(TOOLCHAIN_PREFIX)ar
RISCV_OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
RISCV_READELF := $(TOOLCHAIN_PREFIX)readelf

# GCC 10+ split Zicsr/Zifencei out of RV32I. tinyriscv start.S / init.c use CSR
# instructions, so append _zicsr when the assembler rejects a bare rv32im.
ifeq ($(findstring zicsr,$(RISCV_ARCH)),)
  CSR_AS_ERR := $(shell printf '%s\n' 'csrr x0, mstatus' | $(RISCV_GCC) -march=$(RISCV_ARCH) -mabi=$(RISCV_ABI) -x assembler -c -o /dev/null - 2>&1)
  ifneq ($(findstring zicsr,$(CSR_AS_ERR)),)
    RISCV_ARCH := $(RISCV_ARCH)_zicsr
  endif
endif

.PHONY: all
all: $(TARGET)

ASM_SRCS += $(COMMON_DIR)/start.S
ASM_SRCS += $(COMMON_DIR)/trap_entry.S
C_SRCS += $(COMMON_DIR)/init.c
C_SRCS += $(COMMON_DIR)/trap_handler.c
C_SRCS += $(COMMON_DIR)/lib/utils.c
C_SRCS += $(COMMON_DIR)/lib/xprintf.c
C_SRCS += $(COMMON_DIR)/lib/uart.c
C_SRCS += $(COMMON_DIR)/lib/flash_n25q.c
C_SRCS += $(COMMON_DIR)/lib/spi.c

LINKER_SCRIPT := $(COMMON_DIR)/link.lds

INCLUDES += -I$(COMMON_DIR)

# -nostdlib: these examples ship start.S and do not need newlib. Ubuntu's
# gcc-riscv64-unknown-elf package has no -lc/-lgloss; -nostartfiles alone fails.
LDFLAGS += -T $(LINKER_SCRIPT) -nostdlib -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump $(TARGET).bin

CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=$(RISCV_MCMODEL) -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) Makefile
	@echo "Using TOOLCHAIN_PREFIX=$(TOOLCHAIN_PREFIX) RISCV_ARCH=$(RISCV_ARCH)"
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump

$(ASM_OBJS): %.o: %.S
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -f $(CLEAN_OBJS)

.PHONY: toolchain-info
toolchain-info:
	@echo "TOOLCHAIN_PREFIX=$(TOOLCHAIN_PREFIX)"
	@echo "RISCV_GCC=$$(command -v $(RISCV_GCC) || echo $(RISCV_GCC))"
	@echo "RISCV_ARCH=$(RISCV_ARCH)"
	@$(RISCV_GCC) --version | head -n 1

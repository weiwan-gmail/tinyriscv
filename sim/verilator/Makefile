# HDL co-simulation for tinyriscv (master/develop RTL, not the
# upstream verilator-branch SoC rewrite).
#
#   make                        # build simple.bin, compile TB, run
#   make PROG=.../uart_tx.bin run
#   make TRACE=1 run            # dump wave.vcd (slow)

REPO_ROOT     := $(abspath ../..)
PROG          ?= $(REPO_ROOT)/tests/example/simple/simple.bin
PROG_DIR      := $(dir $(PROG))
VERILATOR     ?= verilator
OBJ_DIR       := obj_dir
TOP           := tb_verilator
CXX           ?= g++
PYTHON        ?= python3
MAX_CYCLES    ?= 2000000
EXPECT_UART   ?=
TRACE         ?= 0

BIN_TO_MEM    := $(REPO_ROOT)/tools/BinToMem_CLI.py

VERI_FLAGS := --cc --exe --build -j 0
VERI_FLAGS += --top-module $(TOP)
VERI_FLAGS += -f rtl.f
VERI_FLAGS += --Mdir $(OBJ_DIR)
VERI_FLAGS += --clk clk
VERI_FLAGS += -Wno-fatal
VERI_FLAGS += -Wno-UNOPTFLAT
VERI_FLAGS += -Wno-WIDTH
VERI_FLAGS += -Wno-CASEINCOMPLETE
VERI_FLAGS += -Wno-UNSIGNED
VERI_FLAGS += -Wno-PINMISSING
VERI_FLAGS += -Wno-TIMESCALEMOD
VERI_FLAGS += -Wno-IMPLICIT
VERI_FLAGS += -CFLAGS "-std=c++17 -O2"
VERI_FLAGS += tb_verilator.cpp

ifeq ($(TRACE),1)
VERI_FLAGS += --trace -CFLAGS "-DVM_TRACE=1"
endif

PLUSARGS := +max-cycles=$(MAX_CYCLES)
ifneq ($(EXPECT_UART),)
PLUSARGS += +expect-uart=$(EXPECT_UART)
endif

.PHONY: all sim run compile firmware hex clean help

all: sim

firmware:
	$(MAKE) -C $(PROG_DIR)

hex: firmware
	$(PYTHON) $(BIN_TO_MEM) $(PROG) inst.data

compile: $(OBJ_DIR)/V$(TOP)

$(OBJ_DIR)/V$(TOP): tb_verilator.cpp tb_verilator.v rtl.f
	$(VERILATOR) $(VERI_FLAGS)

run: compile hex
	./$(OBJ_DIR)/V$(TOP) $(PLUSARGS)

sim: run

clean:
	rm -rf $(OBJ_DIR) inst.data wave.vcd *.log

help:
	@echo 'make                          # sim tests/example/simple/simple.bin'
	@echo 'make PROG=<path/to/foo.bin>   # sim another firmware image'
	@echo 'make EXPECT_UART="hello" run  # also require UART substring'
	@echo 'make TRACE=1 run              # enable VCD (rebuild required)'
	@echo 'make clean'
	@echo 'TOOLCHAIN_PREFIX is used by the C examples, not this Makefile.'

// C++ harness for tinyriscv HDL co-simulation.
// Loads the same inst.data firmware as the iverilog testbench, clocks the SoC
// until x26/x27 (over/succ) report completion, and optionally prints UART TX.

#include "Vtb_verilator.h"
#include "verilated.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

static vluint64_t main_time = 0;

double sc_time_stamp() { return static_cast<double>(main_time); }

// 50 MHz clock, default UART divisor 0x1B8 = 440 -> ~113636 baud
static const int kUartDiv = 440;

struct UartRx {
    int sample = 0;
    int bit_idx = -1;  // -1 idle
    uint8_t shifter = 0;
    std::string text;

    void tick(int tx_pin) {
        if (bit_idx < 0) {
            if (tx_pin == 0) {
                bit_idx = 0;
                sample = kUartDiv / 2;  // sample mid start-bit next
                shifter = 0;
            }
            return;
        }
        if (--sample > 0) {
            return;
        }
        sample = kUartDiv;
        if (bit_idx == 0) {
            // start bit; if line bounced back high, abort
            if (tx_pin != 0) {
                bit_idx = -1;
                return;
            }
            bit_idx = 1;
            return;
        }
        if (bit_idx >= 1 && bit_idx <= 8) {
            if (tx_pin) {
                shifter |= static_cast<uint8_t>(1u << (bit_idx - 1));
            }
            bit_idx++;
            return;
        }
        // stop bit
        if (tx_pin == 1) {
            text.push_back(static_cast<char>(shifter));
            std::fputc(shifter, stdout);
            std::fflush(stdout);
        }
        bit_idx = -1;
    }
};

static void tick(Vtb_verilator* tb, UartRx* uart) {
    tb->clk = 0;
    tb->eval();
    main_time += 10;
    tb->clk = 1;
    tb->eval();
    main_time += 10;
    uart->tick(tb->uart_tx_pin);
}

static void print_banner(const char* title) {
    std::printf("~~~~~~~~~~~~~~~~~~~ %s ~~~~~~~~~~~~~~~~~~~\n", title);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    uint64_t max_cycles = 2000000;
    const char* expect_uart = nullptr;
    for (int i = 1; i < argc; i++) {
        if (std::strncmp(argv[i], "+max-cycles=", 12) == 0) {
            max_cycles = std::strtoull(argv[i] + 12, nullptr, 0);
        } else if (std::strncmp(argv[i], "+expect-uart=", 13) == 0) {
            expect_uart = argv[i] + 13;
        }
    }

    Vtb_verilator* tb = new Vtb_verilator;
    UartRx uart;

    // rst is active-low (defines.v: RstEnable = 0)
    tb->clk = 0;
    tb->rst = 0;
    tb->eval();
    for (int i = 0; i < 8; i++) {
        tick(tb, &uart);
    }
    tb->rst = 1;

    std::printf("test running (Verilator, max_cycles=%llu)...\n",
                static_cast<unsigned long long>(max_cycles));

    bool finished = false;
    uint64_t cycles = 0;
    for (cycles = 0; cycles < max_cycles; cycles++) {
        tick(tb, &uart);
        if (tb->over == 0) {
            finished = true;
            int extra = (uart.bit_idx >= 0 || !uart.text.empty())
                            ? (kUartDiv * 24)
                            : 16;
            for (int i = 0; i < extra; i++) {
                tick(tb, &uart);
            }
            break;
        }
    }

    int rc = 0;
    if (!finished) {
        print_banner("TEST_TIMEOUT");
        std::printf("over=%d succ=%d cycles=%llu\n", tb->over, tb->succ,
                    static_cast<unsigned long long>(cycles));
        rc = 2;
    } else if (tb->succ == 0) {
        print_banner("TEST_PASS");
        std::printf("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~\n");
        std::printf("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~\n");
        std::printf("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~\n");
        std::printf("~~~~~~~~~ #####   ######       #       #~~~~~~~~~\n");
        std::printf("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~\n");
        std::printf("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~\n");
        std::printf("cycles=%llu sim_time=%llu ns\n",
                    static_cast<unsigned long long>(cycles),
                    static_cast<unsigned long long>(main_time));
        rc = 0;
    } else {
        print_banner("TEST_FAIL");
        std::printf("over=%d succ=%d cycles=%llu\n", tb->over, tb->succ,
                    static_cast<unsigned long long>(cycles));
        rc = 1;
    }

    if (!uart.text.empty()) {
        std::printf("UART_TX: %s\n", uart.text.c_str());
    }
    if (expect_uart != nullptr) {
        if (uart.text.find(expect_uart) == std::string::npos) {
            std::printf("UART_EXPECT_FAIL: did not find \"%s\"\n", expect_uart);
            rc = 1;
        } else {
            std::printf("UART_EXPECT_PASS: found \"%s\"\n", expect_uart);
        }
    }

    tb->final();
    delete tb;
    return rc;
}

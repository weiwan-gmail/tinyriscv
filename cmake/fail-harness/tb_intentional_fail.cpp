// Intentional-fail harness for the CMake `sim-fail` target.
//
// DUT is cmake/fail-harness/fail_probe.v (identity, not a copy of the CPU).
// The checker demands y==1 for x==0 (true result is 0) so a working sim MUST
// print FAIL and exit 1. ExpectFail.cmake succeeds only when that failure
// is caught — same inject-and-catch idea as rtl-learning-plan / ProtoSim.

#include "Vfail_probe.h"
#include "verilated.h"

#include <cstdint>
#include <cstdio>

int main() {
    Verilated::commandArgs(0, static_cast<char**>(nullptr));
    Vfail_probe* t = new Vfail_probe;
    t->x = 0;
    t->eval();
    const uint8_t y = static_cast<uint8_t>(t->y);
    t->final();
    delete t;
    if (y != 1u) {
        std::printf("FAIL intentional mismatch (cmake sim-fail harness)\n");
        return 1;
    }
    std::printf("UNEXPECTED PASS sim-fail harness (checker did not fire)\n");
    return 0;
}

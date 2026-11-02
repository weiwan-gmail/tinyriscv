// Tiny identity used only by cmake/fail-harness (not tinyriscv SoC RTL).
// A working DUT yields y==x. The C++ checker demands y==1 for x==0 so
// the process prints FAIL and exits 1; ExpectFail.cmake succeeds then.
module fail_probe (
    input  wire [7:0] x,
    output wire [7:0] y
);
    assign y = x;
endmodule

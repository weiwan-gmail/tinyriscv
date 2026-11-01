// C++ co-sim wrapper around tinyriscv_soc_top.
// Does not change the CPU RTL: it only ties unused pins and exposes the
// existing over/succ/uart_tx_pin SoC ports to the C++ harness.

`include "defines.v"

module tb_verilator (
    input  wire clk,
    input  wire rst,
    output wire over,
    output wire succ,
    output wire uart_tx_pin
);

    wire [1:0] gpio;
    wire halted_ind;
    wire jtag_TDO;
    wire spi_mosi;
    wire spi_ss;
    wire spi_clk;

    tinyriscv_soc_top dut (
        .clk(clk),
        .rst(rst),
        .over(over),
        .succ(succ),
        .halted_ind(halted_ind),
        .uart_debug_pin(1'b0),
        .uart_tx_pin(uart_tx_pin),
        .uart_rx_pin(1'b1),
        .gpio(gpio),
        .jtag_TCK(1'b0),
        .jtag_TMS(1'b1),
        .jtag_TDI(1'b1),
        .jtag_TDO(jtag_TDO),
        .spi_miso(1'b0),
        .spi_mosi(spi_mosi),
        .spi_ss(spi_ss),
        .spi_clk(spi_clk)
    );

    initial begin
        $readmemh("inst.data", dut.u_rom._rom);
    end

endmodule

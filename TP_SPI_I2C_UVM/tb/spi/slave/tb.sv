`include "uvm_macros.svh"
import uvm_pkg::*;

`include "./spi/slave/agent.sv"
`include "./spi/slave/coverage.sv"
`include "./spi/slave/driver.sv"
`include "./spi/slave/env.sv"
`include "./spi/slave/interface.sv"
`include "./spi/slave/monitor.sv"
`include "./spi/slave/scoreboard.sv"
`include "./spi/slave/seq_item.sv"
`include "./spi/slave/sequence.sv"
`include "./spi/slave/test.sv"

module tb_spi_slave ();

	logic clk, reset;

	always #5 clk = ~clk;

	spi_slave_if vif(clk, reset);

	localparam CPOL = 0;
    localparam CPHA = 0;

	spi_slave #(
	    .CPOL(CPOL),
	    .CPHA(CPHA)
	) dut (
	    .clk		(clk),
	    .reset		(reset),
	    .SCLK		(vif.SCLK),
	    .MOSI		(vif.MOSI),
	    .MISO		(vif.MISO),
	    .CS_n		(vif.CS_n),
	    .tx_updata	(vif.tx_updata),
	    .tx_data	(vif.tx_data),
	    .rx_data	(vif.rx_data),
	    .rx_done	(vif.rx_done),
	    .busy		(vif.busy)
	);

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_spi_slave, "+all");
	end

	initial begin
		clk = 0; reset = 1;
		repeat(5) @(posedge clk);
		reset = 0;
	end

    initial begin
		uvm_config_db#(virtual spi_slave_if)::set(null, "*", "vif", vif);
		run_test();
	end

endmodule

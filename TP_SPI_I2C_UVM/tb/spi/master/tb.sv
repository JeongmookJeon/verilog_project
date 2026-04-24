`include "uvm_macros.svh"
import uvm_pkg::*;

`include "./spi/master/agent.sv"
`include "./spi/master/coverage.sv"
`include "./spi/master/driver.sv"
`include "./spi/master/env.sv"
`include "./spi/master/interface.sv"
`include "./spi/master/monitor.sv"
`include "./spi/master/scoreboard.sv"
`include "./spi/master/seq_item.sv"
`include "./spi/master/sequence.sv"
`include "./spi/master/test.sv"

module tb_spi_master ();

	logic clk, reset, cpol, cpha;
	logic [7:0] clk_div;

	always #5 clk = ~clk;

	spi_master_if vif(clk, reset, cpol, cpha, clk_div);

	spi_master dut (
	    .clk		(clk),
	    .reset		(reset),
	    .cpol		(cpol),
	    .cpha		(cpha),
	    .clk_div	(clk_div),
	    .tx_data	(vif.tx_data),
	    .start		(vif.start),
	    .rx_data	(vif.rx_data),
	    .done		(vif.done),
	    .busy		(vif.busy),
	    .sclk		(vif.sclk),
	    .mosi		(vif.mosi),
	    .miso		(vif.miso),
	    .cs_n		(vif.cs_n)
	);

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_spi_master, "+all");
	end

	initial begin
		clk = 0; reset = 1; cpol = 0; cpha = 0; clk_div = 4;
		repeat(5) @(posedge clk);
		reset = 0;
	end

    initial begin
		uvm_config_db#(virtual spi_master_if)::set(null, "*", "vif", vif);
		run_test();
	end

endmodule

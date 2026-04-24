`include "uvm_macros.svh"
import uvm_pkg::*;

`include "./i2c/agent.sv"
`include "./i2c/coverage.sv"
`include "./i2c/driver.sv"
`include "./i2c/env.sv"
`include "./i2c/interface.sv"
`include "./i2c/monitor.sv"
`include "./i2c/scoreboard.sv"
`include "./i2c/seq_item.sv"
`include "./i2c/sequence.sv"
`include "./i2c/test.sv"

module tb_i2c ();

	logic clk, reset;
	wire scl;
	tri1 sda;
	localparam ADDR = 7'h12;

	always #5 clk = ~clk;

	i2c_if vif(clk, reset);

	I2C_Master dut_master (
	    .clk		(clk),
	    .reset		(reset),
	    .cmd_start  (vif.cmd_start),
	    .cmd_write  (vif.cmd_write),
	    .cmd_read	(vif.cmd_read),
	    .cmd_stop	(vif.cmd_stop),
	    .tx_data	(vif.m_tx_data),
	    .ack_in		(vif.m_ack_in),
	    .rx_data	(vif.m_rx_data),
	    .done		(vif.m_done),
	    .ack_out	(vif.m_ack_out),
	    .busy		(vif.m_busy),
	    .scl		(scl),
	    .sda		(sda)
	);

	i2c_slave #( .ADDR(ADDR) ) dut_slave (
		.clk				(clk),
		.reset				(reset),
		.tx_data			(vif.s_tx_data),
		.tx_update			(vif.s_tx_update),
		.tx_insert_enable	(vif.s_tx_insert_enable),
		.rx_data			(vif.s_rx_data),
		.rx_valid			(vif.s_rx_valid),
		.busy				(vif.s_busy),
		.SCL				(scl),
		.SDA				(sda)
	);

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_i2c, "+all");
	end

	initial begin
		clk = 0; reset = 1;
		repeat(5) @(posedge clk);
		reset = 0;
	end

    initial begin
		uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", vif);
		run_test();
	end

endmodule

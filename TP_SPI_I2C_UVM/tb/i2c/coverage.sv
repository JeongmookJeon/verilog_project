`ifndef I2C_COVERAGE_SV
`define I2C_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"

class i2c_coverage extends uvm_subscriber#(i2c_signal_seq_item);
	`uvm_component_utils(i2c_coverage)

	i2c_signal_seq_item tx;
	
	covergroup i2c_cg;
		cp_tx_data : coverpoint tx.s_rx_data {
			bins data_low      = {[8'h00 : 8'h3F]};
			bins data_mid_low  = {[8'h40 : 8'h7F]};
			bins data_mid_high = {[8'h80 : 8'hBF]};
			bins data_high     = {[8'hC0 : 8'hFF]};
		}
		
		cp_rx_data : coverpoint tx.m_rx_data {
			bins data_low      = {[8'h00 : 8'h3F]};
			bins data_mid_low  = {[8'h40 : 8'h7F]};
			bins data_mid_high = {[8'h80 : 8'hBF]};
			bins data_high     = {[8'hC0 : 8'hFF]};
		}
	endgroup // i2c_cg

	function new(string name, uvm_component parent);
		super.new(name, parent);
		i2c_cg = new();
	endfunction // new()

	virtual function void write(i2c_signal_seq_item t);
		tx = t;
		i2c_cg.sample();
	endfunction // write

	virtual function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "********** Coverage Summary **********", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	Overall        : %.1f%%", i2c_cg.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	RX Data : %.1f%%", i2c_cg.cp_tx_data.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	TX Data : %.1f%%", i2c_cg.cp_rx_data.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), "********** Coverage Summary **********", UVM_LOW)
	endfunction // report_phase

endclass // i2c_coverage

`endif


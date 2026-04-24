`ifndef SPI_SLAVE_COVERAGE_SV
`define SPI_SLAVE_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"

class spi_slave_coverage extends uvm_subscriber#(spi_slave_signal_seq_item);
	`uvm_component_utils(spi_slave_coverage)

	spi_slave_signal_seq_item tx;
	
	covergroup spi_slave_cg;
		cp_tx_data : coverpoint tx.tx_data {
			bins data_low      = {[8'h00 : 8'h3F]};
			bins data_mid_low  = {[8'h40 : 8'h7F]};
			bins data_mid_high = {[8'h80 : 8'hBF]};
			bins data_high     = {[8'hC0 : 8'hFF]};
		}
		
		cp_rx_data : coverpoint tx.rx_data {
			bins data_low      = {[8'h00 : 8'h3F]};
			bins data_mid_low  = {[8'h40 : 8'h7F]};
			bins data_mid_high = {[8'h80 : 8'hBF]};
			bins data_high     = {[8'hC0 : 8'hFF]};
		}
	endgroup // spi_slave_cg

	function new(string name, uvm_component parent);
		super.new(name, parent);
		spi_slave_cg = new();
	endfunction // new()

	virtual function void write(spi_slave_signal_seq_item t);
		tx = t;
		spi_slave_cg.sample();
	endfunction // write

	virtual function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "********** Coverage Summary **********", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	Overall        : %.1f%%", spi_slave_cg.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	RX Data : %.1f%%", spi_slave_cg.cp_tx_data.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("	TX Data : %.1f%%", spi_slave_cg.cp_rx_data.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), "********** Coverage Summary **********", UVM_LOW)
	endfunction // report_phase

endclass // spi_slave_coverage

`endif


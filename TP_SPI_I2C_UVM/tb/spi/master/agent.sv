`ifndef SPI_MASTER_AGENT_SV
`define SPI_MASTER_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/master/seq_item.sv"
`include "./spi/master/driver.sv"
`include "./spi/master/monitor.sv"

typedef uvm_sequencer#(spi_master_inst_seq_item) spi_master_sequencer;

class spi_master_agent extends uvm_agent;
	`uvm_component_utils(spi_master_agent)

	spi_master_sequencer sqr;
	spi_master_driver    drv;
	spi_master_monitor   mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sqr = spi_master_sequencer::type_id::create("sqr", this);
		drv = spi_master_driver::type_id::create   ("drv", this);
		mon = spi_master_monitor::type_id::create  ("mon", this);
	endfunction // build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction // connect_phase

endclass // spi_master_agent

`endif


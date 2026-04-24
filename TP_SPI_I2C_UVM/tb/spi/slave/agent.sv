`ifndef SPI_SLAVE_AGENT_SV
`define SPI_SLAVE_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"
`include "./spi/slave/driver.sv"
`include "./spi/slave/monitor.sv"

typedef uvm_sequencer#(spi_slave_inst_seq_item) spi_slave_sequencer;

class spi_slave_agent extends uvm_agent;
	`uvm_component_utils(spi_slave_agent)

	spi_slave_sequencer sqr;
	spi_slave_driver    drv;
	spi_slave_monitor   mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sqr = spi_slave_sequencer::type_id::create("sqr", this);
		drv = spi_slave_driver::type_id::create   ("drv", this);
		mon = spi_slave_monitor::type_id::create  ("mon", this);
	endfunction // build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction // connect_phase

endclass // spi_slave_agent

`endif


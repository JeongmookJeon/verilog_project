`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"
`include "./i2c/driver.sv"
`include "./i2c/monitor.sv"

typedef uvm_sequencer#(i2c_inst_seq_item) i2c_sequencer;

class i2c_agent extends uvm_agent;
	`uvm_component_utils(i2c_agent)

	i2c_sequencer sqr;
	i2c_driver    drv;
	i2c_monitor   mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sqr = i2c_sequencer::type_id::create("sqr", this);
		drv = i2c_driver::type_id::create   ("drv", this);
		mon = i2c_monitor::type_id::create  ("mon", this);
	endfunction // build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction // connect_phase

endclass // i2c_agent

`endif


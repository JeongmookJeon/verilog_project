`ifndef COMPONENT_SV
`define COMPONENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class component extends uvm_component;
	`uvm_component_utils(component)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction // build_phase

	virtual function void connect_phase(uvm_phase phase);

	endfunction // connect_phase

	virtual task run_phase(uvm_phase phase);

	endtask // run_phase

	virtual function void report_phase(uvm_phase phase);

	endfunction // report_phase

endclass // component

`endif


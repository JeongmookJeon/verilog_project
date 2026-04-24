`ifndef SPI_SLAVE_TEST_SV
`define SPI_SLAVE_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/sequence.sv"

class spi_slave_base_test extends uvm_test;
	`uvm_component_utils(spi_slave_base_test)

	spi_slave_env env;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = spi_slave_env::type_id::create("env", this);
	endfunction // build_phase

	virtual function void end_of_elaboration_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "===== Structure of UVM Hierarchy =====", UVM_MEDIUM)
		uvm_top.print_topology();
	endfunction // end_of_elaboration_phase

	virtual task run_phase(uvm_phase phase);

	endtask // run_phase

endclass // spi_slave_base_test

class spi_slave_rand_test extends spi_slave_base_test;
	`uvm_component_utils(spi_slave_rand_test)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual task run_phase(uvm_phase phase);
		spi_slave_rand_sequence seq;
		phase.raise_objection(this);
		seq = spi_slave_rand_sequence::type_id::create("seq");
		seq.num_loop = 512;
		seq.start(env.agt.sqr);
		phase.drop_objection(this);
	endtask // run_phase

endclass // spi_slave_rand_test

`endif


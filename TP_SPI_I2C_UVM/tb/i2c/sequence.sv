`ifndef I2C_SEQUENCE_SV
`define I2C_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"

class i2c_rand_sequence extends uvm_sequence#(i2c_inst_seq_item);
	`uvm_object_utils(i2c_rand_sequence)

	int num_loop = 0;

	function new(string name = "I2C_RAND_SEQ");
		super.new(name);
		num_loop = 0;
	endfunction // new()

	virtual task body();
		repeat(num_loop) begin
			i2c_inst_seq_item item;
			
			item = i2c_inst_seq_item::type_id::create("INST_ITEM");
			start_item(item);
			if (!item.randomize())
				`uvm_fatal(get_type_name(), "Fail inst item RANDOMIZE!!!")
			finish_item(item);
			//`uvm_info(get_type_name(), $sformatf("transfer: tx-0x%02h rx-0x%02h", item.mosi_data, item.miso_data), UVM_MEDIUM)
		end
	endtask // body

endclass // i2c_rand_sequence

`endif


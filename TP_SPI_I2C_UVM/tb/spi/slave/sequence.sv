`ifndef SPI_SLAVE_SEQUENCE_SV
`define SPI_SLAVE_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"

class spi_slave_rand_sequence extends uvm_sequence#(spi_slave_inst_seq_item);
	`uvm_object_utils(spi_slave_rand_sequence)

	int num_loop = 0;

	function new(string name = "SPI_SLAVE_RAND_SEQ");
		super.new(name);
		num_loop = 0;
	endfunction // new()

	virtual task body();
		repeat(num_loop) begin
			spi_slave_inst_seq_item item;
			
			item = spi_slave_inst_seq_item::type_id::create("INST_ITEM");
			start_item(item);
			if (!item.randomize())
				`uvm_fatal(get_type_name(), "Fail inst item RANDOMIZE!!!")
			finish_item(item);
			`uvm_info(get_type_name(), $sformatf("transfer: tx-0x%02h rx-0x%02h", item.tx_data, item.rx_data), UVM_MEDIUM)
		end
	endtask // body

endclass // spi_slave_rand_sequence

`endif


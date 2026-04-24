`ifndef SPI_MASTER_SEQ_ITEM_SV
`define SPI_MASTER_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_master_inst_seq_item extends uvm_sequence_item;
	rand logic [7:0] miso_data;
	rand logic [7:0] mosi_data;

	`uvm_object_utils_begin(spi_master_inst_seq_item)
		`uvm_field_int(miso_data, UVM_ALL_ON)
		`uvm_field_int(mosi_data, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "SPI_MASTER_INST_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		return $sformatf("slave: MISO=0x%02h / MOSI=0x%02h", miso_data, mosi_data);
	endfunction // cnvt2str

endclass // spi_master_inst_seq_item

class spi_master_signal_seq_item extends uvm_sequence_item;
	logic [7:0] tx_data;
	logic       start;
	logic [7:0] rx_data;
	logic       done;
	logic       busy;
	logic       sclk;
	logic       mosi;
	logic       miso;
	logic       cs_n;

	`uvm_object_utils_begin(spi_master_signal_seq_item)
		`uvm_field_int(tx_data, UVM_ALL_ON)
		`uvm_field_int(start,   UVM_ALL_ON)
		`uvm_field_int(rx_data, UVM_ALL_ON)
		`uvm_field_int(done,    UVM_ALL_ON)
		`uvm_field_int(busy,    UVM_ALL_ON)
		`uvm_field_int(sclk,    UVM_ALL_ON)
		`uvm_field_int(mosi,    UVM_ALL_ON)
		`uvm_field_int(miso,    UVM_ALL_ON)
		`uvm_field_int(cs_n,    UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "SPI_MASTER_SIGNAL_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		return $sformatf(
			"tx_data=0x%02h start=%b / rx_data=0x%02h done=%b busy=%b / sclk=%b mosi=%b miso=%b cs_n=%b", 
			tx_data, start, rx_data, done, busy, sclk, mosi, miso, cs_n);
	endfunction // cnvt2str

endclass // spi_master_signal_seq_item

`endif


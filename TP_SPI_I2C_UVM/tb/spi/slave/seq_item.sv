`ifndef SPI_SLAVE_SEQ_ITEM_SV
`define SPI_SLAVE_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_slave_inst_seq_item extends uvm_sequence_item;
	rand logic [7:0] rx_data;
	rand logic [7:0] tx_data;

	`uvm_object_utils_begin(spi_slave_inst_seq_item)
		`uvm_field_int(rx_data, UVM_ALL_ON)
		`uvm_field_int(tx_data, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "SPI_SLAVE_INST_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		return $sformatf("slave: rx_data=0x%02h / tx_data=0x%02h", rx_data, tx_data);
	endfunction // cnvt2str

endclass // spi_slave_inst_seq_item

class spi_slave_signal_seq_item extends uvm_sequence_item;
    logic       SCLK;
    logic       MOSI;
    logic       MISO;
    logic       CS_n;
    logic       tx_updata;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       busy;

	`uvm_object_utils_begin(spi_slave_signal_seq_item)
		`uvm_field_int(SCLK, UVM_ALL_ON)
		`uvm_field_int(MOSI, UVM_ALL_ON)
		`uvm_field_int(MISO, UVM_ALL_ON)
		`uvm_field_int(CS_n, UVM_ALL_ON)
		`uvm_field_int(tx_updata, UVM_ALL_ON)
		`uvm_field_int(tx_data, UVM_ALL_ON)
		`uvm_field_int(rx_data, UVM_ALL_ON)
		`uvm_field_int(rx_done, UVM_ALL_ON)
		`uvm_field_int(busy, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "SPI_SLAVE_SIGNAL_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		return $sformatf(
			"SCLK=%b MOSI=%b MISO=%b CS_n=%b / tx_data=0x%02h tx_updata=%b / rx_data=0x%02h rx_done=%b / busy=%b", 
			SCLK, MOSI, MISO, CS_n, tx_data, tx_updata, rx_data, rx_done, busy);
	endfunction // cnvt2str

endclass // spi_slave_signal_seq_item

`endif


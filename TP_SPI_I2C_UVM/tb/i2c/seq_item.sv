`ifndef I2C_SEQ_ITEM_SV
`define I2C_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class i2c_inst_seq_item extends uvm_sequence_item;
	rand logic [6:0] addr;
	rand logic       wr;
	rand logic [3:0] data_cnt;
	rand logic [7:0] data;
	
	constraint c_addr {addr == 7'h12;}

	`uvm_object_utils_begin(i2c_inst_seq_item)
		`uvm_field_int(addr, UVM_ALL_ON)
		`uvm_field_int(wr, UVM_ALL_ON)
		`uvm_field_int(data_cnt, UVM_ALL_ON)
		`uvm_field_int(data, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "I2C_INST_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		string wr_indicate = (wr)? "READ" : "WRITE";
		return $sformatf("-%s- addr: 0x%02h / data*%d: 0x%02h ~ 0x%02h",
						 wr_indicate, addr, data_cnt+1, data, data+data_cnt);
	endfunction // cnvt2str

endclass // i2c_inst_seq_item

class i2c_signal_seq_item extends uvm_sequence_item;

    // master command port
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       m_ack_in;
    // master internal output
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       m_ack_out;
    logic       m_busy;
    // slave Control/Status
    logic [7:0] s_tx_data;
    logic       s_tx_update;
    logic       s_tx_insert_enable;
    logic [7:0] s_rx_data;
    logic       s_rx_valid;
    logic       s_busy;

	`uvm_object_utils_begin(i2c_signal_seq_item)
		`uvm_field_int(cmd_start, UVM_ALL_ON)
		`uvm_field_int(cmd_write, UVM_ALL_ON)
		`uvm_field_int(cmd_read, UVM_ALL_ON)
		`uvm_field_int(cmd_stop, UVM_ALL_ON)
		`uvm_field_int(m_tx_data, UVM_ALL_ON)
		`uvm_field_int(m_ack_in, UVM_ALL_ON)
		`uvm_field_int(m_rx_data, UVM_ALL_ON)
		`uvm_field_int(m_done, UVM_ALL_ON)
		`uvm_field_int(m_ack_out, UVM_ALL_ON)
		`uvm_field_int(m_busy, UVM_ALL_ON)
		`uvm_field_int(s_tx_data, UVM_ALL_ON)
		`uvm_field_int(s_tx_update, UVM_ALL_ON)
		`uvm_field_int(s_tx_insert_enable, UVM_ALL_ON)
		`uvm_field_int(s_rx_data, UVM_ALL_ON)
		`uvm_field_int(s_rx_valid, UVM_ALL_ON)
		`uvm_field_int(s_busy, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "I2C_SIGNAL_SEQ_ITEM");
		super.new(name);
	endfunction // new()

	function string cnvt2str();
		return $sformatf(
			"-cmd- START:%b WRITE:%b READ:%b STOP:%b | -master tx- tx_data:0x%02h ack_in:%b | -master rx- rx_data:0x%02h done:%b ack_out:%b busy:%b | -slave- tx_data:0x%02h tx_update:%b tx_insert_enable:%b rx_data:0x%02h rx_valid:%b busy:%b", 
			cmd_start, cmd_write, cmd_read, cmd_stop,
			m_tx_data, m_ack_in,
			m_rx_data, m_done, m_ack_out, m_busy,
			s_tx_data, s_tx_update, s_tx_insert_enable,
			s_rx_data, s_rx_valid, s_busy);
	endfunction // cnvt2str

endclass // i2c_signal_seq_item

`endif


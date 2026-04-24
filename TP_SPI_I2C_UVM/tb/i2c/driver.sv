`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"
`include "./i2c/interface.sv"

class i2c_driver extends uvm_driver #(i2c_inst_seq_item);
	`uvm_component_utils(i2c_driver)

	virtual i2c_if vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Driver CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		vif.cmd_start = 1'b0;
		vif.cmd_write = 1'b0;
		vif.cmd_read = 1'b0;
		vif.cmd_stop = 1'b0;
		vif.m_tx_data = 0;
		vif.m_ack_in = 1'b0;
		vif.s_tx_data = 0;
		vif.s_tx_update = 1'b0;
		wait(vif.reset == 1);
		`uvm_info(get_type_name(), "End Reset", UVM_MEDIUM)
		
		wait (vif.reset == 0);

		forever begin
			i2c_inst_seq_item tx;
			seq_item_port.get_next_item(tx);
			drive_i2c(tx);
			seq_item_port.item_done();
		end
	endtask // run_phase

	task drive_i2c(i2c_inst_seq_item tx);
		// Start
		@(vif.drv_cb);
		vif.cmd_start = 1'b1; 
		@(vif.drv_cb);
		vif.cmd_start = 1'b0;
		wait(vif.m_done);
		// Address
		vif.m_tx_data = {tx.addr, tx.wr};
		@(vif.drv_cb);
		vif.cmd_write = 1'b1; 
		@(vif.drv_cb);
		vif.cmd_write = 1'b0;
		wait(vif.m_done);
		// Data Transaction
		vif.m_ack_in = 0;
		for (int dcnt = 0; dcnt <= tx.data_cnt; dcnt++) begin
			if (tx.wr == 1'b0) begin // write
				vif.m_tx_data = tx.data + dcnt;
				@(vif.drv_cb);
				vif.cmd_write = 1'b1; 
				@(vif.drv_cb);
				vif.cmd_write = 1'b0;
				wait(vif.m_done);
				wait(vif.s_rx_valid);
			end
			else begin // read
				if (dcnt == tx.data_cnt) vif.m_ack_in = 1;
				vif.s_tx_data = tx.data + dcnt;
				@(vif.drv_cb);
				vif.cmd_read = 1'b1; 
				@(vif.drv_cb);
				vif.cmd_read = 1'b0;
				wait(vif.s_tx_insert_enable);
				vif.s_tx_update = 1'b1;
				@(vif.drv_cb);
				vif.s_tx_update = 1'b0;
				@(vif.drv_cb);
				wait(vif.m_done);
			end
		end
		// Stop
		@(vif.drv_cb);
		vif.cmd_stop = 1'b1; 
		@(vif.drv_cb);
		vif.cmd_stop = 1'b0;
		wait(vif.m_done);
		@(vif.drv_cb);

	endtask // drive_i2c

endclass // i2c_driver

`endif


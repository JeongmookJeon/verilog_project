`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"
`include "./i2c/interface.sv"

class i2c_monitor extends uvm_monitor;
	`uvm_component_utils(i2c_monitor)

	uvm_analysis_port #(i2c_signal_seq_item) ap;
	virtual i2c_if vif;

	bit       run_trans = 0;
	bit       last_sclk = 0;
	bit [3:0] data_cnt  = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new("ap",this);
		if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Monitor CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "Start Monitoring...", UVM_MEDIUM)

		forever begin
			catch_i2c();
		end
	endtask // run_phase

	task catch_i2c();
		i2c_signal_seq_item tx;
		bit trans = 0;

		@(vif.mon_cb);
		
		if (vif.cmd_start) trans = 1;
		if (vif.cmd_write) trans = 1;
		if (vif.cmd_read)  trans = 1;
		if (vif.cmd_stop)  trans = 1;

		if (vif.m_done)      trans = 1;
		if (vif.s_rx_valid)  trans = 1;
		
		if (trans) begin
			tx 			 = i2c_signal_seq_item::type_id::create("mon_tx");
			tx.cmd_start = vif.cmd_start;
			tx.cmd_write = vif.cmd_write;
			tx.cmd_read = vif.cmd_read;
			tx.cmd_stop = vif.cmd_stop;
			tx.m_tx_data = vif.m_tx_data;
			tx.m_ack_in = vif.m_ack_in;
			tx.m_rx_data = vif.m_rx_data;
			tx.m_done = vif.m_done;
			tx.m_ack_out = vif.m_ack_out;
			tx.m_busy = vif.m_busy;
			tx.s_tx_data = vif.s_tx_data;
			tx.s_tx_update = vif.s_tx_update;
			tx.s_tx_insert_enable = vif.s_tx_insert_enable;
			tx.s_rx_data = vif.s_rx_data;
			tx.s_rx_valid = vif.s_rx_valid;
			tx.s_busy = vif.s_busy;
			`uvm_info(get_type_name(), $sformatf("mon tx: %s", tx.cnvt2str()), UVM_MEDIUM)
			ap.write(tx);
		end
	endtask // catch_i2c

endclass // i2c_monitor

`endif


`ifndef I2C_SCOREBOARD_SV
`define I2C_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./i2c/seq_item.sv"

class i2c_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(i2c_scoreboard)

	uvm_analysis_imp #(i2c_signal_seq_item, i2c_scoreboard) ap_imp;

	int pass_cnt = 0;
	int fail_cnt = 0;

	bit fail;

	bit cmd_start = 0;
	bit cmd_write = 0;
	bit cmd_read = 0;
	bit cmd_stop = 0;
	bit is_read = 0;
	bit is_nack = 0;

	byte data = 0;
	
	typedef enum logic [1:0] {
		IDLE = 2'b00,
		ADDR,
		TRANSACTION
	} stage_e;

	stage_e stage = IDLE;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap_imp = new("ap_imp", this);
	endfunction // build_phase

	virtual function void write(i2c_signal_seq_item signal);
		fail = 1'b0;

		if (cmd_start || cmd_write || cmd_read || cmd_stop) begin
			case({cmd_start, cmd_write, cmd_read, cmd_stop})
				4'b1000: begin
					if (signal.m_done) begin
						`uvm_info(get_type_name(), "Successful i2c START!!", UVM_MEDIUM)
						cmd_start = 0;
					end
					else begin
						`uvm_error(get_type_name(), "Fail i2c START..")
						fail = 1'b1;
					end
				end
				4'b0100: begin
					if (signal.s_rx_valid) begin
						if (data === signal.s_rx_data) begin
							`uvm_info(get_type_name(), "Successful i2c WRITE!!", UVM_MEDIUM)
						end
						else begin
							`uvm_error(get_type_name(), "Fail i2c WRITE..")
							fail = 1'b1;
						end
						cmd_write = 0;
					end
					else if (signal.m_done) begin
						if (stage == ADDR) begin
							`uvm_info(get_type_name(), "Successful i2c ADDRESS!!", UVM_MEDIUM)
							cmd_write = 0;
						end
					end
					else begin
						if (stage == ADDR) `uvm_error(get_type_name(), "Fail i2c ADDRESS..")
						if (stage == TRANSACTION) `uvm_error(get_type_name(), "Fail i2c WRITE..")
						fail = 1'b1;
					end
				end
				4'b0010: begin
					if (signal.m_done) begin
						cmd_read = 0;
						if (data === signal.m_rx_data) begin
							`uvm_info(get_type_name(), "Successful i2c READ!!", UVM_MEDIUM)
						end
						else begin
							`uvm_error(get_type_name(), "Fail i2c READ..")
							fail = 1'b1;
						end
					end
					else begin
						`uvm_error(get_type_name(), "Fail i2c READ..")
						fail = 1'b1;
					end
				end
				4'b0001: begin
					cmd_stop = 0;
					if (signal.m_done) begin
						`uvm_info(get_type_name(), "Successful i2c Transaction!!", UVM_MEDIUM)
						pass_cnt++;
					end
					else begin
						`uvm_error(get_type_name(), "Fail i2c Transaction..")
						fail = 1'b1;
					end
				end
				default: begin
					`uvm_error(get_type_name(), "Unknown Action..")
					fail = 1'b1;
				end
			endcase
		end
		else if ((cmd_start || cmd_write || cmd_read || cmd_stop) == 0) begin
			if (signal.cmd_start) begin cmd_start = 1; stage = IDLE; end
			if (signal.cmd_write) begin
				cmd_write = 1; stage = (stage == IDLE)? ADDR : TRANSACTION;
				data = signal.m_tx_data;
			end
			if (signal.cmd_read) begin
				cmd_read = 1; stage = TRANSACTION;
				data = signal.s_tx_data;
			end
			if (signal.cmd_stop) begin cmd_stop = 1; stage = IDLE; end
		end

		if (fail) fail_cnt++;
	endfunction // write

	virtual function void report_phase(uvm_phase phase);
		string result = (fail_cnt == 0) ? "** PASS **" : "** FAIL **";
		`uvm_info(get_type_name(), "********** summary report **********", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("Result : %s", result),       UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("pass num : %0d", pass_cnt),  UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("error num : %0d", fail_cnt), UVM_LOW)
		`uvm_info(get_type_name(), "************************************", UVM_LOW)
	endfunction // report_phase

endclass // i2c_scoreboard

`endif


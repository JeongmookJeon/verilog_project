`ifndef SPI_SLAVE_SCOREBOARD_SV
`define SPI_SLAVE_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"

class spi_slave_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(spi_slave_scoreboard)

	uvm_analysis_imp #(spi_slave_signal_seq_item, spi_slave_scoreboard) ap_imp;

	int pass_cnt = 0;
	int fail_cnt = 0;

	bit transaction = 0;
	bit [3:0] trans_cnt = 0;
	bit [7:0] miso_bit = 0;
	bit [7:0] mosi_bit = 0;
	bit fail_now = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap_imp = new("ap_imp", this);
	endfunction // build_phase

	virtual function void write(spi_slave_signal_seq_item signal);
		if (signal.rx_done) begin
			transaction = 0;
			if (trans_cnt !== 4'd8) `uvm_error(get_type_name(), "Unknown Action: Less data..")
			else begin
				fail_now = 0;
				trans_cnt = 0;
				// Check TX
				if (miso_bit !== signal.tx_data) begin
					`uvm_error(get_type_name(), $sformatf("FAIL) Mismatch miso(0x%02h) and tx_data(0x%02h)",
														  miso_bit, signal.tx_data));
					fail_now = 1;
				end
				else `uvm_info(get_type_name(), $sformatf("pass) Match miso(0x%02h) and tx_data(0x%02h)",
														  miso_bit, signal.tx_data), UVM_LOW);
				
				// Check RX
				if (mosi_bit !== signal.rx_data) begin
					`uvm_error(get_type_name(), $sformatf("FAIL) Mismatch mosi(0x%02h) and rx_data(0x%02h)",
														  mosi_bit, signal.rx_data));
					fail_now = 1;
				end
				else `uvm_info(get_type_name(), $sformatf("pass) Match mosi(0x%02h) and rx_data(0x%02h)",
														  mosi_bit, signal.rx_data), UVM_LOW);
				
				if (fail_now) fail_cnt++;
				else          pass_cnt++;
			end
		end
		else begin
			miso_bit[7-trans_cnt] = signal.MISO;
			mosi_bit[7-trans_cnt] = signal.MOSI;
			`uvm_info(get_type_name(), $sformatf("trans_cnt: %d - MISO %b 0b%08b / MOSI %b 0b%08b", 
												trans_cnt, signal.MISO, miso_bit, signal.MOSI, mosi_bit), UVM_MEDIUM)
			trans_cnt++;
		end
	endfunction // write

	virtual function void report_phase(uvm_phase phase);
		string result = (fail_cnt == 0) ? "** PASS **" : "** FAIL **";
		`uvm_info(get_type_name(), "********** summary report **********", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("Result : %s", result),       UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("pass num : %0d", pass_cnt),  UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("error num : %0d", fail_cnt), UVM_LOW)
		`uvm_info(get_type_name(), "************************************", UVM_LOW)
	endfunction // report_phase

endclass // spi_slave_scoreboard

`endif


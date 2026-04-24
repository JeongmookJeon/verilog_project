`ifndef SPI_MASTER_DRIVER_SV
`define SPI_MASTER_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/master/seq_item.sv"
`include "./spi/master/interface.sv"

class spi_master_driver extends uvm_driver #(spi_master_inst_seq_item);
	`uvm_component_utils(spi_master_driver)

	virtual spi_master_if vif;

	localparam CLK10MHZ = 100_000_000 / 10_000_000;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual spi_master_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Driver CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		wait(vif.reset == 1);
		`uvm_info(get_type_name(), "End Reset", UVM_MEDIUM)
		
		wait (vif.reset == 0);

		forever begin
			spi_master_inst_seq_item tx;
			seq_item_port.get_next_item(tx);
			drive_spi_master(tx);
			seq_item_port.item_done();
		end
	endtask // run_phase

	task drive_spi_master(spi_master_inst_seq_item tx);
		// Instruction input
		@(vif.drv_cb);
		vif.tx_data = tx.mosi_data;
		vif.start   = 1'b1;
		@(vif.drv_cb);
		vif.start   = 1'b0;
		@(vif.drv_cb);
		if (vif.cpha) begin
			case (vif.cpol)
				1'b0: @(posedge vif.sclk);
				1'b1: @(negedge vif.sclk);
			endcase
		end
		for (shortint clock_times = 0; clock_times < 8; clock_times++) begin
			vif.miso = tx.miso_data[clock_times];
			case ({vif.cpha, vif.cpol})
				2'b00: @(negedge vif.sclk);
				2'b01: @(posedge vif.sclk);
				2'b10: @(posedge vif.sclk);
				2'b11: @(negedge vif.sclk);
			endcase
			@(vif.drv_cb);
		end
		vif.miso = 1'bz;
		wait(vif.busy == 0);
		@(vif.drv_cb);
	endtask // drive_spi_master

endclass // spi_master_driver

`endif


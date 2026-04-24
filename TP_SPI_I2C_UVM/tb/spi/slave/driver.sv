`ifndef SPI_SLAVE_DRIVER_SV
`define SPI_SLAVE_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"
`include "./spi/slave/interface.sv"

class spi_slave_driver extends uvm_driver #(spi_slave_inst_seq_item);
	`uvm_component_utils(spi_slave_driver)

	virtual spi_slave_if vif;

	localparam CLK10MHZ = 1_000_000_000 / 10_000_000;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual spi_slave_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Driver CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		vif.CS_n = 1; vif.SCLK = 0; vif.MOSI = 0;
		wait(vif.reset == 1);
		wait (vif.reset == 0);
		`uvm_info(get_type_name(), "End Reset", UVM_MEDIUM)
		

		forever begin
			spi_slave_inst_seq_item tx;
			seq_item_port.get_next_item(tx);
			drive_spi_slave(tx);
			seq_item_port.item_done();
		end
	endtask // run_phase

	task drive_spi_slave(spi_slave_inst_seq_item tx);
		@(vif.drv_cb);
        vif.tx_data   = tx.tx_data;
        vif.tx_updata = 1'b1;
        @(vif.drv_cb);
        vif.tx_updata = 1'b0;

        vif.CS_n = 0;
        
        for (int tick_times = 7; tick_times >= 0; tick_times--) begin
            vif.MOSI = tx.rx_data[tick_times];
            #(CLK10MHZ/2);
            vif.SCLK = 1'b1;
            #(CLK10MHZ/2);
            vif.SCLK = 1'b0;
			`uvm_info(get_type_name(), "Eee", UVM_MEDIUM)
        end

        vif.CS_n = 1;
		`uvm_info(get_type_name(), "f", UVM_MEDIUM)
        while (!vif.rx_done) @(vif.drv_cb);
	endtask // drive_spi_slave

endclass // spi_slave_driver

`endif


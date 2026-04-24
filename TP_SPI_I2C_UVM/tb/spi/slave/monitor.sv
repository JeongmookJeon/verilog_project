`ifndef SPI_SLAVE_MONITOR_SV
`define SPI_SLAVE_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/slave/seq_item.sv"
`include "./spi/slave/interface.sv"

class spi_slave_monitor extends uvm_monitor;
	`uvm_component_utils(spi_slave_monitor)

	uvm_analysis_port #(spi_slave_signal_seq_item) ap;
	virtual spi_slave_if vif;

	bit       run_trans = 0;
	bit       last_sclk = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new("ap",this);
		if (!uvm_config_db#(virtual spi_slave_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Monitor CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "Start Monitoring...", UVM_MEDIUM)

		forever begin
			catch_spi();
		end
	endtask // run_phase

	task catch_spi();
		spi_slave_signal_seq_item tx;
		bit trans = 0;

		@(vif.mon_cb);

		if (!last_sclk && vif.SCLK) begin trans = 1; end
		if (vif.rx_done) begin trans = 1; end

		if (trans) begin
			tx 			 = spi_slave_signal_seq_item::type_id::create("mon_tx");
			tx.SCLK      = vif.SCLK;
			tx.MOSI      = vif.MOSI;
			tx.MISO      = vif.MISO;
			tx.CS_n      = vif.CS_n;
			tx.tx_updata = vif.tx_updata;
			tx.tx_data   = vif.tx_data;
			tx.rx_data   = vif.rx_data;
			tx.rx_done   = vif.rx_done;
			tx.busy      = vif.busy;
			`uvm_info(get_type_name(), $sformatf("mon tx: %s", tx.cnvt2str()), UVM_MEDIUM)
			ap.write(tx);
		end

		last_sclk = vif.SCLK;

	endtask // catch_spi

endclass // spi_slave_monitor

`endif


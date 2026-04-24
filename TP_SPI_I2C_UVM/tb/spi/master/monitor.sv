`ifndef SPI_MASTER_MONITOR_SV
`define SPI_MASTER_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "./spi/master/seq_item.sv"
`include "./spi/master/interface.sv"

class spi_master_monitor extends uvm_monitor;
	`uvm_component_utils(spi_master_monitor)

	uvm_analysis_port #(spi_master_signal_seq_item) ap;
	virtual spi_master_if vif;

	bit       run_trans = 0;
	bit       last_sclk = 0;
	bit [3:0] data_cnt  = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new("ap",this);
		if (!uvm_config_db#(virtual spi_master_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_type_name(), "Monitor CAN'T get vif")
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "Start Monitoring...", UVM_MEDIUM)

		forever begin
			catch_spi();
		end
	endtask // run_phase

	task catch_spi();
		spi_master_signal_seq_item tx;
		bit trans = 0;

		@(vif.mon_cb);

		if (run_trans) begin
			if (last_sclk !== vif.sclk) begin
				case ({vif.cpha, vif.cpol})
					2'b00: if (!last_sclk && vif.sclk) begin trans = 1; data_cnt++; end
					2'b01: if (last_sclk && !vif.sclk) begin trans = 1; data_cnt++; end
					2'b10: if (last_sclk && !vif.sclk) begin trans = 1; data_cnt++; end
					2'b11: if (!last_sclk && vif.sclk) begin trans = 1; data_cnt++; end
				endcase
			end

			if (vif.done) begin
				trans = 1; run_trans = 0;
			end
		end
		else if (vif.start) begin
			run_trans = 1;
			trans     = 1;
		end

		if (trans) begin
			tx 			= spi_master_signal_seq_item::type_id::create("mon_tx");
			tx.tx_data	= vif.tx_data;
			tx.start	= vif.start;
			tx.rx_data	= vif.rx_data;
			tx.done		= vif.done;
			tx.busy		= vif.busy;
			tx.sclk		= vif.sclk;
			tx.mosi		= vif.mosi;
			tx.miso		= vif.miso;
			tx.cs_n		= vif.cs_n;
			`uvm_info(get_type_name(), $sformatf("mon tx: %s", tx.cnvt2str()), UVM_MEDIUM)
			ap.write(tx);
		end

		last_sclk = vif.sclk;
	endtask // catch_spi

endclass // spi_master_monitor

`endif


`include "uvm_macros.svh"
import uvm_pkg::*;

`include "define.svh"


interface i2c_if (
    input bit clk,
    input bit rst
);
	logic [7:0] slave_addr;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] tx_data_m;
    logic [7:0] tx_data_s;
    logic [7:0] rx_data_m;
    logic [7:0] rx_data_s;
    logic       ack_in;
    logic       done_m;
    logic       done_s;
    logic       busy_m;
    logic       read_busy_s;
    logic       ack_out;
	logic		rw;	// 1=r/0=w , for MONITOR, dependent with cmd_write/cmd_read
	logic [4:0]	num_tr;
    //output logic       scl;
    //inout              sda


    clocking drv_cb @(posedge clk);
        default input #1step output #0;
		output slave_addr;
		output cmd_start;
    	output cmd_write;
    	output cmd_read;
    	output cmd_stop;
    	output tx_data_m;
    	output tx_data_s;
    	output ack_in;
		output rw;
		output num_tr;
    	input  rx_data_m;
    	input  rx_data_s;
    	input  ack_out;
    	input  done_m;
    	input  done_s;
    	input  busy_m;
    	input  read_busy_s;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;  // output #0;
		input	slave_addr;
		input	cmd_start;
    	input	cmd_write;
    	input	cmd_read;
    	input	cmd_stop;
    	input	tx_data_m;
    	input	tx_data_s;
    	input	rx_data_m;
    	input	rx_data_s;
    	input	ack_in;
    	input	ack_out;
    	input	done_m;
    	input	done_s;
    	input	busy_m;
    	input	read_busy_s;
		input	rw;
		input	num_tr;
    endclocking
endinterface


class i2c_seq_item extends uvm_sequence_item;
	rand logic [7:0]	slave_addr;
    logic				cmd_start;
    rand logic			cmd_write;
    rand logic			cmd_read;
    logic				cmd_stop;
    rand logic [7:0]	tx_data_m;
    rand logic [7:0]	tx_data_s;
    logic [7:0]			rx_data_m;
    logic [7:0]			rx_data_s;
    logic				done_m;
    logic				done_s;
    logic				busy_m;
    logic				read_busy_s;
	rand logic [4:0]	num_tr;
    logic				ack_in;
    logic				ack_out;

    `uvm_object_utils_begin(i2c_seq_item)
		`uvm_field_int(slave_addr, UVM_ALL_ON);
		`uvm_field_int(cmd_start, UVM_ALL_ON);
    	`uvm_field_int(cmd_write, UVM_ALL_ON);
    	`uvm_field_int(cmd_read, UVM_ALL_ON)
    	`uvm_field_int(cmd_stop, UVM_ALL_ON)
    	`uvm_field_int(tx_data_m, UVM_ALL_ON);
    	`uvm_field_int(tx_data_s, UVM_ALL_ON);
    	`uvm_field_int(rx_data_m, UVM_ALL_ON);
    	`uvm_field_int(rx_data_s, UVM_ALL_ON);
    	`uvm_field_int(done_m, UVM_ALL_ON);
    	`uvm_field_int(done_s, UVM_ALL_ON);
    	`uvm_field_int(busy_m, UVM_ALL_ON);
    	`uvm_field_int(read_busy_s, UVM_ALL_ON);
    	`uvm_field_int(num_tr, UVM_ALL_ON);
    	`uvm_field_int(ack_in, UVM_ALL_ON);
    	`uvm_field_int(ack_out, UVM_ALL_ON);
    `uvm_object_utils_end

	constraint c_slave_addr {
		slave_addr == 8'h12;
	}

	constraint c_r_w {
		cmd_write == ~cmd_read;
	}

	constraint c_num_tr {
		num_tr inside {[1:31]};
	}

	function new(string name = "i2c_seq_item");
		super.new(name);
	endfunction

	function string convert2string();
		return $sformatf("num_tr=%0d, [Master] tx_data=0x%0h, rx_data=0x%0h [Slave] tx_data=0x%0h, rx_data=0x%0h, cmd_write=%0b, cmd_read=%0b", num_tr, tx_data_m,  rx_data_m, tx_data_s, rx_data_s, cmd_write, cmd_read);
	endfunction
endclass


class i2c_seq extends uvm_sequence #(i2c_seq_item);
	`uvm_object_utils(i2c_seq)
	int num_trans = 10;

	function new(string name = "i2c_seq");
		super.new(name);
	endfunction

	task body();
		i2c_seq_item item;
		repeat(num_trans) begin
			item = i2c_seq_item::type_id::create("item");
			start_item(item);
			if (!item.randomize() with {slave_addr==8'h12;}) begin
				`uvm_fatal(get_type_name(), "randomization failed")
			end
			`uvm_info(get_type_name(), $sformatf("seq send: %s", item.convert2string()), UVM_MEDIUM)
			finish_item(item);
		end
	endtask
endclass


class i2c_driver extends uvm_driver #(i2c_seq_item);
	`uvm_component_utils(i2c_driver)
	virtual i2c_if i_if;
	logic r_w;	// 1 : READ, 0 : WRITE was the previous operation

	function new(string name = "i2c_drv", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i_if", i_if)) begin
			`uvm_fatal(get_type_name(), "cannot access to interface")
		end
	endfunction


	task i2c_master_start(i2c_seq_item item);
			wait(!i_if.drv_cb.busy_m);

			// start
			i_if.drv_cb.cmd_start <= 1'b1;
			i_if.drv_cb.cmd_write <= 1'b0;
			i_if.drv_cb.cmd_read <= 1'b0;
			i_if.drv_cb.cmd_stop <= 1'b0;
			@(i_if.drv_cb);
			@(posedge i_if.done_m);
			i_if.drv_cb.cmd_start <= 1'b0;
			@(i_if.drv_cb);
			
			`uvm_info(get_type_name(), $sformatf("Master started : %s", item.convert2string()), UVM_HIGH)
	endtask

	task i2c_master_addr(i2c_seq_item item);
			// addr
			if (item.cmd_write) begin
				i_if.drv_cb.tx_data_m <= {item.slave_addr[6:0], 1'b0};
			end else if (item.cmd_read) begin
				i_if.drv_cb.tx_data_m <= {item.slave_addr[6:0], 1'b1};
			end
			i_if.drv_cb.cmd_write <= 1'b1;
			@(i_if.drv_cb);
			@(posedge i_if.done_m);
			i_if.drv_cb.cmd_write <= 1'b0;
			i_if.drv_cb.cmd_write <= 1'b0;
			@(i_if.drv_cb);
			
			`uvm_info(get_type_name(), $sformatf("Master sent addr : %s", item.convert2string()), UVM_HIGH)
	endtask

	task i2c_master_write(i2c_seq_item item);
		for (int i=0; i<item.num_tr; i++) begin
				i_if.drv_cb.cmd_write <= 1'b1;
				i_if.drv_cb.cmd_read <= 1'b0;
				i_if.drv_cb.tx_data_m <= item.tx_data_m;
				i_if.drv_cb.tx_data_s <= item.tx_data_s;
				i_if.drv_cb.rw <= 1'b0;	// write
			
				i_if.drv_cb.ack_in <= 1'b1;	// 1 in default	// ??

				@(i_if.drv_cb);
				@(posedge i_if.done_m);
				i_if.drv_cb.cmd_write <= 1'b0;	// prevent duplicated WRITE
				@(i_if.drv_cb);
				@(i_if.drv_cb);
			`uvm_info(get_type_name(), $sformatf("Master write [%0d/%0d] : %s", i, item.num_tr, item.convert2string()), UVM_HIGH)
		end
			`uvm_info(get_type_name(), $sformatf("Master write completed : %s", item.convert2string()), UVM_HIGH)
	endtask

	task i2c_master_read(i2c_seq_item item);
		for (int i=0; i<item.num_tr; i++) begin
				i_if.drv_cb.cmd_write <= 1'b0;
				i_if.drv_cb.cmd_read <= 1'b1;
				i_if.drv_cb.tx_data_m <= item.tx_data_m;
				i_if.drv_cb.tx_data_s <= item.tx_data_s;
				i_if.drv_cb.rw <= 1'b1;	// read

				if (i == (item.num_tr - 1)) begin
					i_if.drv_cb.ack_in <= 1'b1;	// NACK
				end else begin
					i_if.drv_cb.ack_in <= 1'b0;	// ACK
				end

				@(i_if.drv_cb);
				@(posedge i_if.done_m);
				i_if.drv_cb.cmd_read <= 1'b0;	// prevent duplicated READ
				@(i_if.drv_cb);
			`uvm_info(get_type_name(), $sformatf("Master read [%0d/%0d] : %s", i, item.num_tr, item.convert2string()), UVM_HIGH)
		end
			`uvm_info(get_type_name(), $sformatf("Master read completed : %s", item.convert2string()), UVM_HIGH)
	endtask

	task i2c_master_stop(i2c_seq_item item);
			// stop
			i_if.drv_cb.cmd_stop <= 1'b1;
			@(i_if.drv_cb);
			wait(i_if.drv_cb.done_m);
			i_if.drv_cb.cmd_stop <= 1'b0;
			@(i_if.drv_cb);
			`uvm_info(get_type_name(), $sformatf("Master stopped : %s", item.convert2string()), UVM_HIGH)
	endtask


	virtual task run_phase(uvm_phase phase);
		i2c_seq_item item;

		wait(i_if.rst == 0);
		
		forever begin
			seq_item_port.get_next_item(item);
			`uvm_info(get_type_name(), $sformatf("got item : %s", item.convert2string()), UVM_HIGH)
			
			// for coverage
			i_if.drv_cb.num_tr <= item.num_tr;

			i2c_master_start(item);
			i2c_master_addr(item);

			if (item.cmd_write) begin
				i2c_master_write(item);
			end else if (item.cmd_read) begin
				i2c_master_read(item);
			end

			i2c_master_stop(item);

			/*
			// FOR DEBUG
			item.tx_data_m <= i_if.tx_data_m;
			item.tx_data_s <= i_if.tx_data_s;
			item.rx_data_m <= i_if.rx_data_m;
			item.rx_data_s <= i_if.rx_data_s;
			`uvm_info(get_type_name(), $sformatf("tx, rx finished : %s", item.convert2string()), UVM_DEBUG)
			*/

			seq_item_port.item_done();
		end
	endtask
endclass


class i2c_monitor extends uvm_monitor;
	`uvm_component_utils(i2c_monitor)
	virtual i2c_if i_if;
	uvm_analysis_port #(i2c_seq_item) ap;

	function new(string name = "i2c_mon", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i_if", i_if)) begin
			`uvm_fatal(get_type_name(), "cannot access to interface")
		end
		ap = new("ap", this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		@(i_if.mon_cb);
		forever begin
			i2c_seq_item item = i2c_seq_item::type_id::create("item", this);

			@(posedge i_if.done_s);
			@(i_if.mon_cb);
			@(i_if.mon_cb);
			
			// read
			if (i_if.mon_cb.rw) begin
				item.cmd_write = 1'b0;
				item.cmd_read = 1'b1;
			end else begin
				item.cmd_write = 1'b1;
				item.cmd_read = 1'b0;
			end
			item.tx_data_m = i_if.mon_cb.tx_data_m;
			item.tx_data_s = i_if.mon_cb.tx_data_s;
			item.rx_data_m = i_if.mon_cb.rx_data_m;
			item.rx_data_s = i_if.mon_cb.rx_data_s;
			item.num_tr = i_if.mon_cb.num_tr;
			`uvm_info(get_type_name(), $sformatf("tx, rx finished : %s", item.convert2string()), UVM_HIGH)

			ap.write(item);
		end
	endtask
endclass

class i2c_agent extends uvm_agent;
	`uvm_component_utils(i2c_agent)

	i2c_driver drv;
	i2c_monitor mon;
	uvm_sequencer #(i2c_seq_item) sqr;

	function new(string name = "i2c_agent", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		drv = i2c_driver::type_id::create("drv", this);
		mon = i2c_monitor::type_id::create("mon", this);
		sqr = uvm_sequencer#(i2c_seq_item)::type_id::create("sqr", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction
endclass


class i2c_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(i2c_scoreboard)
	uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) ap_imp;
	int pass_cnt = 0;
	int fail_cnt = 0;
	int err_cnt = 0;

	function new(string name = "i2c_scb", uvm_component parent);
		super.new(name, parent);
		ap_imp = new("ap_imp", this);
	endfunction

	function void write(i2c_seq_item item);

		
		if ((item.cmd_write)&&(!item.cmd_read)) begin
			// WRITE
			if (item.tx_data_m == item.rx_data_s) begin
				`uvm_info(get_type_name(), $sformatf("%s[PASS]%s M->S : 0x%0h", `CLR_GRN, `CLR_RESET, item.tx_data_m), UVM_MEDIUM)
				pass_cnt++;
			end else begin
				`uvm_error(get_type_name(), $sformatf("%s[FAIL]%s M->S : 0x%0h -> 0x%0h", `CLR_RED, `CLR_RESET, item.tx_data_m, item.rx_data_s))
				fail_cnt++;
			end
		end else if (!(item.cmd_write)&(item.cmd_read)) begin
			// READ
			if (item.rx_data_m == item.tx_data_s) begin
				`uvm_info(get_type_name(), $sformatf("%s[PASS]%s S->M : 0x%0h", `CLR_GRN, `CLR_RESET, item.tx_data_s), UVM_MEDIUM)
				pass_cnt++;
			end else begin
				`uvm_error(get_type_name(), $sformatf("%s[FAIL]%s S->M : 0x%0h -> 0x%0h", `CLR_RED, `CLR_RESET, item.tx_data_s, item.rx_data_m))
				fail_cnt++;
			end
		end else begin
			`uvm_error(get_type_name(), $sformatf("[SCB] !!! ERROR !!! write(%0b)/read(%0b) cmd in same time", item.cmd_write, item.cmd_read))
			err_cnt++;
		end
	endfunction

	virtual function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info(get_type_name(), $sformatf("\n\n ====== Scoreboard Result ====== "), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("pass_cnt = %0d/%0d", pass_cnt, pass_cnt+fail_cnt+err_cnt), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("fail_cnt = %0d/%0d", fail_cnt, pass_cnt+fail_cnt+err_cnt), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("err_cnt = %0d", err_cnt), UVM_MEDIUM)
		if (!(fail_cnt || err_cnt)) begin
			`uvm_info(get_type_name(), $sformatf("[TEST PASS] %0d/%0d", pass_cnt, pass_cnt+fail_cnt+err_cnt), UVM_DEBUG)
		end else begin
			`uvm_info(get_type_name(), $sformatf("[TEST FAIL] %0d/%0d/%0d", fail_cnt, err_cnt, pass_cnt+fail_cnt+err_cnt), UVM_DEBUG)
		end
		`uvm_info(get_type_name(), $sformatf(" ====== Scoreboard Result ====== \n\n"), UVM_LOW)
	endfunction 
endclass



class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
`uvm_component_utils(i2c_coverage)

	logic [7:0] cov_tx_data_m, cov_tx_data_s;
	logic [4:0] cov_num_tr;

	covergroup cg_data;
		cp_tx_data_m: coverpoint cov_tx_data_m {
			bins zero = {8'h00};
			bins alt_01 = {8'h55};
			bins alt_10 = {8'haa};
			bins lsb_only = {8'h01};
			bins msb_only = {8'h80};
			bins range0 = {[8'h00:8'h0f]};
			bins range1 = {[8'h10:8'h1f]};
			bins range2 = {[8'h20:8'h2f]};
			bins range3 = {[8'h30:8'h3f]};
			bins range4 = {[8'h40:8'h4f]};
			bins range5 = {[8'h50:8'h5f]};
			bins range6 = {[8'h60:8'h6f]};
			bins range7 = {[8'h70:8'h7f]};
			bins range8 = {[8'h80:8'h8f]};
			bins range9 = {[8'h90:8'h9f]};
			bins rangea = {[8'ha0:8'haf]};
			bins rangeb = {[8'hb0:8'hbf]};
			bins rangec = {[8'hc0:8'hcf]};
			bins ranged = {[8'hd0:8'hdf]};
			bins rangee = {[8'he0:8'hef]};
			bins rangef = {[8'hf0:8'hff]};
		}
		cp_tx_data_s: coverpoint cov_tx_data_s {
			bins zero = {8'h00};
			bins alt_01 = {8'h55};
			bins alt_10 = {8'haa};
			bins lsb_only = {8'h01};
			bins msb_only = {8'h80};
			bins range0 = {[8'h00:8'h0f]};
			bins range1 = {[8'h10:8'h1f]};
			bins range2 = {[8'h20:8'h2f]};
			bins range3 = {[8'h30:8'h3f]};
			bins range4 = {[8'h40:8'h4f]};
			bins range5 = {[8'h50:8'h5f]};
			bins range6 = {[8'h60:8'h6f]};
			bins range7 = {[8'h70:8'h7f]};
			bins range8 = {[8'h80:8'h8f]};
			bins range9 = {[8'h90:8'h9f]};
			bins rangea = {[8'ha0:8'haf]};
			bins rangeb = {[8'hb0:8'hbf]};
			bins rangec = {[8'hc0:8'hcf]};
			bins ranged = {[8'hd0:8'hdf]};
			bins rangee = {[8'he0:8'hef]};
			bins rangef = {[8'hf0:8'hff]};
		}
		cp_num_tr: coverpoint cov_num_tr {
			bins low = {[1:8]};
			bins mid_low = {[9:16]};
			bins mid_high = {[17:24]};
			bins high = {[25:31]};
		}
	endgroup



	function new(string name = "i2c_coverage", uvm_component parent);
		super.new(name, parent);
		cg_data = new();
	endfunction

	function void write(i2c_seq_item item);
		cov_tx_data_m = item.tx_data_m;
		cov_tx_data_s = item.tx_data_s;
		cov_num_tr = item.num_tr;
		cg_data.sample();
	endfunction

	function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "\n\n ===== Coverage Report ===== ", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("coverage cg_data=%.1f%%", cg_data.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("coverage tx_data_m=%.1f%%", cg_data.cp_tx_data_m.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("coverage tx_data_s=%.1f%%", cg_data.cp_tx_data_s.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("coverage num_tr=%.1f%%", cg_data.cp_num_tr.get_coverage()), UVM_LOW)
		`uvm_info(get_type_name(), " ===== Coverage Report ===== \n\n", UVM_LOW)
	endfunction
endclass



class i2c_env extends uvm_env;
	`uvm_component_utils(i2c_env)

	i2c_agent agt;
	i2c_scoreboard scb;
	i2c_coverage cov;

	function new(string name="i2c_env", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agt = i2c_agent::type_id::create("agt", this);
		scb = i2c_scoreboard::type_id::create("scb", this);
		cov = i2c_coverage::type_id::create("cov", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agt.mon.ap.connect(scb.ap_imp);
		agt.mon.ap.connect(cov.analysis_export);
	endfunction

endclass


class i2c_test extends uvm_test;
	`uvm_component_utils(i2c_test)

	i2c_env env;

	function new(string name = "i2c_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = i2c_env::type_id::create("env", this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		i2c_seq seq;
		phase.raise_objection(this);
		seq = i2c_seq::type_id::create("seq", this);
		seq.num_trans = 1000;
		seq.start(env.agt.sqr);
		phase.drop_objection(this);
	endtask

	

endclass

module tb_i2c_uvm ();

    bit clk;
    bit rst;
	bit cpol, cpha;	// 0 in default
	logic scl;
	tri1 sda;

    i2c_if i_if (
        clk,
        rst
    );

    I2C_Master I2C_M (
		.clk(clk),
		.rst(rst),
		.cmd_start(i_if.cmd_start),
		.cmd_write(i_if.cmd_write),
		.cmd_read(i_if.cmd_read),
		.cmd_stop(i_if.cmd_stop),
		.ack_in(i_if.ack_in),
		.ack_out(i_if.ack_out),
        .tx_data(i_if.tx_data_m),
        .rx_data(i_if.rx_data_m),
        .done(i_if.done_m),
        .busy(i_if.busy_m),
		.scl(scl),
		.sda(sda)
		//.scl(i_if.scl),
		//.sda(i_if.sda)
    );

    i2c_slave I2C_S (
        .clk(clk),
		.rst(rst),
        .tx_data(i_if.tx_data_s),
        .rx_data(i_if.rx_data_s),
        .done(i_if.done_s),
        //.busy(i_if.busy_s),
        .sending(i_if.read_busy_s),
		.scl(scl),
		.sda(sda)
		//.scl(i_if.scl),
		//.sda(i_if.sda)
    );

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst = 1;
		repeat(3) @(posedge clk);
		rst = 0;
		@(posedge clk);
	end

	initial begin
		uvm_config_db#(virtual i2c_if)::set(null, "*", "i_if", i_if);
		run_test("i2c_test");

		#100;
		$finish;
	end

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_i2c_uvm, "+all");
	end
endmodule

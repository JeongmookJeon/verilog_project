`timescale 1ns / 1ps
interface ram_interface (
    input clk
);
    logic [3:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface  //ram_interface

class transaction;
    rand bit [3:0] addr;
    rand bit [7:0] wdata;
    rand bit we;
    logic [7:0] rdata;
    function void display(string name);
        $display("%t : [%s]we = %d, addr=%2h, wdata = %2h, rdata = %2h", $time,
                 name, we, addr, wdata, rdata);
    endfunction  //new()
endclass  //transaction

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;
    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()
    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask  //run
endclass  //generator

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface ram_if;
    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;
    endfunction  //new()
    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge ram_if.clk);
            ram_if.addr = tr.addr;
            ram_if.wdata = tr.wdata;
            ram_if.we = tr.we;
            tr.display("drv");
        end
    endtask  //present
endclass  //driver

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_if;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual ram_interface ram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if = ram_if;
    endfunction  //new()
    task run();
        forever begin
            @(posedge ram_if.clk);
            #1;
            tr       = new();
            tr.addr  = ram_if.addr;
            tr.we    = ram_if.we;
            tr.wdata = ram_if.wdata;
            tr.rdata = ram_if.rdata;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run r
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    covergroup cg_sram;  // tr.addr만 보겠다.
        cp_addr: coverpoint tr.addr {
            bins min = {0}; bins max = {15}; bins mid = {[1 : 14]};
        }
    endgroup

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
        cg_sram = new();
    endfunction  //new()
    task run();
        logic [7:0] expected_ram[0:15];
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            cg_sram.sample();
            //pass fail
            if (tr.we) begin
                expected_ram[tr.addr] = tr.wdata;
                $display(
                    "%2h",
                    expected_ram[tr.addr]);  // 여기 주석처리하면 많이 뜸!!
            end else begin
                if (expected_ram[tr.addr] === tr.rdata)
                    $display("pass");  // ===이거 확인!!!! ==과 ===차이
                else
                    $display(
                        "fail:expected data= %2h, rdata = %2h",
                        expected_ram[tr.addr],
                        tr.rdata
                    );
            end
            //next stimulus
            ->gen_next_ev;
        end
    endtask  //run
endclass  //scoreboard

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface  ram_if;
    event                  gen_next_ev;
    function new(virtual ram_interface ram_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, ram_if);
        mon = new(mon2scb_mbox, ram_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()
    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("coverage addr = %d", scb.cg_sram.get_inst_coverage());
        $stop;
    endtask  //run
endclass

module tb_sram_sv ();
    logic clk;
    ram_interface ram_if (clk);
    environment env;
    bit_8_we_sram DUT (
        .clk(clk),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .we(ram_if.we),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        env = new(ram_if);
        env.run();
    end
endmodule

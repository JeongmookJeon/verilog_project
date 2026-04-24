`timescale 1ns / 1ps

interface register_interface;
    logic       clk;
    logic       rst;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface  //register_interface

class transaction;
    rand bit [7:0] wdata;
    logic    [7:0] rdata;
    task display(string name);
        $display("%t : [%s] wdata = %h,rdata=%h", $time, name, wdata, rdata);
    endtask  //automatic
endclass  //transaction

class generator;
    transaction tr;  //핸들러
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()
    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();  // 알아서 생성됨
            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask
endclass

class driver;  // 얘는 안멈추고 계속 대기하면서 동작하는 녀석
    transaction tr;  // p.g 5 중요!!!!!!!!!!!!!!!!!!!!!!
    mailbox #(transaction) gen2drv_mbox;
    virtual register_interface register_if;
    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual register_interface register_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.register_if  = register_if;
    endfunction  //new()
    task preset();
        register_if.clk = 0;
        register_if.rst = 1;
        @(posedge register_if.clk);
        @(posedge register_if.clk);
        register_if.rst = 0;
        @(posedge register_if.clk);

    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge register_if.clk);
            register_if.wdata = tr.wdata;
            tr.display(
                "drv");  // 순서 어디에 할건지 확인!!!!!!!!!!!!!
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface register_if;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual register_interface register_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.register_if  = register_if;

    endfunction  //new()
    task run();
        forever begin
            tr = new();  // 메일박스에 언제 넣어줄거지 파악하자. 
            @(posedge register_if.clk);
            #1;
            tr.wdata = register_if.wdata;
            tr.rdata = register_if.rdata;
            mon2scb_mbox.put(tr);
            tr.display("mon");
        end
    endtask  //
endclass  //monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()
    task run();
        forever begin
            mon2scb_mbox.get(tr);
            if (tr.wdata == tr.rdata) begin
                $display("%t : pass : wdata=%h, rdata=%h", $time, tr.wdata,
                         tr.rdata);
            end else begin
                $display("%t : fail : wdata=%h, rdata=%h", $time, tr.wdata,
                         tr.rdata);
            end
            tr.display("scb");
            ->gen_next_ev;

        end
    endtask
endclass  //scoreboard

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  gen_next_ev;
    function new(virtual register_interface register_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, register_if);
        mon = new(mon2scb_mbox, register_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()
    task run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;
        $stop;
    endtask  //run
endclass  //className


module tb_bit_8_reg ();
    register_interface register_if();  //인터페이스 만든 후 모듈에 넣어버리는것으로 시작!
    environment env;
    bit_8_reg DUT(
        .clk  (register_if.clk),
        .rst  (register_if.rst),
        .wdata(register_if.wdata),
        .rdata(register_if.rdata)
    );
    always #5 register_if.clk = ~register_if.clk;  // clk 생성.
    initial begin
        //register_if.clk = 0;
        //register_if.rst = 0;
        env = new(register_if);
        env.run();
    end
endmodule

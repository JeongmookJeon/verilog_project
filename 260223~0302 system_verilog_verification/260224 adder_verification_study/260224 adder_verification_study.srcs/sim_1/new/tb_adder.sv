`timescale 1ns / 1ps

interface adder_interface; // 연결 묶음
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;
endinterface  //adder_interface

class transaction; // 랜덤 데이터라고 알려줌
    rand bit [31:0] a;
    rand bit [31:0] b;
    rand bit        mode;
    logic    [31:0] s;
    logic           c;
endclass  //transaction

//generator for randomize stimulus
class generator;
    // handler생성 tr
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;
    // 불릴 때마다 생성해서 파일철에 넣고 보내고 끝 시간신경안씀.
    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction 

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end
    endtask  //
endclass  //generator

class driver;
    transaction tr;  // transaction에서 받아온 것.
    virtual adder_interface adder_if;
    mailbox #(transaction) gen2drv_mbox;
    event mon_next_ev;
    function new(mailbox#(transaction) gen2drv_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.adder_if = adder_if;  // 왼쪽이 
        this.mon_next_ev = mon_next_ev;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction  //new()
    task run();
        forever begin
            gen2drv_mbox.get(tr);  // p.g 7
            adder_if.a    = tr.a;
            adder_if.b    = tr.b;
            adder_if.mode = tr.mode;
            #10;  // 시간을 기다려줌
            //event 발생
            ->mon_next_ev;
        end
    endtask  //
endclass  //driver

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;
    virtual adder_interface adder_if;

    function new(mailbox#(transaction) mon2scb_mbox, 
                    event mon_next_ev,
                 virtual adder_interface adder_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.mon_next_ev = mon_next_ev;
        this.adder_if = adder_if;
    endfunction  //new()

    task run();
        forever begin
            @(mon_next_ev);
            tr      = new();
            tr.a    = adder_if.a;
            tr.b    = adder_if.b;
            tr.mode = adder_if.mode;
            tr.s    = adder_if.s;
            tr.c    = adder_if.c;
            mon2scb_mbox.put(tr);
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            //compare, pass,fail
            $display("%t: a=%0d, b=%0d, mode=%0d, s=%0d, c=%0d", $time, tr.a,
                     tr.b, tr.mode, tr.s, tr.c);
            ->gen_next_ev;
        end
    endtask  //run
endclass

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;  // gen -> drv
    mailbox #(transaction) mon2scb_mbox;  // mon ->scb
    event                  gen_next_ev;  // scb to gen
    event                  mon_next_ev;  // drv to mon
    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, mon_next_ev, adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()
    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $stop;
    endtask

endclass  //environment

module tb_adder_verification ();

    adder_interface adder_if ();
    environment env;
    adder dut (
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),
        .s   (adder_if.s),
        .c   (adder_if.c)
    );
    initial begin
        //constructor
        env = new(adder_if);
        //exe
        env.run();
    end

endmodule

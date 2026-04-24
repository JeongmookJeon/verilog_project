`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/26 10:38:46
// Design Name: 
// Module Name: tb_bit_8_reg_we`timescale 1ns / 1ps


//report 추가해보라


interface register_interface;
    logic       clk;
    logic       rst;
    logic       we;
    logic [7:0] wdata;
    logic [7:0] rdata;

    property preset_check;
        @(posedge clk) rst |=> (rdata == 0);
    endproperty
    reg_reset_check :
    assert property (preset_check)
    else $display("%t : Assert error : reset check", $time);
endinterface  //register_interface

class transaction;
    rand bit [7:0] wdata;
    rand bit       we;
    logic    [7:0] rdata;

    task display(string name);
        $display("%t : [%s] we=%d, wdata = %h,rdata=%h", $time, name, we,
                 wdata, rdata);
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

            assert (tr.randomize())
            else $display("[gen]tr.randomize()error!!!");

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
        register_if.clk   = 0;
        register_if.rst   = 1;
        register_if.we    = 0;
        register_if.wdata = 0;
        @(posedge register_if.clk);
        @(posedge register_if.clk); // 이렇게하면 pos때 데이터 세팅, pos때 데이터 업데이트????
        register_if.rst = 0;
        @(posedge register_if.clk);

    endtask
    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge register_if.clk);
            register_if.we    = tr.we;
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
            tr.we = register_if.we;
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
    int pass_cnt, fail_cnt, try_cnt;
    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()
    task run();
        pass_cnt = 0;
        fail_cnt = 0;
        forever begin
            mon2scb_mbox.get(tr);
            try_cnt++;
            if (tr.we)
                if (tr.wdata == tr.rdata) begin
                    $display("%t : pass : wdata=%h, rdata=%h", $time, tr.wdata,
                             tr.rdata);
                    pass_cnt++;
                end else begin
                    $display("%t : fail : wdata=%h, rdata=%h", $time, tr.wdata,
                             tr.rdata);
                    fail_cnt++;
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
        $display("________________________");
        $display("**8bit register werifi*");
        $display("**********************");
        $display("** total count = %3d  **", scb.try_cnt);
        $display("** pass count = %3d  **", scb.pass_cnt);
        $display("** fail count = %3d  **", scb.fail_cnt);
        $display("**********************");
        $stop;
    endtask  //run
endclass  //className


module tb_bit_8_reg ();
    register_interface register_if();  //인터페이스 만든 후 모듈에 넣어버리는것으로 시작!
    environment env;
    bit_8_reg DUT (
        .clk  (register_if.clk),
        .rst  (register_if.rst),
        .we   (register_if.we),
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

// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_bit_8_reg_we ();
endmodule

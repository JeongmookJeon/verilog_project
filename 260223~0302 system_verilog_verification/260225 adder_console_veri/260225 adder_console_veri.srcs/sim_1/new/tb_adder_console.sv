`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;
endinterface  //adder_interface

class transaction; // randc 대입 cyclic
    randc bit [31:0] a;
    randc bit [31:0] b;
    randc bit        mode;
    logic    [31:0] s;
    logic           c;
    task display(string name);
        $display("%t : [%s] a = %h, b = %h, mode = %h, sum = %h, carry = %h",
                 $time, name, a, b, mode, s, c);
    endtask
    //transaction에서 제약조건을 줌 
    //constraints range{
    //    a > 10;
    //    b > 32'hffff_0000;
    //}

    //constraint dist_pattern{
    //    a dist{
    //        0:=8,
    //        32'hffff_ffff:=1,
    //        [1:32'hffff_fffe] :=1
    //        };
    //}

    //constraint dist_pattern {
    //    a dist {
    //        0 :/ 80,
    //        32'hffff_ffff :/ 10,
    //        [1 : 32'hffff_fffe] :/ 10
    //    };
    //}
    constraint list_pattern {a inside {[0 : 16]};}

endclass

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
    endfunction  //new()
    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            // 여기에 위치한 이유는 시간(time)의 영향을 받기 때문!! 10ns의 시간으로 영향을 받음
            tr.display("gen");
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
        this.adder_if = adder_if;
        this.mon_next_ev = mon_next_ev;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction  //new()
    task run();
        forever begin
            gen2drv_mbox.get(tr);  // p.g 7
            adder_if.a    = tr.a;
            adder_if.b    = tr.b;
            adder_if.mode = tr.mode;
            tr.display("drv");
            #10;  // 시간을 보내줌.
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

    function new(mailbox#(transaction) mon2scb_mbox, event mon_next_ev,
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
            tr.display("mon");
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    transaction                   tr;
    mailbox #(transaction)        mon2scb_mbox;
    event                         gen_next_ev;
    bit                    [31:0] expected_sum;
    bit                           expected_carry;
    int                           pass_cnt,       fail_cnt;
    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            //compare, pass,fail
            // 비교할(for compare) expected data 만듦
            if (tr.mode == 0) {expected_carry, expected_sum} = tr.a + tr.b;
            else {expected_carry, expected_sum} = tr.a - tr.b;
            if ((expected_sum == tr.s) && (expected_carry == tr.c)) begin
                $display("[PASS]: a=%d, b=%d, mode=%d, s=%d, c=%d", tr.a, tr.b,
                         tr.mode, tr.s, tr.c);
                pass_cnt++;
            end else begin
                $display("[FAIL]: a=%d, b=%d, mode=%d, s=%d, c=%d", tr.a, tr.b,
                         tr.mode, tr.s, tr.c);
                fail_cnt++;
                $display("expected sum=%d", expected_sum);
                $display("expected carry=%d", expected_carry);
            end
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
    int                    i;
    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, mon_next_ev, adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()
    task run();  // 2. 이것을 실행해 ()추가지시사항 없음
        i = 100;
        fork  // 실행해
            gen.run(i);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;
        $display("_______________________________");
        $display("**32bit Adder Verification");
        $display("-------------------------------");
        $display("**Total Ttest cnt=%3d        **", i);
        $display("**Total pass  cnt=%3d        **", scb.pass_cnt);
        $display("**Total fail  cnt=%3d        **", scb.fail_cnt);
        $display("-------------------------------");
        $display("_______________________________");
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
        env.run(); // 1. run()이라는 시동 버튼에 의해 env를 깨워서
    end

endmodule

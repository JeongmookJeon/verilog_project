`timescale 1ns / 1ps

// ---------------------------------------------------------
// 1. Interface
// ---------------------------------------------------------
interface watch_interface (
    input logic clk
);
    logic rst;
    logic sel_display;
    logic up_l;
    logic up_r;
    logic down_l;
    logic down_r;
    logic change;

    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;

endinterface  // watch_interface

// ---------------------------------------------------------
// 2. Transaction
// ---------------------------------------------------------
class transaction;
    rand bit sel_display;
    rand bit up_l;
    rand bit up_r;
    rand bit down_l;
    rand bit down_r;
    rand bit change;
    rand int duration;

    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;

    // 기본적으로 한 번 누를 때 1클럭만 눌리도록 설정
    constraint c_duration {duration inside {[1 : 1000]};}

    function void display(string name);
        $display(
            "%t : [%s] change=%b, sel=%b | up(L:%b, R:%b) down(L:%b, R:%b) | dur=%0d clks | Time = %0d:%0d:%0d.%0d",
            $time, name, change, sel_display, up_l, up_r, down_l, down_r,
            duration, hour, min, sec, msec);
    endfunction
endclass  // transaction

// ---------------------------------------------------------
// 3. Generator (표 스펙 완벽 구현)
// ---------------------------------------------------------
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    // 헬퍼 태스크: 특정 버튼 조합을 '1클럭' 동안만 누르고 떼는 동작 (한 칸만 조작)
    task press_button(bit c, bit sel, bit ul, bit ur, bit dl, bit dr,
                      string name);
        // 1단계: 버튼 누르기 (duration = 1 클럭)
        tr = new();
        if (!tr.randomize() with {
                change == c;
                sel_display == sel;
                up_l == ul;
                up_r == ur;
                down_l == dl;
                down_r == dr;
                duration == 1;
            })
            $fatal(1, "Gen Randomization failed!");
        gen2drv_mbox.put(tr);
        tr.display(name);
        @(gen_next_ev);

        // 2단계: 버튼 떼고 대기 (결과를 파형에서 쉽게 보기 위해 5클럭 대기)
        tr = new();
        if (!tr.randomize() with {
                change == c;
                sel_display == sel;
                up_l == 0;
                up_r == 0;
                down_l == 0;
                down_r == 0;
                duration == 5;
            })
            $fatal(1, "Gen Randomization failed!");
        gen2drv_mbox.put(tr);
        @(gen_next_ev);
    endtask

    // 헬퍼 태스크: 조작 없이 일반 시간 흐름
    task run_time(int clks);
        tr = new();
        if (!tr.randomize() with {
                change == 0;
                up_l == 0;
                up_r == 0;
                down_l == 0;
                down_r == 0;
                duration == clks;
            })
            $fatal(1, "Gen Randomization failed!");
        gen2drv_mbox.put(tr);
        tr.display("GEN_SEQ_TIME_RUN");
        @(gen_next_ev);
    endtask

    task run(int run_count);
        run_time(100);

        press_button(1, 1, 1, 0, 0, 0, "GEN_SEQ_HOUR_UP");
        press_button(1, 1, 0, 1, 0, 0, "GEN_SEQ_MIN_UP");
        press_button(1, 1, 0, 0, 1, 0, "GEN_SEQ_HOUR_DOWN");
        press_button(1, 1, 0, 0, 0, 1, "GEN_SEQ_MIN_DOWN");

        // 3. 표 스펙: change=1, sel_display=0 (Sec, Msec 수정)
        press_button(1, 0, 1, 0, 0, 0, "GEN_SEQ_SEC_UP");
        press_button(1, 0, 0, 1, 0, 0, "GEN_SEQ_MSEC_UP");
        press_button(1, 0, 0, 0, 1, 0, "GEN_SEQ_SEC_DOWN");
        press_button(1, 0, 0, 0, 0, 1, "GEN_SEQ_MSEC_DOWN");

        // 4. 조작 완료 후 일반 시간 다시 흐르도록 설정
        run_time(100);
    endtask
endclass  // generator

// ---------------------------------------------------------
// 4. Driver
// ---------------------------------------------------------
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual watch_interface watch_if;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual watch_interface watch_if, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.watch_if = watch_if;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task preset();
        watch_if.rst = 1;
        watch_if.sel_display = 0;
        watch_if.up_l = 0;
        watch_if.up_r = 0;
        watch_if.down_l = 0;
        watch_if.down_r = 0;
        watch_if.change = 0;
        repeat (5) @(posedge watch_if.clk);
        watch_if.rst = 0;
        $display("%t : [DRV] Reset Completed", $time);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);

            watch_if.sel_display = tr.sel_display;
            watch_if.up_l        = tr.up_l;
            watch_if.up_r        = tr.up_r;
            watch_if.down_l      = tr.down_l;
            watch_if.down_r      = tr.down_r;
            watch_if.change      = tr.change;

            // tr.display("DRV"); // 로그 절약을 위해 DRV 출력 생략 가능

            repeat (tr.duration) @(posedge watch_if.clk);

            ->gen_next_ev;
        end
    endtask
endclass  // driver

// ---------------------------------------------------------
// 5. Monitor
// ---------------------------------------------------------
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual watch_interface watch_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual watch_interface watch_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.watch_if = watch_if;
    endfunction

    task run();
        forever begin
            tr = new();
            @(negedge watch_if.clk);
            tr.sel_display = watch_if.sel_display;
            tr.up_l        = watch_if.up_l;
            tr.up_r        = watch_if.up_r;
            tr.down_l      = watch_if.down_l;
            tr.down_r      = watch_if.down_r;
            tr.change      = watch_if.change;

            tr.msec        = watch_if.msec;
            tr.sec         = watch_if.sec;
            tr.min         = watch_if.min;
            tr.hour        = watch_if.hour;
tr.display("MON");
            mon2scb_mbox.put(tr);
        end
    endtask
endclass  // monitor

// ---------------------------------------------------------
// 6. Scoreboard
// ---------------------------------------------------------
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            // tr.display("SCB"); // 로그가 너무 많아지면 주석 처리
        end
    endtask
endclass  // scoreboard

// ---------------------------------------------------------
// 7. Environment & Top Module
// ---------------------------------------------------------
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    virtual watch_interface watch_if;

    function new(virtual watch_interface watch_if);
        this.watch_if = watch_if;
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, watch_if, gen_next_ev);
        mon = new(mon2scb_mbox, watch_if);
        scb = new(mon2scb_mbox);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(
                1); // 고정된 헬퍼 태스크들이 순서대로 실행되므로 1번만 돌림
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
endclass  // environment

module tb_watch ();
    logic clk;

    watch_interface watch_if (clk);
    environment env;

    // DUT 인스턴스화
    watch_datapath dut (
        .clk(clk),
        .rst(watch_if.rst),
        .sel_display(watch_if.sel_display),
        .up_l(watch_if.up_l),
        .up_r(watch_if.up_r),
        .down_l(watch_if.down_l),
        .down_r(watch_if.down_r),
        .change(watch_if.change),
        .msec(watch_if.msec),
        .sec(watch_if.sec),
        .min(watch_if.min),
        .hour(watch_if.hour)
    );

    // 시뮬레이션용 빠른 시간 카운트 (10클럭마다 1틱 발생)
    defparam dut.u_TICK.F_COUNT = 10;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(watch_if);
        env.run();
        #100 $finish;
    end
endmodule

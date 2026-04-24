`timescale 1ns / 1ps

// ---------------------------------------------------------
// 1. Interface
// ---------------------------------------------------------
interface stopwatch_interface (
    input logic clk
);
    logic rst;
    logic mode;      // 0: Up count, 1: Down count
    logic clear;     // 버튼 L
    logic run_stop;  // 버튼 R
    
    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;

    // Assert: clear(버튼 L)가 눌리면 모든 카운트가 0이 되어야 함
    property clear_check;
        @(posedge clk) clear |=> (msec == 0 && sec == 0 && min == 0 && hour == 0);
    endproperty
    assert property (clear_check) else $error("%t : Clear Failed!", $time);

endinterface // stopwatch_interface

// ---------------------------------------------------------
// 2. Transaction
// ---------------------------------------------------------
class transaction;
    rand bit run_stop;
    rand bit clear;
    rand bit mode;
    rand int duration; 

    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;

    constraint c_duration { duration inside {[10:50000]}; }

    function void display(string name);
        $display("%t : [%s] run_stop(R)=%b, clear(L)=%b, mode=%b, duration=%0d clks | Time = %0d:%0d:%0d.%0d",
                 $time, name, run_stop, clear, mode, duration, hour, min, sec, msec);
    endfunction
endclass // transaction

// ---------------------------------------------------------
// 3. Generator
// ---------------------------------------------------------
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        
        // 시나리오 1: mode=0, run_stop=1, clear=0 (업 카운트로 시간이 올라감)
        tr = new();
        if (!tr.randomize() with { mode == 0; run_stop == 1; clear == 0; }) $fatal(1, "Gen error 1");
        gen2drv_mbox.put(tr);
        tr.display("GEN_SEQ_1_UP_RUN"); // 주석 해제됨
        @(gen_next_ev); 

        // 시나리오 2: mode=1, run_stop=0, clear=0 (다운 카운트 상태에서 시간 정지)
        tr = new();
        if (!tr.randomize() with { mode == 1; run_stop == 0; clear == 0; }) $fatal(1, "Gen error 2");
        gen2drv_mbox.put(tr);
        tr.display("GEN_SEQ_2_DOWN_STOP"); // 주석 해제됨
        @(gen_next_ev); 

        // 시나리오 3: clear가 딱 1번만 발생하도록 강제 지정
        tr = new();
        if (!tr.randomize() with { clear == 1; }) $fatal(1, "Gen error 3");
        gen2drv_mbox.put(tr);
        tr.display("GEN_SEQ_3_CLEAR"); // 주석 해제됨
        @(gen_next_ev); 

        // 시나리오 4: 남은 횟수(run_count)만큼 run_stop은 랜덤(0 또는 1), clear는 발생하지 않음(0)
        repeat(run_count) begin
            tr = new();
            if (!tr.randomize() with { clear == 0; }) $fatal(1, "Gen error 4");
            gen2drv_mbox.put(tr);
            tr.display("GEN_SEQ_4_RANDOM"); // 주석 해제됨
            @(gen_next_ev); 
        end
        
    endtask
endclass

// ---------------------------------------------------------
// 4. Driver
// ---------------------------------------------------------
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual stopwatch_interface stopwatch_if; 
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, virtual stopwatch_interface stopwatch_if, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.stopwatch_if = stopwatch_if;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task preset();
        stopwatch_if.rst = 1;
        stopwatch_if.clear = 0;
        stopwatch_if.run_stop = 0;
        stopwatch_if.mode = 0;
        repeat(5) @(negedge stopwatch_if.clk);
        stopwatch_if.rst = 0;
        $display("%t : [DRV] Reset Completed", $time);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            
            stopwatch_if.run_stop = tr.run_stop;
            stopwatch_if.clear    = tr.clear;
            stopwatch_if.mode     = tr.mode;
            
            tr.display("DRV");

            repeat(tr.duration) @(posedge stopwatch_if.clk);
            
            ->gen_next_ev;
        end
    endtask
endclass // driver

// ---------------------------------------------------------
// 5. Monitor
// ---------------------------------------------------------
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual stopwatch_interface stopwatch_if; 

    function new(mailbox#(transaction) mon2scb_mbox, virtual stopwatch_interface stopwatch_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.stopwatch_if = stopwatch_if;
    endfunction

    task run();
        forever begin
            tr = new();
            @(posedge stopwatch_if.clk);
            tr.run_stop = stopwatch_if.run_stop;
            tr.clear    = stopwatch_if.clear;
            tr.mode     = stopwatch_if.mode;
            tr.msec     = stopwatch_if.msec;
            tr.sec      = stopwatch_if.sec;
            tr.min      = stopwatch_if.min;
            tr.hour     = stopwatch_if.hour;
            //tr.display("MON"); // 모니터 로그는 현재 꺼져있습니다. 필요시 주석 해제하세요.
            mon2scb_mbox.put(tr);
        end
    endtask
endclass // monitor


class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    // Golden model registers
    logic [6:0] exp_msec;
    logic [5:0] exp_sec;
    logic [5:0] exp_min;
    logic [4:0] exp_hour;

    logic exp_run_stop;
    logic exp_mode;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        exp_msec = 0;
        exp_sec  = 0;
        exp_min  = 0;
        exp_hour = 0;
    endfunction

    task compare(transaction tr);

        if (tr.msec == exp_msec &&
            tr.sec  == exp_sec  &&
            tr.min  == exp_min  &&
            tr.hour == exp_hour) begin

            pass_cnt++;
            $display("%t :  PASS | DUT=%0d:%0d:%0d.%0d",
                     $time, tr.hour, tr.min, tr.sec, tr.msec);
        end
        else begin
            fail_cnt++;
            $display("%t :  FAIL | DUT=%0d:%0d:%0d.%0d | EXP=%0d:%0d:%0d.%0d",
                     $time,
                     tr.hour, tr.min, tr.sec, tr.msec,
                     exp_hour, exp_min, exp_sec, exp_msec);
        end
    endtask

    task golden_model(transaction tr);

        // clear 우선
        if (tr.clear) begin
            exp_msec = 0;
            exp_sec  = 0;
            exp_min  = 0;
            exp_hour = 0;
        end
        else if (tr.run_stop) begin
            // Up Count
            if (tr.mode == 0) begin
                exp_msec++;
                if (exp_msec == 100) begin
                    exp_msec = 0;
                    exp_sec++;
                end
                if (exp_sec == 60) begin
                    exp_sec = 0;
                    exp_min++;
                end
                if (exp_min == 60) begin
                    exp_min = 0;
                    exp_hour++;
                end
            end
            // Down Count
            else begin
                if (exp_msec > 0)
                    exp_msec--;
            end
        end
    endtask




    task run();
        forever begin
            mon2scb_mbox.get(tr);

            compare(tr);        // DUT와 비교
            golden_model(tr);   // 기대값 계산
        end
    endtask

endclass

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
    virtual stopwatch_interface stopwatch_if;

    function new(virtual stopwatch_interface stopwatch_if);
        this.stopwatch_if = stopwatch_if;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, stopwatch_if, gen_next_ev);
        mon = new(mon2scb_mbox, stopwatch_if);
        scb = new(mon2scb_mbox);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
endclass // environment

module tb_stopwatch ();
    logic clk;
    
    stopwatch_interface stopwatch_if(clk);
    environment env;

    stopwatch_datapath dut (
        .clk(clk),
        .rst(stopwatch_if.rst),
        .mode(stopwatch_if.mode),
        .clear(stopwatch_if.clear),
        .run_stop(stopwatch_if.run_stop),
        .msec(stopwatch_if.msec),
        .sec(stopwatch_if.sec),
        .min(stopwatch_if.min),
        .hour(stopwatch_if.hour)
    );
    defparam dut.u_TICK.F_COUNT = 1;
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(stopwatch_if); 
        env.run();
        #100 $finish;
    end
endmodule
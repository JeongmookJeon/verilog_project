`timescale 1ns / 1ps
interface ram_interface (  // 전선 묶음
    input clk
);
    logic [3:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface  // 완료

class transaction;
    rand bit [3:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    logic    [7:0] rdata;
    function void display(string name);
        $display("%t : [%s]we = %d, addr=%2h, wdata = %2h, rdata = %2h", $time,
                 name, we, addr, wdata, rdata);
    endfunction  //new()
endclass  //function

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
        tr = new();  //  빈 택배상자 준비
        tr.randomize();  // tr랜덤 값을 박스에 채워 넣어서
        gen2drv_mbox.put(tr);  // 우체통에 넣어 tr박스를
        tr.display("gen");
        @(gen_next_ev);
           end
    endtask  //task
endclass

class driver;
    transaction tr;
    virtual ram_interface ram_if;
    mailbox #(transaction) gen2drv_mbox;
    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;
    endfunction  //new()
    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge ram_if.clk);
            ram_if.addr  = tr.addr;  // dut에 꽂힘
            ram_if.wdata = tr.wdata;
            ram_if.we    = tr.we;
            tr.display("drv");
        end
    endtask  //run
endclass  //task

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
            tr       = new();  // 빈 상자 준비
            tr.addr  = ram_if.addr;
            tr.wdata = ram_if.wdata;
            tr.rdata = ram_if.rdata;
            tr.we    = ram_if.we;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run
endclass  //monitor

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
        this.gen_next_ev  = gen_next_ev;
        cg_sram = new();
    endfunction  //new(
    task run();
        logic [7:0] expected_ram[0:15];  // 스코어 보드 선언
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            cg_sram.sample();
            if (tr.we) begin
                expected_ram[tr.addr] = tr.wdata;
                $display("%2h", expected_ram[tr.addr]);

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
            ->gen_next_ev;
        end
    endtask  //run
endclass  //

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
        gen2drv_mbox = new();  // 빈 우체통 준비
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
endclass  //environment

module tb_sram_veri ();
    logic clk;
    environment env;
    ram_interface ram_if (clk);

    sram_veri DUT (
        .clk(clk),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .we(ram_if.we),
        .rdata(ram_if.rdata)
    );
    always #5 clk = ~clk;
    initial begin  // 전원 작업 시작하라는 지시사항
        clk = 0;
        env = new(ram_if);
        env.run();
    end
endmodule

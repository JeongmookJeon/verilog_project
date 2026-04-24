`timescale 1ns / 1ps
interface ram_if (
    input logic clk
);
    logic we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;


endinterface  //ram_if


class test;  // sw,   sw가 hw를 테스트한다.
    rand logic we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic [7:0] rdata;

    virtual ram_if r_if; //핸들러 같은 느낌.HW가 아니다. SW interface이다.그래서 가상의 HW를 받기위한 공간.

    function new(virtual ram_if r_if);
        this.r_if = r_if;
    endfunction  //new()
    virtual task write(logic [7:0] waddr, logic [7:0] data);
        r_if.we = 1;
        r_if.addr = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  // write하기위해서 4개를 묶었따.

    virtual task read(logic [7:0] raddr);
        r_if.we   = 0;
        r_if.addr = raddr;
        @(posedge r_if.clk);
    endtask

endclass  //test

class test_burst extends test;//위에있는 class의 test에서 유지하면서 확장하겠다.(위에있는 read랑 write는 안만들어도돼그러면서 기능확장)
    function new(virtual ram_if r_if);
        super.new(r_if);

    endfunction  //new()
    task write_burst(logic [7:0] waddr, logic [7:0] data, int len);
        for (int i = 0; i < len; i++) begin
            super.write(waddr, data);  // 부모 class의 write
            waddr++;
        end
    endtask
    task write(logic [7:0] waddr, logic [7:0] data);  // 재정의
        r_if.we = 1;
        r_if.addr = waddr + 1;  //addr에 더하기 1을했음.
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  //write
endclass  //test_burst
class transaction;
    logic            we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    constraint c_addr {addr inside {[8'h00 : 8'h10]};} // 특정 구역을 보고싶을 때
    constraint c_wdata {wdata inside {[8'h10 : 8'h20]};}

    function print(string name);
        $display("[name]we:%0d,addr:0x%0d, wdata:0x%0x, rdata:0x%0x", name, we,
                 addr, wdata, rdata);
    endfunction  //new()
endclass  //transaction


class test_rand extends test;  //랜덤기능이 들어가있는 test
    transaction tr;
    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction
    task write_rand(int loop);
        repeat (loop) begin
            //this.randomize(); // 이것의 인스턴스를 랜덤마이즈하겠다. 그래서 랜덤마이즈 값으로 데이터를 내보내겠다.
            tr = new();  //
            tr.randomize();
            r_if.we = 1;
            r_if.addr = tr.addr;  //핸들러. heap영역인 addr변수
            r_if.wdata = tr.wdata; // 객체의 .멤버인 wdata값을 인터페이스의 wdata로 넣겠구나 라고 그려져야함.
            @(posedge r_if.clk);
        end
    endtask  //
endclass

module tb_ram ();
    logic clk;
    ram_if r_if (clk);  // HW interface
    ram dut (
        .clk(r_if.clk),
        .we(r_if.we),
        .addr(r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );
    initial clk = 0;
    always #5 clk = ~clk;

    // task ram_write(logic [7:0] waddr, logic [7:0] data);
    //     we    = 1;
    //     addr  = waddr;
    //     wdata = data;
    //     @(posedge clk);
    // endtask  // write하기위해서 4개를 묶었따.
    //
    // task ram_read(logic [7:0] raddr);
    //     we   = 0;
    //     addr = raddr;
    //     @(posedge clk);
    // endtask  // 

    test BTS;  // 핸들러
    test_rand BlackPink;
    initial begin
        repeat (5) @(posedge clk);  // 5 clk기다림.
        BTS = new(r_if);  // nex(r_if)라는 실체화(인스턴스) 아이의 이름이 BTS이고 BTS가.write(8'h00,8'h01)동작을 한다.
        BlackPink = new(r_if);
        $display("addr=0x%0h", BTS);
        $display("addr=0x%0h", BlackPink);
        // 객체.행동 (주어BTS)가 write한다. 의인화 // 객체 지향!!!!
        BTS.write(8'h00, 8'h01);
        BTS.write(8'h01, 8'h02);
        BTS.write(8'h02, 8'h03);
        BTS.write(8'h03, 8'h04);
        BlackPink.write_rand(10);


        //ram_write(8'h00, 8'h01);
        //ram_write(8'h01, 8'h02);
        //ram_write(8'h02, 8'h03);
        //ram_write(8'h03, 8'h04);
        //
        BTS.read(8'h00);  // 객체.행동 (주어BTS)가 read한다.  의인화
        BTS.read(8'h01);
        BTS.read(8'h02);
        BTS.read(8'h03);
        // BlackPink.read(
        //     8'h00);  // 객체.행동 (주어BTS)가 read한다.  의인화
        //BlackPink.read(8'h01);
        //BlackPink.read(8'h02);
        //BlackPink.read(8'h03);
        //ram_read(8'h00);
        //ram_read(8'h01);
        //ram_read(8'h02);
        //ram_read(8'h03);

        #20;
        $finish;
    end
endmodule

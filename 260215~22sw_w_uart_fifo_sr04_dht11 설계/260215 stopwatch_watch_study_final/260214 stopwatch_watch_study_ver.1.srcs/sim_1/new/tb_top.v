`timescale 1ns / 1ps

module TOP_counter_10000_tb;
    reg clk;
    reg rst;
    reg [2:0] sw;

    reg btn_r;
    reg btn_l;
    reg btn_down_u;
    reg btn_down_d;

    wire [7:0] fnd_data;
    wire [3:0] fnd_digit;

    TOP_counter_10000 DUT (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .btn_r(btn_r),
        .btn_l(btn_l),
        .btn_down_u(btn_down_u),
        .btn_down_d(btn_down_d),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit)
    );


    always #5 clk = ~clk;   // 10ns period

    task press_button;
        output reg btn;
        begin
            btn = 1;
            #1000000;   // 1ms 유지 (debounce 통과용)
            btn = 0;
            #1000000;
        end
    endtask

    initial begin
        // 초기값
        clk = 0;
        rst = 1;
        sw = 3'b000;

        btn_r = 0;
        btn_l = 0;
        btn_down_u = 0;
        btn_down_d = 0;

        // 리셋 해제
        #100;
        rst = 0;


        $display("=== STOPWATCH MODE ===");

        // run
        press_button(btn_r);

        #100000000;  // 100ms 동작

        // stop
        press_button(btn_r);

        // clear
        press_button(btn_l);

        #50000000;


        $display("=== WATCH MODE ===");

        sw[1] = 1;   // watch 모드
        sw[0] = 1;   // change 모드

        #1000000;

        // 시간 증가
        press_button(btn_down_u);
        press_button(btn_down_d);

        #50000000;

        // change 종료 → 정상 동작 모드
        sw[0] = 0;

        #200000000;

        $display("=== SIMULATION END ===");
        $stop;
    end

endmodule
`timescale 1ns / 1ps

module tb_sr04_controller ();

    reg clk;
    reg rst;
    reg start;
    reg echo;

    wire trigger;
    wire [15:0] dist_data;
    wire done;

    // DUT 연결
    sr04_controller DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .echo(echo),
        .trigger(trigger),
        .dist_data(dist_data),
        .done(done)
    );

    // 100MHz 클럭 생성
    always #5 clk = ~clk;

    initial begin
        // 1. 초기화
        #0;
        clk = 0;
        rst = 1;
        start = 0;
        echo = 0;

        // 2. 리셋 해제
        #20;
        rst = 0;

        // 3. Start 신호 주기 (측정 시작)
        #100;
        start = 1;
        #20;       // 2클럭 동안 유지
        start = 0;

        // 4. Trigger 나가는 시간 기다리기 
        // (컨트롤러가 10us(10,000ns) 동안 Trigger를 쏨)
        #15000;    // 넉넉히 15us 대기

        // 5. 가상의 Echo 신호 만들기 (거리 100cm 상황)
        // 100cm * 58us = 5800us
        // 5800us = 5,800,000ns
        echo = 1;
        #5800000;  // 100cm 거리만큼 시간 끌기
        echo = 0;

        // 6. 결과 확인 대기 (Done 신호와 dist_data=100 확인용)
        #200;
        
        $stop;
    end

endmodule
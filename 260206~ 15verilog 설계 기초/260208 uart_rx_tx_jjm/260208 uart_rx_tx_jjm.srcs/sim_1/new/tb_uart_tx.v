`timescale 1ns / 1ps

module tb_uart_tx_with_gen;

    // ==========================================
    // 1. 신호 선언
    // ==========================================
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;

    // b_tick은 이제 우리가 만드는 게 아니라, 모듈에서 받아오는 '선(wire)'입니다.
    wire w_b_tick; 
    
    wire uart_tx;
    wire tx_busy;
    wire tx_done;

    // ==========================================
    // 2. 모듈 인스턴스 (두 친구를 연결!)
    // ==========================================
    
    // [1] 박자 생성기 (작성하신 모듈)
    baud_tickgen u_baud_gen (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick) // 여기서 만든 박자를 w_b_tick으로 내보냄
    );

    // [2] 송신기 (테스트 대상)
    uart_tx uut (
        .clk(clk), 
        .rst(rst), 
        .tx_start(tx_start), 
        .b_tick(w_b_tick), // 생성된 박자를 입력으로 받음
        .tx_data(tx_data), 
        .uart_tx(uart_tx), 
        .tx_busy(tx_busy), 
        .tx_done(tx_done)
    );

    // ==========================================
    // 3. 100MHz 클럭 생성
    // ==========================================
    initial clk = 0;
    always #5 clk = ~clk;

    // ==========================================
    // 4. 테스트 시나리오
    // ==========================================
    initial begin
        // 초기화
        rst = 1;
        tx_start = 0;
        tx_data = 0;

        // 리셋 해제
        #100;
        rst = 0;
        #100;

        // -----------------------------------------------------
        // Case 1: 문자 'r' (0x72) 전송
        // -----------------------------------------------------
        $display("[Time %t] Simulation Start...", $time);
        
        @(posedge clk);
        tx_data = 8'h72;    
        tx_start = 1;       
        
        @(posedge clk);
        tx_start = 0;       

        // Busy 확인
        wait(tx_busy == 1);
        $display("[Time %t] TX Busy...", $time);

        // 완료 대기 (실제 9600bps 속도로 동작하므로 오래 걸림)
        wait(tx_done == 1);
        $display("[Time %t] TX Done!", $time);

        #1000;
        $stop;
    end

endmodule
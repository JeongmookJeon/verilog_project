`timescale 1ns / 1ps

module tb_simple_r_test();

    reg clk;
    reg reset;
    reg [2:0] sw;
    reg uart_rx; // PC -> FPGA
    wire uart_tx;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    // DUT 연결
    top_uart_watch dut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .btn_r(1'b0), .btn_l(1'b0), .btn_u(1'b0), .btn_d(1'b0), // 버튼은 안 누름
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    // 100MHz 클럭
    always #5 clk = ~clk;

    // 9600bps 속도 (약 104us)
    localparam BIT_PERIOD = 104167; 

    initial begin
        // 초기화
        clk = 0;
        reset = 1;
        uart_rx = 1; // 대기 상태 (High)
        sw = 3'b000; // 스톱워치 모드
        
        #1000 reset = 0; // 리셋 해제
        
        // ----------------------------------------------------
        // 여기서 'r' (0x72 = 0111_0010)을 보냅니다.
        // ----------------------------------------------------
        #10000; // 10us 대기 후 시작
        
        // 1. Start Bit (Low로 쿵 떨어짐 -> 여기서 파형이 변해야 함)
        uart_rx = 0; 
        #(BIT_PERIOD);
        
        // 2. Data Bits (0x72의 역순: 0-1-0-0-1-1-1-0)
        uart_rx = 0; #(BIT_PERIOD); // bit 0
        uart_rx = 1; #(BIT_PERIOD); // bit 1
        uart_rx = 0; #(BIT_PERIOD); // bit 2
        uart_rx = 0; #(BIT_PERIOD); // bit 3
        uart_rx = 1; #(BIT_PERIOD); // bit 4
        uart_rx = 1; #(BIT_PERIOD); // bit 5
        uart_rx = 1; #(BIT_PERIOD); // bit 6
        uart_rx = 0; #(BIT_PERIOD); // bit 7
        
        // 3. Stop Bit (High로 복귀)
        uart_rx = 1; 
        #(BIT_PERIOD);
        
        // 데이터 전송 끝. 이제 디코더가 반응하는지 관찰
        #1000000; 
        $finish;
    end

endmodule
`timescale 1ns / 1ps

module tb_uart_top_r();

    // ==========================================
    // 1. 파라미터 및 변수 설정
    // ==========================================
    parameter BAUD = 9600;
    // 9600bps 1비트 시간 (약 104,160ns)
    parameter BAUD_PERIOD = 104160; 

    reg clk, rst;
    reg uart_rx; // PC에서 들어오는 신호
    
    // 관찰할 신호들
    wire uart_tx;
    wire [7:0] rx_data;
    wire rx_done;

    // 테스트용 변수
    reg [7:0] test_data;
    integer i;

    // ==========================================
    // 2. DUT 연결
    // ==========================================
    uart_top dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .i_tx_start(1'b0), // 송신 테스트는 안 할 거라 0
        .i_tx_data(8'b0),
        .o_tx_busy()
    );

    // ==========================================
    // 3. 클럭 생성
    // ==========================================
    always #5 clk = ~clk;

    // ==========================================
    // 4. PC 데이터 송신 Task (PC -> FPGA)
    // ==========================================
    task uart_sender();
        begin
            // Start Bit (0)
            uart_rx = 1'b0;
            i=0;
            #(BAUD_PERIOD);
            
            // Data Bits (LSB부터 8개)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = test_data[i];
                #(BAUD_PERIOD);
            end
            
            // Stop Bit (1)
            uart_rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    // ==========================================
    // 5. 테스트 시나리오 ('r' 전송)
    // ==========================================
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        uart_rx = 1'b1; // Idle 상태 (High)
        test_data = 0;

        // 리셋 해제
        #200;
        rst = 0;
        #200;

        // ------------------------------------------------
        // [테스트] 문자 'r' (0x72) 전송 -> Run/Stop 트리거
        // ------------------------------------------------
        $display("[Time %t] Sending 'r' (0x72) to start Stopwatch...", $time);
        
        test_data = 8'h72; // 'r' (Run/Stop)
        uart_sender();     // 전송 시작!

        // 전송이 끝나면 rx_done이 뜨고, 내부적으로 Run 신호가 발생했을 것임.
        // 이를 확인하기 위해 조금 기다림.
        #(BAUD_PERIOD * 5);

        // ------------------------------------------------
        // [추가 테스트] 문자 'l' (0x6C) 전송 -> Clear 확인 (선택사항)
        // ------------------------------------------------
        $display("[Time %t] Sending 'l' (0x6C) to Clear...", $time);
        
        test_data = 8'h6C; // 'l' (Clear)
        uart_sender();

        #(BAUD_PERIOD * 5);
        
        $display("[Time %t] Test Finished", $time);
        $stop;
    end

endmodule
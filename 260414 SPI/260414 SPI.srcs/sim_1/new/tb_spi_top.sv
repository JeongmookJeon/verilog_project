`timescale 1ns / 1ps

module spi_top_tb;

    // 1. 테스트벤치 내부 신호 선언 (Top 모듈의 포트와 매핑)
    logic       clk;
    logic       reset;

    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic       master_start;
    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_busy;

    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic       slave_done;

    // 2. DUT (Design Under Test) 인스턴스화
    spi_top u_spi_top (
        .clk            (clk),
        .reset          (reset),
        .cpol           (cpol),
        .cpha           (cpha),
        .clk_div        (clk_div),
        .master_tx_data (master_tx_data),
        .master_start   (master_start),
        .master_rx_data (master_rx_data),
        .master_done    (master_done),
        .master_busy    (master_busy),
        .slave_tx_data  (slave_tx_data),
        .slave_rx_data  (slave_rx_data),
        .slave_done     (slave_done)
    );

    // 3. 시스템 클럭 생성 (100MHz 설정: 10ns 주기)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. 시뮬레이션 시나리오 구성
    initial begin
        // 초기화 단계
        reset = 1'b1;
        cpol = 1'b0;
        cpha = 1'b0;
        clk_div = 8'd4;         // 마스터 모듈에서 SCLK 분주를 위한 설정값
        master_tx_data = 8'h00;
        master_start = 1'b0;
        slave_tx_data = 8'h00;

        // 리셋 해제
        #20;
        reset = 1'b0;
        #20;

        // =========================================================
        // 시나리오 1: SPI Mode 0 검증 (CPOL=0, CPHA=0)
        // Master 송신 데이터: 8'h5A, Slave 송신 데이터: 8'hC3
        // =========================================================
        $display("----------------------------------------");
        $display("[TEST 1] 시작: SPI Mode 0 (CPOL=0, CPHA=0)");
        cpol = 1'b0;
        cpha = 1'b0;
        
        // 송신할 데이터 셋업
        master_tx_data = 8'h5A; // 0101_1010
        slave_tx_data  = 8'hC3; // 1100_0011

        // 마스터 통신 시작 신호 인가 (1 클럭 주기 동안 High)
        #10;
        master_start = 1'b1;
        #10;
        master_start = 1'b0;

        // 마스터의 done 신호가 발생할 때까지 대기
        wait(master_done == 1'b1);
        #20;

        // 송수신 결과 출력 및 비교 검증
        $display("Master 수신 데이터: 0x%0h (예상값: 0xc3)", master_rx_data);
        $display("Slave 수신 데이터:  0x%0h (예상값: 0x5a)", slave_rx_data);
        
        if (master_rx_data == 8'hC3 && slave_rx_data == 8'h5A)
            $display("-> [TEST 1] 결과: PASS");
        else
            $display("-> [TEST 1] 결과: FAIL");

        #100;

        // =========================================================
        // 시나리오 2: SPI Mode 3 검증 (CPOL=1, CPHA=1)
        // Master 송신 데이터: 8'h11, Slave 송신 데이터: 8'hEE
        // =========================================================
        $display("----------------------------------------");
        $display("[TEST 2] 시작: SPI Mode 3 (CPOL=1, CPHA=1)");
        cpol = 1'b1;
        cpha = 1'b1;
        
        // 송신할 데이터 셋업
        master_tx_data = 8'h11; // 0001_0001
        slave_tx_data  = 8'hEE; // 1110_1110

        // 마스터 통신 시작 신호 인가
        #10;
        master_start = 1'b1;
        #10;
        master_start = 1'b0;

        // 마스터의 done 신호가 발생할 때까지 대기
        wait(master_done == 1'b1);
        #20;

        // 송수신 결과 출력 및 비교 검증
        $display("Master 수신 데이터: 0x%0h (예상값: 0xee)", master_rx_data);
        $display("Slave 수신 데이터:  0x%0h (예상값: 0x11)", slave_rx_data);
        
        if (master_rx_data == 8'hEE && slave_rx_data == 8'h11)
            $display("-> [TEST 2] 결과: PASS");
        else
            $display("-> [TEST 2] 결과: FAIL");

        $display("----------------------------------------");

        // 시뮬레이션 종료
        #100;
        $finish;
    end

    // 파형 디버깅을 위한 VCD 파일 덤프 (Vivado, VCS, ModelSim 등 사용 시)
    initial begin
        $dumpfile("spi_top_tb.vcd");
        $dumpvars(0, spi_top_tb);
    end

endmodule
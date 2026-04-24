`timescale 1ns / 1ps

module tb_spi_slave_test ();

    // 1. 시스템 및 DUT 연결 신호
    logic       clk;
    logic       reset;
    logic       sclk;
    logic       mosi;
    logic       cs_n;

    logic [7:0] rx_data;
    logic       done;
    logic       miso;

    // 2. DUT (Device Under Test) 인스턴스화
    spi_slave dut (
        .clk    (clk),
        .reset  (reset),
        .rx_data(rx_data),
        .done   (done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    // 3. 시스템 클럭 생성 (100MHz, 주기 10ns)
    always #5 clk = ~clk;

    // 4. 테스트 시나리오
    logic [7:0] test_data = 8'hA5; // 슬레이브로 보낼 테스트 데이터 (1010_0101)
    int i;

    initial begin
        // 초기화
        clk   = 0;
        reset = 1;
        sclk  = 0;
        mosi  = 0;
        cs_n  = 1;

        // 리셋 유지 후 해제
        repeat (3) @(posedge clk);
        reset = 0;
        repeat (2) @(posedge clk);

        // 1. 통신 시작 (Chip Select Low)
        @(posedge clk);
        cs_n = 0;

        // START 상태를 거치기 위해 1클럭 대기
        @(posedge clk);

        // 2. 8비트 데이터 전송 루프 (MSB부터 1비트씩)
        for (i = 7; i >= 0; i--) begin
            // [송신 준비] sclk가 0일 때 mosi에 1비트 데이터를 올려둡니다.
            sclk = 0;
            mosi = test_data[i];

            // 회원님의 RTL 코드(`else` 구문)가 동작하도록 1클럭 유지
            repeat (5) @(posedge clk);

            // [수신 타이밍] sclk를 1로 올려서 슬레이브가 mosi를 읽어가게 합니다.
            sclk = 1;

            // 회원님의 RTL 코드(`if(sclk)` 구문)가 동작하도록 1클럭 유지
            repeat (5) @(posedge clk);
        end

        // 3. 마지막 비트 처리 후 SCLK 내리기
        sclk = 0;

        // done 신호가 뜰 때까지 대기
        wait (done);
        repeat (5) @(posedge clk);

        // 4. 통신 종료 (Chip Select High)
        cs_n = 1;

        #50;
        $finish;
    end

endmodule


/* `timescale 1ns / 1ps

module tb_spi_slave ();
    logic       clk;
    logic       reset;
    logic [7:0] rx_data;
    logic       done;
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;


    spi_slave dut1 (
        .clk    (clk),
        .reset  (reset),
        .rx_data(rx_data),
        .done   (done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    //always #50 sclk = ~sclk;
    always #5 clk = ~clk;

    logic [2:0] count = 0;
    

 always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            sclk  <= 0;
        end else if (!cs_n) begin // 통신 중일 때만
            if (count == 4) begin 
                count <= 0;
                sclk  <= ~sclk;
            end else begin
                count <= count + 1;
            end
        end else begin
            sclk  <= 0; // 통신이 아닐 때는 Low 유지 (Mode 0)
            count <= 0;
        end
    end

    initial begin
        clk   = 0;
        reset = 1;
        cs_n  = 1'b1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        cs_n = 1'b0;
        repeat (10) @(posedge clk);
        mosi = 1'b1;
        repeat (10) @(posedge clk);
        mosi = 1'b0;
        repeat (10) @(posedge clk);
        mosi = 1'b1;
        repeat (10) @(posedge clk);
        mosi = 1'b0;
        repeat (10) @(posedge clk);
        mosi = 1'b1;
        repeat (10) @(posedge clk);
        mosi = 1'b0;
        repeat (10) @(posedge clk);
        mosi = 1'b1;
        repeat (10) @(posedge clk);
        mosi = 1'b0;
        repeat (10) @(posedge clk);
 
        wait (done);
        repeat (10) @(posedge clk);
        #20;
        $finish;
    end

endmodule
*/

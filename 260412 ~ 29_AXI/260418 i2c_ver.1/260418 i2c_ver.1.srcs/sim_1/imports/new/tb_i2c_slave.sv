`timescale 1ns / 1ps

module tb_i2c_slave ();
    logic clk;
    logic reset;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic busy, done;

    // I2C 물리 라인 (Pull-up 필요)
    wire scl;
    wire sda;

    // Master 드라이빙용 내부 신호
    logic scl_m, sda_m;

    // Open-drain 로직: 1일 때 'z'를 내보내어 Pull-up이 작동하게 함
    assign scl = (scl_m) ? 1'bz : 1'b0;
    assign sda = (sda_m) ? 1'bz : 1'b0;

    // 물리적인 Pull-up 저항 시뮬레이션
    pullup (scl);
    pullup (sda);

    localparam SLAVE_ADDR = 7'h5A;

    I2C_SLAVE dut (.*);

    always #5 clk = ~clk;
    localparam T_HALF = 5000;  // 5us
    localparam T_QTR = 2500;  // 2.5us

    task i2c_start();
        scl_m = 1;
        sda_m = 1;
        #T_QTR;
        sda_m = 0;
        #T_QTR;  // START 조건
        scl_m = 0;
        #T_QTR;
    endtask

    task i2c_write_byte(input [7:0] data);
        for (int i = 7; i >= 0; i--) begin
            sda_m = data[i];
            #T_QTR;
            scl_m = 1;
            #(T_QTR * 2);
            scl_m = 0;
            #T_QTR;
        end
        // ACK 수신 구간
        sda_m = 1;
        #T_QTR;  // SDA 해제 (Slave ACK 대기)
        scl_m = 1;
        #T_QTR;
        if (sda === 0) $display("[MASTER] ACK Received for data: %h", data);
        else $display("[MASTER] NACK Received!");
        #T_HALF;
        scl_m = 0;
        #T_QTR;
    endtask

    task i2c_stop();
        sda_m = 0;
        scl_m = 0;
        #T_QTR;
        scl_m = 1;
        #T_QTR;
        sda_m = 1;
        #T_QTR;  // STOP 조건
        $display("[MASTER] Stop Condition");
    endtask

    // --- 실행 시나리오 ---
    initial begin
        // 초기화
        clk = 0;
        reset = 1;
        scl_m = 1;
        sda_m = 1;
        tx_data = 8'h00;

        repeat (10) @(posedge clk);
        reset = 0;
        #100;

        // 주소 전송 (Write 모드)
        i2c_start();
        i2c_write_byte({SLAVE_ADDR, 1'b0});  // 7'h5A + Write(0)

        // 데이터 전송
        i2c_write_byte(8'h55);
        i2c_write_byte(8'hAA);
        i2c_write_byte(8'h01);
        i2c_write_byte(8'h02);
        i2c_write_byte(8'h03);
        i2c_write_byte(8'h04);
        i2c_write_byte(8'hff);

        i2c_stop();

        #500;
        $finish;
    end

endmodule

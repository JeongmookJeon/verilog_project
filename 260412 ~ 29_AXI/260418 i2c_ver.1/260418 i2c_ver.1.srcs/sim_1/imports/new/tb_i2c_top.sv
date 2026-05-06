`timescale 1ns / 1ps

`timescale 1ns / 1ps

module tb_i2c_top ();
    logic clk;
    logic reset;
    logic cmd_start, cmd_write, cmd_read, cmd_stop;
    logic [7:0] m_tx_data;
    logic [7:0] s_tx_data;  // Slave로 들어갈 데이터
    logic       ack_in;     // Master가 Slave에게 보낼 응답 신호
    logic [7:0] m_rx_data;
    logic [7:0] s_rx_data;
    logic m_done, s_done;
    logic ack_out;
    logic m_busy, s_busy;

    localparam SLAVE_ADDR = 7'h5A;

    i2c_top dut (.*);

    always #5 clk = ~clk;

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_addr(byte addr);
        m_tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        m_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    // Master가 Slave에게 보낼 응답(ACK=0, NACK=1)을 인자로 받습니다.
    task i2c_read(logic send_nack);
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        ack_in    = send_nack; // 마스터에게 ACK/NACK 지시
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    initial begin
        clk       = 0;
        reset     = 1;
        ack_in    = 0;
        s_tx_data = 8'h00;  
        repeat (10) @(posedge clk);
        reset = 0;
        @(posedge clk);
        i2c_start();
        i2c_addr((SLAVE_ADDR << 1) | 1'b0);
        i2c_write(8'h11); 
        i2c_write(8'h22); 
        i2c_write(8'h33); 
        i2c_write(8'h44); 
        i2c_stop();
        #200; 
        i2c_start();
        s_tx_data = 8'hA1;
        i2c_addr((SLAVE_ADDR << 1) | 1'b1);
        s_tx_data = 8'hA2;
        i2c_read(1'b0);  
        s_tx_data = 8'hA3;
        i2c_read(1'b0);  
        s_tx_data = 8'hA4;
        i2c_read(1'b0); 
        s_tx_data = 8'h00; 
        i2c_read(1'b1);  
        i2c_stop();
        #100;
        $finish;
    end
endmodule

/*
module tb_i2c_top ();
    logic clk;
    logic reset;
    logic cmd_start, cmd_write, cmd_read, cmd_stop;
    logic [7:0] m_tx_data;
    logic [7:0] s_tx_data;  // Slave로 들어갈 데이터
    logic       ack_in;  // Master가 Slave에게 보낼 응답 신호
    logic [7:0] m_rx_data;
    logic [7:0] s_rx_data;
    logic m_done, s_done;
    logic ack_out;
    logic m_busy, s_busy;

    localparam SLAVE_ADDR = 7'h5A;

    i2c_top dut (.*);

    always #5 clk = ~clk;

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_addr(byte addr);
        m_tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        m_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    // Master가 Slave에게 보낼 응답(ACK=0, NACK=1)을 인자로 받습니다.
    task i2c_read(logic send_nack);
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        ack_in    = send_nack; // 마스터에게 ACK/NACK 지시
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    initial begin
        clk       = 0;
        reset     = 1;
        ack_in    = 0;
        s_tx_data = 8'h00;  // 초기 데이터 쓰레기값 방지
        repeat (10) @(posedge clk);
        reset = 0;
        @(posedge clk);

        // [Step 1] 통신 시작
        i2c_start();

        // [Step 2] 주소 전송 및 첫 데이터(A1) 사전 장전
        // Slave는 ADDR_ACK 상태가 끝날 때 첫 번째 데이터를 레지스터에 올립니다.
        // 따라서 주소를 보내기 직전에 첫 데이터를 미리 준비해야 합니다.
        s_tx_data = 8'hA1;
        i2c_addr((SLAVE_ADDR << 1) | 8'h01);

        // [Step 3] 데이터 연속 읽기 및 파이프라이닝
        // 현재 Master가 이전 데이터를 읽고 있는 동안, 
        // Slave가 9번째 클럭에서 가져갈 '다음 데이터'를 한 박자 먼저 갱신합니다.

        s_tx_data = 8'hA1;
        i2c_read(1'b0);  // ★ 0(ACK) 전송: "잘 받았어, 다음 거 줘!"

        s_tx_data = 8'hA2;
        i2c_read(1'b0);  // ★ 0(ACK) 전송

        s_tx_data = 8'hA3;
        i2c_read(1'b0);  // ★ 0(ACK) 전송

        s_tx_data = 8'hA4;
        i2c_read(1'b0);  // ★ 0(ACK) 전송

        s_tx_data = 8'hA5;
        i2c_read(1'b0);  // ★ 0(ACK) 전송

       s_tx_data = 8'hA6;
        i2c_read(1'b1);  // ★  1(NACK) 전송: "이제 그만 줘!"

        // [Step 4] 통신 종료
        i2c_stop();

        #100;
        $finish;
    end
endmodule
*/
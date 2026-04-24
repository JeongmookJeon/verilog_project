`timescale 1ns / 1ps



module slave_top (
    input  logic       clk,          // 100MHz 시스템 클럭
    input  logic       reset,        // Active High 리셋 버튼 (U18)

    // SPI Slave 외부 인터페이스
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs_n,

    // 내부 UI: 스위치 및 LED
    input  logic [7:0] sw_tx_data,   // 슬레이브 송신 데이터 (스위치)
    output logic [7:0] led_rx_data,  // 수신 데이터 확인용 LED
    output logic       led_done,     // 통신 완료 플래그 (LED)

    // 내부 UI: FND (7-Segment) 인터페이스
    output logic [3:0] fnd_digit,    // FND 자릿수 선택 (Anode)
    output logic [7:0] fnd_data      // FND 세그먼트 데이터 (Cathode)
);

    logic [7:0] rx_data_reg;
    logic done_sig;

    // 1. SPI Slave 인스턴스화
    spi_slave u_spi_slave (
        .clk     (clk),
        .reset   (reset),
        .tx_data (sw_tx_data),
        .rx_data (rx_data_reg),
        .done    (done_sig),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .cs_n    (cs_n)
    );

    // 2. LED 레지스터 갱신 (수신 완료 시 데이터 유지)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led_rx_data <= 8'h00;
            led_done    <= 1'b0;
        end else if (done_sig) begin
            led_rx_data <= rx_data_reg;
            led_done    <= 1'b1;
        end else begin
            led_done    <= 1'b0;
        end
    end

    // 3. FND Controller 인스턴스화
    // rx_data_reg(8비트)를 fnd_in_data(14비트)에 맞춰 확장하여 연결합니다.
    fnd_controller u_fnd_controller (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data({6'd0, rx_data_reg}), // 상위 6비트는 0으로 패딩
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module spi_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       sclk,
    input  logic       mosi,     //[master] out slave in
    output logic       miso,     // master in [slave] out
    input  logic       cs_n      //  active low signal
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e       state;
    logic       [7:0] tx_shift_reg;
    logic       [7:0] rx_shift_reg;
    logic       [2:0] bit_cnt;  // 8bit siganl reg & count
    logic       [1:0] sclk_sync;
    logic       [1:0] cs_n_sync;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync <= 2'b00;
            // cs_n은 high 유지 후 select될 시 low로 떨어짐
            cs_n_sync <= 2'b11;
        end else begin
            //매 시스템 clk마다 신호를 시프트 하여 저장
            sclk_sync <= {sclk_sync[0], sclk};
            cs_n_sync <= {cs_n_sync[0], cs_n};
        end

    end
    wire sclk_rising = (sclk_sync == 2'b01);  // 0에서 1로 변하는 '순간'
    wire sclk_falling = (sclk_sync == 2'b10); // 1에서 0으로 변하는 '순간'
    wire cs_n_falling = (cs_n_sync == 2'b10);  // 통신 시작의 '순간'
    wire cs_n_rising  = (cs_n_sync == 2'b01); // 통신 강제 종료의 '순간'

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            miso    <= 1'bz;
            rx_data <= 0;
            done    <= 1'b0;
            tx_shift_reg <=0;
            rx_shift_reg <=0;
            bit_cnt <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    miso    <= 1'bz;
                    bit_cnt <= 0;
                    if (cs_n_falling) begin
                        tx_shift_reg <= tx_data;
                        state <= START;
                    end
                end
                //슬레이브 송신
                START: begin
                    //7번째 bit를 보냄(MSB)
                    //phase '0' 규칙 : SCLK 첫 엣지 전 miso 선에 대기.
                    miso <= tx_shift_reg[7];
                    //7번쨰 bit부터 0으로 채워짐
                    //shift regist
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    state <= DATA;
                end
                //마스터 수신
                DATA: begin
                    //통신 도중 마스터가 CS_N을 올려버리면 즉시 중단
                    if (cs_n_rising) begin
                        state <= IDLE;
                        //수신(phase '0'의 첫번째 엣지 = 상승엣지)
                    end else if (sclk_rising) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                        //송신(phase '0'의 두번째 엣지 = 하강엣지)
                    end else if (sclk_falling) begin
                        if (bit_cnt < 7) begin
                            miso         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_cnt      <= bit_cnt + 1;
                            //bit_cnt ==7이 되었을 때 state를 stop으로 변화
                        end else begin
                            state   <= STOP;
                            //8bit 모두 수신완료
                            rx_data <= rx_shift_reg;
                        end
                    end
                end
                STOP: begin
                    //rx_data <= rx_shift_reg;
                    miso    <= 1'bz;
                    done    <= 1'b1;
                    bit_cnt <= 0;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

/*
module spi_slave (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       sclk,
    input  logic       mosi,     //[master] out slave in
    output logic       miso,     // master in [slave] out
    input  logic       cs_n      //  active low signal
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;  // 8bit siganl reg & count
    //logic sclk_r;  // sclk register

    //assign sclk = ~sclk;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            miso    <= 1'b1;
            rx_data <= 0;
            done    <= 1'b0;
            bit_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    miso    <= 1'b1;
                    rx_data <= 0;
                    bit_cnt <= 0;
                    done    <= 1'b0;
                    if (!cs_n) begin
                        state <= START;
                    end
                end
                //슬레이브 송신
                START: begin
                    //7번째 bit를 보냄(MSB)
                    miso <= rx_shift_reg[7];
                    //7번쨰 bit부터 0으로 채워짐
                    rx_shift_reg <= {rx_shift_reg[6:0], 1'b0};
                    state <= DATA;
                end
                //마스터 수신
                DATA: begin
                    if (sclk) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                    end else begin  //송신 구간
                        if (bit_cnt < 7) begin
                            miso <= rx_shift_reg[7];
                            rx_shift_reg <= {rx_shift_reg[6:0], 1'b0};
                        end
                        if (bit_cnt == 7) begin
                            state   <= STOP;
                            rx_data <= rx_shift_reg;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                STOP: begin
                    rx_data <= rx_shift_reg;
                    miso    <= 1'b1;
                    sclk_r  <= 1'b0;
                    done    <= 1'b1;
                    bit_cnt <= 0;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
*/

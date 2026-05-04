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



module fnd_controller (
    input        clk,
    input        reset,
    input  [13:0] fnd_in_data,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4x1_out;
    wire [1:0] w_digit_sel;
    wire w_1khz;

    digit_splitter U_DIGIT_SPL (
        .in_data(fnd_in_data),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk(w_1khz),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel(w_digit_sel),
        .fnd_digit(fnd_digit)
    );

    mux_4x1 U_MUX_4x1 (
        .sel(w_digit_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out(w_mux_4x1_out)
    );

    bcd U_BCD (
        .bcd(w_mux_4x1_out),
        .fnd_data(fnd_data)
    );

endmodule

module clk_div (
    input      clk,
    input      reset,
    output reg o_1khz
);
    
    reg [16:0] counter_r; // [16:0] 대신 {$clog2(100_000):0]로 해도 된다.

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_1khz    <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz    <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz    <= 1'b0;
            end
        end    
    end

endmodule

module counter_4 (
    input        clk,
    input        reset,
    output [1:0] digit_sel
);
    reg [1:0] counter_r;

    assign digit_sel = counter_r;

    always @(posedge clk or posedge reset) begin
        if (reset == 1) begin
            // init courter_r
            counter_r <= 0;
        end else begin
            // to do 
            counter_r <= counter_r + 1;
        end
    end
    
endmodule

// to select to fnd digit display
module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] fnd_digit
);

    always @(digit_sel) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
        endcase
    end        

endmodule

module mux_4x1 (
    input      [1:0] sel,
    input      [3:0] digit_1,
    input      [3:0] digit_10,
    input      [3:0] digit_100,
    input      [3:0] digit_1000,
    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;
        endcase
    end

endmodule

module digit_splitter (
    input  [13:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

    assign digit_1 = in_data % 10;
    assign digit_10 = (in_data/10) % 10;
    assign digit_100 = (in_data/100) % 10;
    assign digit_1000 = (in_data/1000) % 10;

endmodule

module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;

            default: fnd_data = 8'hFF;
        endcase
    end

endmodule



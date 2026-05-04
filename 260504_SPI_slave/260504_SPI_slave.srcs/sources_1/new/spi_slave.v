`timescale 1ns / 1ps

// =======================================================
// Top Module: SPI Slave
// 동작: 스위치(sw_tx_data)값을 Master로 전송하고,
//       Master로부터 수신한 데이터를 FND에 십진수로 표시
// =======================================================
module slave_top (
    input  wire       sys_clock,    // 100MHz System Clock (Basys3 W5)
    input  wire       reset,        // Active High Reset   (BTNC U18)

    // SPI Interface (JA 포트)
    input  wire       sclk,         // JA4 G2
    input  wire       cs_n,         // JA3 J2
    input  wire       mosi,         // JA1 J1
    output wire       miso,         // JA2 L2

    // 사용자 입력: 스위치 8개 (Slave가 Master에게 보낼 데이터)
    input  wire [7:0] sw_tx_data,   // SW[7:0] -> GPIOB

    // FND 출력
    output wire [3:0] fnd_digit,    // Anode  (7-segment 자릿수 선택)
    output wire [7:0] fnd_data      // Cathode (7-segment 세그먼트)
);

    wire [7:0] rx_data_sig;
    wire       done_sig;
    wire       busy_sig;

    // done 시점에 수신 데이터를 래치
    reg [7:0] rx_data_reg;

    // SPI Slave
    spi_slave U_SPI_SLAVE (
        .clk     (sys_clock),
        .rst     (reset),
        .sclk    (sclk),
        .cs_n    (cs_n),
        .mosi    (mosi),
        .tx_data (sw_tx_data),
        .rx_data (rx_data_sig),
        .miso    (miso),
        .done    (done_sig),
        .busy    (busy_sig)
    );

    // 수신 완료(done) 시 데이터 래치
    always @(posedge sys_clock or posedge reset) begin
        if (reset)
            rx_data_reg <= 8'd0;
        else if (done_sig)
            rx_data_reg <= rx_data_sig;
    end

    // FND 컨트롤러: 수신 데이터(0~255)를 십진수로 FND 표시
    fnd_controller U_FND_CTRL (
        .clk         (sys_clock),
        .reset       (reset),
        .fnd_in_data ({6'd0, rx_data_reg}),  // 14비트 (0~255 범위)
        .fnd_digit   (fnd_digit),
        .fnd_data    (fnd_data)
    );

endmodule


// =======================================================
// SPI Slave FSM
// CPOL=0, CPHA=0 (Mode 0): 상승엣지 샘플링, 하강엣지 전송
// =======================================================
module spi_slave (
    input  wire       clk,
    input  wire       rst,
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        miso,
    output reg        done,
    output reg        busy
);

    localparam IDLE    = 3'd0;
    localparam START   = 3'd1;
    localparam DATA_RX = 3'd2;
    localparam DATA_TX = 3'd3;
    localparam STOP    = 3'd4;

    reg [2:0] c_state, n_state;

    reg [7:0] rx_data_next;
    reg [7:0] tx_shift_reg, tx_shift_next;
    reg [7:0] rx_shift_reg, rx_shift_next;
    reg [3:0] bit_cnt_reg,  bit_cnt_next;
    reg       miso_next;
    reg       done_next, busy_next;

    wire sclk_pedge, sclk_nedge;

    edge_detector U_EDGE_DETECTOR (
        .clk     (clk),
        .rst     (rst),
        .data_in (sclk),
        .pedge   (sclk_pedge),
        .nedge   (sclk_nedge)
    );

    // Sequential Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            rx_data      <= 8'd0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            miso         <= 1'b0;
            done         <= 1'b0;
            busy         <= 1'b0;
            bit_cnt_reg  <= 4'd0;
        end else begin
            c_state      <= n_state;
            rx_data      <= rx_data_next;
            tx_shift_reg <= tx_shift_next;
            rx_shift_reg <= rx_shift_next;
            miso         <= miso_next;
            done         <= done_next;
            busy         <= busy_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    // Combinational Logic (FSM)
    always @(*) begin
        // 기본값 (래치 방지)
        n_state       = c_state;
        rx_data_next  = rx_data;
        tx_shift_next = tx_shift_reg;
        rx_shift_next = rx_shift_reg;
        miso_next     = miso;
        done_next     = 1'b0;       // done은 1클럭 펄스
        busy_next     = busy;
        bit_cnt_next  = bit_cnt_reg;

        case (c_state)
            // ---------------------------------------------------
            IDLE: begin
                miso_next = 1'b0;
                busy_next = 1'b0;
                if (!cs_n) begin
                    tx_shift_next = tx_data;    // 전송할 데이터 로드
                    rx_shift_next = 8'd0;
                    bit_cnt_next  = 4'd0;
                    busy_next     = 1'b1;
                    n_state       = START;
                end
            end
            // ---------------------------------------------------
            // START: 첫 번째 비트를 MISO에 출력 (하강엣지 전 준비)
            START: begin
                miso_next = tx_shift_reg[7];    // MSB 먼저 출력
                if (sclk_pedge) begin
                    // 첫 번째 상승엣지: MOSI 샘플링 후 DATA_RX로
                    rx_shift_next = {rx_shift_reg[6:0], mosi};
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    bit_cnt_next  = 4'd1;
                    n_state       = DATA_TX;
                end
            end
            // ---------------------------------------------------
            // DATA_TX: 하강엣지에서 다음 비트 MISO 출력
            DATA_TX: begin
                if (sclk_nedge) begin
                    miso_next = tx_shift_reg[7];
                    n_state   = DATA_RX;
                end
                // cs_n이 해제되면 강제 종료
                if (cs_n) begin
                    n_state = IDLE;
                end
            end
            // ---------------------------------------------------
            // DATA_RX: 상승엣지에서 MOSI 샘플링
            DATA_RX: begin
                if (sclk_pedge) begin
                    rx_shift_next = {rx_shift_reg[6:0], mosi};
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    bit_cnt_next  = bit_cnt_reg + 4'd1;
                    if (bit_cnt_reg == 4'd7) begin
                        n_state = STOP;
                    end else begin
                        n_state = DATA_TX;
                    end
                end
                if (cs_n) begin
                    n_state = IDLE;
                end
            end
            // ---------------------------------------------------
            STOP: begin
                rx_data_next = rx_shift_reg;
                done_next    = 1'b1;
                busy_next    = 1'b0;
                miso_next    = 1'b0;
                n_state      = IDLE;
            end
            // ---------------------------------------------------
            default: n_state = IDLE;
        endcase
    end

endmodule


// =======================================================
// Edge Detector: SCLK 에지 검출
// =======================================================
module edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output wire pedge,
    output wire nedge
);
    reg ff;

    always @(posedge clk or posedge rst) begin
        if (rst) ff <= 1'b0;
        else     ff <= data_in;
    end

    assign pedge = ~ff &  data_in;  // 0→1
    assign nedge =  ff & ~data_in;  // 1→0
endmodule


// =======================================================
// FND Controller: 14비트 정수를 4자리 FND에 십진수 표시
// =======================================================
module fnd_controller (
    input  wire        clk,
    input  wire        reset,
    input  wire [13:0] fnd_in_data,
    output wire [3:0]  fnd_digit,
    output wire [7:0]  fnd_data
);
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [3:0] w_mux_out;
    wire [1:0] w_digit_sel;
    wire       w_1khz;

    digit_splitter U_DIGIT_SPL (
        .in_data   (fnd_in_data),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .reset (reset),
        .o_1khz(w_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk      (w_1khz),
        .reset    (reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel(w_digit_sel),
        .fnd_digit(fnd_digit)
    );

    mux_4x1 U_MUX_4x1 (
        .sel      (w_digit_sel),
        .digit_1  (w_digit_1),
        .digit_10 (w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out  (w_mux_out)
    );

    bcd U_BCD (
        .bcd     (w_mux_out),
        .fnd_data(fnd_data)
    );
endmodule


// =======================================================
// 클럭 분주: 100MHz → 1kHz (멀티플렉싱용)
// =======================================================
module clk_div (
    input  wire clk,
    input  wire reset,
    output reg  o_1khz
);
    // 100MHz / 100000 = 1kHz  → 카운터 0~99999
    reg [16:0] counter_r;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_r <= 17'd0;
            o_1khz    <= 1'b0;
        end else begin
            if (counter_r == 17'd99999) begin
                counter_r <= 17'd0;
                o_1khz    <= 1'b1;
            end else begin
                counter_r <= counter_r + 17'd1;
                o_1khz    <= 1'b0;
            end
        end
    end
endmodule


// =======================================================
// 2비트 카운터: FND 자릿수 선택 (0~3 순환)
// =======================================================
module counter_4 (
    input  wire       clk,
    input  wire       reset,
    output wire [1:0] digit_sel
);
    reg [1:0] counter_r;
    assign digit_sel = counter_r;

    always @(posedge clk or posedge reset) begin
        if (reset) counter_r <= 2'd0;
        else       counter_r <= counter_r + 2'd1;
    end
endmodule


// =======================================================
// 2→4 디코더: 자릿수 선택 → Anode (Active Low)
// =======================================================
module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @(*) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110; // 1의 자리
            2'b01: fnd_digit = 4'b1101; // 10의 자리
            2'b10: fnd_digit = 4'b1011; // 100의 자리
            2'b11: fnd_digit = 4'b0111; // 1000의 자리
            default: fnd_digit = 4'b1111;
        endcase
    end
endmodule


// =======================================================
// 4:1 MUX: 자릿수 선택에 따라 BCD 값 출력
// =======================================================
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
            default: mux_out = 4'd0;
        endcase
    end
endmodule


// =======================================================
// 자릿수 분리: 14비트 정수 → 각 십진 자릿수 BCD
// =======================================================
module digit_splitter (
    input  wire [13:0] in_data,
    output wire [3:0]  digit_1,
    output wire [3:0]  digit_10,
    output wire [3:0]  digit_100,
    output wire [3:0]  digit_1000
);
    assign digit_1    =  in_data % 10;
    assign digit_10   = (in_data / 10)   % 10;
    assign digit_100  = (in_data / 100)  % 10;
    assign digit_1000 = (in_data / 1000) % 10;
endmodule


// =======================================================
// BCD → 7-Segment Cathode (Active Low, Common Anode)
// =======================================================
module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);
    // 비트 순서: dp g f e d c b a
    always @(*) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0; // 0: a b c d e f 켜짐
            4'd1: fnd_data = 8'hF9; // 1
            4'd2: fnd_data = 8'hA4; // 2
            4'd3: fnd_data = 8'hB0; // 3
            4'd4: fnd_data = 8'h99; // 4
            4'd5: fnd_data = 8'h92; // 5
            4'd6: fnd_data = 8'h82; // 6
            4'd7: fnd_data = 8'hF8; // 7
            4'd8: fnd_data = 8'h80; // 8
            4'd9: fnd_data = 8'h90; // 9
            default: fnd_data = 8'hFF; // 소등
        endcase
    end
endmodule
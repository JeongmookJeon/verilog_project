`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input rst,
    input sel_dht11,
    input sel_distance,
    input sel_display,
    input [23:0] fnd_in_data,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    // --- Wire 선언 ---
    wire [3:0] w_digit_msec_1, w_digit_msec_10;
    wire [3:0] w_digit_sec_1, w_digit_sec_10;
    wire [3:0] w_digit_min_1, w_digit_min_10;
    wire [3:0] w_digit_hour_1, w_digit_hour_10;

    wire [3:0] w_digit_val_int_1, w_digit_val_int_10;
    wire [3:0] w_digit_val_dec_1, w_digit_val_dec_10;

    // [추가] 거리용 자릿수 Wire
    wire [3:0] w_digit_dist_1, w_digit_dist_10, w_digit_dist_100;

    wire [3:0] w_mux_hour_min_out;
    wire [3:0] w_mux_sec_msec_out;
    wire [3:0] w_mux_dist_out;  // [추가] 거리용 MUX 출력
    wire [3:0] w_mux_dht11_out;

    wire [3:0] w_final_mux_out; // [수정] 최종 MUX 출력 (3가지 중 선택)
    wire [2:0] w_digit_sel;
    wire w_1khz;
    wire w_dot_onoff;

    assign w_final_mux_out = (sel_dht11)    ? w_mux_dht11_out : 
                             (sel_distance) ? w_mux_dist_out : 
                             (sel_display)  ? w_mux_hour_min_out : w_mux_sec_msec_out;

    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_VAL_INT_SP (
        .in_data  (fnd_in_data[15:8]),
        .digit_1  (w_digit_val_int_1),
        .digit_10 (w_digit_val_int_10),
        .digit_100()
    );

    // [추가] 온습도 소수 부분 (fnd_in_data[7:0])
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_VAL_DEC_SP (
        .in_data  (fnd_in_data[7:0]),
        .digit_1  (w_digit_val_dec_1),
        .digit_10 (w_digit_val_dec_10),
        .digit_100()
    );


    // Hour (시)
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_SP (
        .in_data(fnd_in_data[23:19]),
        .digit_1(w_digit_hour_1),
        .digit_10(w_digit_hour_10),
        .digit_100()  // 안 씀
    );

    // Min (분)
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_SP (
        .in_data  (fnd_in_data[18:13]),
        .digit_1  (w_digit_min_1),
        .digit_10 (w_digit_min_10),
        .digit_100()
    );

    // Sec (초)
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_SP (
        .in_data  (fnd_in_data[12:7]),
        .digit_1  (w_digit_sec_1),
        .digit_10 (w_digit_sec_10),
        .digit_100()
    );

    // Msec (밀리초)
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSECD_SP (
        .in_data  (fnd_in_data[6:0]),
        .digit_1  (w_digit_msec_1),
        .digit_10 (w_digit_msec_10),
        .digit_100()
    );

    // [추가] Distance (거리) - 16비트 전체 사용
    // 거리값은 0~400 정도이므로 100의 자리까지 필요함
    digit_splitter #(
        .BIT_WIDTH(16)
    ) U_DIST_SP (
        .in_data  (fnd_in_data[15:0]),
        .digit_1  (w_digit_dist_1),
        .digit_10 (w_digit_dist_10),
        .digit_100(w_digit_dist_100)
    );

    // Dot 깜빡임 제어
    dot_onoff_comp U_DOT_COMP (
        .msec(fnd_in_data[6:0]),
        .dot_onoff(w_dot_onoff)
    );


 // (A) 시:분 모드용 MUX
    mux_8x1 U_Mux_HOUR_MIN (
        .sel(w_digit_sel),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .digit_dot_1(4'd10),           // 10 = 빈칸(Blank)
        .digit_dot_10(4'd10),
        .digit_dot_100(w_dot_onoff ? 4'd15 : 4'd10), //  1이면 15(점), 0이면 10(빈칸)
        .digit_dot_1000(4'd10),
        .mux_out(w_mux_hour_min_out)
    );

    // (B) 초:밀리초 모드용 MUX
    mux_8x1 U_Mux_SEC_MSEC (
        .sel(w_digit_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .digit_dot_1(4'd10),
        .digit_dot_10(4'd10),
        .digit_dot_100(w_dot_onoff ? 4'd15 : 4'd10), // 수정 완료
        .digit_dot_1000(4'd10),
        .mux_out(w_mux_sec_msec_out)
    );

    // (C) 거리 모드용 MUX
    mux_8x1 U_Mux_DIST (
        .sel(w_digit_sel),
        .digit_1(w_digit_dist_1),       
        .digit_10(w_digit_dist_10),
        .digit_100(w_digit_dist_100),
        .digit_1000(4'd14),             // 'd' 출력
        .digit_dot_1(4'd10),            // 거리 모드에서는 점을 모두 끔
        .digit_dot_10(4'd10),
        .digit_dot_100(4'd10),
        .digit_dot_1000(4'd10),
        .mux_out(w_mux_dist_out)
    );

    // (D) 온습도 모드용 MUX
    mux_8x1 U_Mux_DHT11 (
        .sel(w_digit_sel),
        .digit_1(w_digit_val_dec_1),    
        .digit_10(w_digit_val_dec_10),  
        .digit_100(w_digit_val_int_1),  
        .digit_1000(w_digit_val_int_10),
        .digit_dot_1(4'd10),
        .digit_dot_10(4'd10),
        .digit_dot_100(4'd15),          // 온습도는 정수/소수 사이 점 항상 켜기
        .digit_dot_1000(4'd10),
        .mux_out(w_mux_dht11_out)
    );


    clk_div U_CLK_DIV (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel(w_digit_sel[1:0]),
        .fnd_digit(fnd_digit)
    );

    // [수정된 BCD] 'd' 문자 처리가 포함됨
    bcd U_BCD (
        .bcd(w_final_mux_out),
        .fnd_data(fnd_data)
    );

endmodule


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100 // [추가] 거리(100의 자리) 위해 포트 추가
);
    assign digit_1 = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;
    assign digit_100 = (in_data / 100) % 10; // 시간일 땐 0이 나오므로 상관없음
endmodule


module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hc0;
            4'd1: fnd_data = 8'hf9;
            4'd2: fnd_data = 8'ha4;
            4'd3: fnd_data = 8'hb0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hf8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            4'd10: fnd_data = 8'hff;  // Blank
            4'd11: fnd_data = 8'hff;  // 
            4'd12: fnd_data = 8'hff;  // 
            4'd13: fnd_data = 8'hff;  // 
            4'd14: fnd_data = 8'hA1;  // [추가] d (Distance) - 모양: 5E (d)
            4'd15: fnd_data = 8'h7f;  // . (dot)
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule


// --- 기존 서브 모듈들 (그대로 유지) ---

module dot_onoff_comp (
    input [6:0] msec,
    output dot_onoff
);
    assign dot_onoff = (msec < 50);
endmodule

module clk_div (
    input clk,
    input rst,
    output reg o_1khz
);
    reg [$clog2(100_000)-1:0] counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99_999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule

module counter_8 (
    input clk,
    input rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_r;
    assign digit_sel = counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
        end else begin
            counter_r <= counter_r + 1;
        end
    end
endmodule

module decoder_2x4 (
    input [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @(*) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
        endcase
    end
endmodule

module mux_8x1 (
    input [2:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_dot_1,
    input [3:0] digit_dot_10,
    input [3:0] digit_dot_100,
    input [3:0] digit_dot_1000,
    output reg [3:0] mux_out
);
    always @(*) begin
        case (sel)
            3'b000: mux_out = digit_1;
            3'b001: mux_out = digit_10;
            3'b010: mux_out = digit_100;
            3'b011: mux_out = digit_1000;
            3'b100: mux_out = digit_dot_1;
            3'b101: mux_out = digit_dot_10;
            3'b110: mux_out = digit_dot_100;
            3'b111: mux_out = digit_dot_1000;
        endcase
    end
endmodule

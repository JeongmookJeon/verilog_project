`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input rst,
    input sel_display,  // 입력값
    input [23:0] fnd_in_data,  // 어디??? 입력값
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);
    wire [3:0] w_digit_msec_1, w_digit_msec_10;
    wire [3:0] w_digit_sec_1, w_digit_sec_10;
    wire [3:0] w_digit_min_1, w_digit_min_10;
    wire [3:0] w_digit_hour_1, w_digit_hour_10;
    wire [3:0] w_mux_hour_min_out, w_mux_sec_msec_out;
    wire [3:0] w_mux_2x1_out;
    wire [2:0] w_digit_sel;
    wire w_1khz;
    wire w_dot_onoff;

    //hour
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_SP (
        .in_data (fnd_in_data[23:19]),
        .digit_1 (w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );

    //min
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_SP (
        .in_data (fnd_in_data[18:13]),
        .digit_1 (w_digit_min_1),
        .digit_10(w_digit_min_10)
    );

    //sec
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_SP (
        .in_data (fnd_in_data[12:7]),
        .digit_1 (w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );


    //msec
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSECD_SP (
        .in_data (fnd_in_data[6:0]),
        .digit_1 (w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );

    dot_onoff_comp U_DOT_COMP (
        .msec(fnd_in_data[6:0]),
        .dot_onoff(w_dot_onoff)
    );


    mux_8x1 U_Mux_HOUR_MIN (
        .sel(w_digit_sel),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100({3'b111, w_dot_onoff}),
        .digit_dot_1000((4'hf)),
        .mux_out(w_mux_hour_min_out)

    );

    mux_8x1 U_Mux_SEC_MSEC (
        .sel(w_digit_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .digit_dot_1(4'hf),
        .digit_dot_10(4'hf),
        .digit_dot_100({3'b111, w_dot_onoff}),  // 1110 or 1111 켜고 끄고
        .digit_dot_1000((4'hf)),
        .mux_out(w_mux_sec_msec_out)
    );

    mux_2x1 U_MUX_2x1 (
        .sel(sel_display),
        .i_sel0(w_mux_sec_msec_out),
        .i_sel1(w_mux_hour_min_out),
        .o_mux(w_mux_2x1_out)
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


    bcd U_BCD (
        .bcd(w_mux_2x1_out),  // 8bit 중 하위 4bit만 사용.
        .fnd_data(fnd_data)
    );

    clk_div U_CLK_DIV (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );
endmodule

module dot_onoff_comp (  // 50msec 지날때 마다 깜빡임
    input [6:0] msec,
    output dot_onoff
);
    assign dot_onoff = (msec <= 50);

endmodule

module mux_2x1 (  //시,분과 초,밀리초 를 나눔.
    input        sel,
    input  [3:0] i_sel0,
    input  [3:0] i_sel1,
    output [3:0] o_mux
);
    assign o_mux = (sel) ? i_sel1 : i_sel0;
endmodule

module clk_div ( // clk을 1khz틱으로 만들어서 틱신호를 내보냄 1ms틱
    input clk,
    input rst,
    output reg o_1khz
);
    parameter CLK_DIV = 1000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 1'b0;
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == (F_COUNT) - 1) begin
                counter_r <= 1'b0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule

module counter_8 ( //fnd에 7개 bar를 띄어야하는데 counter_r에 저장하여 출력한다. 왜?
    //fnd는 한자리씩 아주 빠르게 번갈아 켜는데 한자리를 킨것을 기억해야 다음자리를 켤 수 있으니까.
    input clk,
    input rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_r;
    assign digit_sel = counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 3'b0;
        end else begin
            if (counter_r == 7) begin
                counter_r <= 3'b0;
            end else begin
                counter_r <= counter_r + 1;
            end
        end
    end
endmodule

module decoder_2x4 (  // 화면을 어떤것을 켤건지 알려주는 모듈
    input [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @(*) begin
        case (digit_sel)
            2'b00:   fnd_digit = 4'b1110;
            2'b01:   fnd_digit = 4'b1101;
            2'b10:   fnd_digit = 4'b1011;
            2'b11:   fnd_digit = 4'b0111;
            default: fnd_digit = 4'b1111;
        endcase
    end
endmodule

module mux_8x1 (
    input [2:0] sel,  // 자릿수 고르기
    input [3:0] digit_1, // 왜 4비트?
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_dot_1,
    input [3:0] digit_dot_10,
    input [3:0] digit_dot_100,
    input [3:0] digit_dot_1000,
    output reg [3:0] mux_out // 매우빠른속도로 mux를 통해서 데이터가 나간다.
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

module digit_splitter #( // 한개 화면에 1자리 수만!!(ex, 12면 1 2따로)
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);
    assign digit_1  = in_data % 10;  // 1의자리만.
    assign digit_10 = (in_data / 10) % 10;  // 10의자리만

endmodule

module bcd (
    input [3:0] bcd,  // sum의 값을 입력으로한다.
    output reg[7:0] fnd_data //8비트 출력으로 hex(1 1 0 0 _ 0 0 0 0 = 0)값으로 출력
);
    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hc0;  // 4'd0의 값으로 1 1 0 0 _ 0 0 0 0 = 0
            4'd1: fnd_data = 8'hf9;  // 1 1 1 1 _ 1 0 0 1 = 1
            4'd2: fnd_data = 8'ha4;
            4'd3: fnd_data = 8'hb0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hf8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            4'd10: fnd_data = 8'hff;  // 깜빡깜빡 1111_1111
            4'd11: fnd_data = 8'hff;
            4'd12: fnd_data = 8'hff;
            4'd13: fnd_data = 8'hff;
            4'd14: fnd_data = 8'h7f;  // dot 깜빡깜빡
            4'd15: fnd_data = 8'hff;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule

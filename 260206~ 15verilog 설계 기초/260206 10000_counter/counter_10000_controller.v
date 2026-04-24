`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input [13:0] fnd_in_data,
    output [3:0] fnd_digit,
    output [7:0] fnd_data   // 여기서 fnd_data는 연결만하고 값을 저장하지 않는다. wire.
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

    mux_4x1 U_Mux_4x1 (
        .sel(w_digit_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out(w_mux_4x1_out)
    );

    bcd U_BCD (
        .bcd(w_mux_4x1_out),  // 8bit 중 하위 4bit만 사용.
        .fnd_data(fnd_data)
    );

endmodule

module clk_div (
    input clk,
    input reset,
    output reg o_1khz
);
    reg [$clog2(100_000):0] counter_r;  //counter 모듈의 counter_r과 다른거다. 모듈이 다르니까.

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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


module counter_4 (
    input clk,
    input reset,
    output [1:0] digit_sel
);
    reg [1:0] counter_r;

    assign digit_sel = counter_r;   // reg 뒤에 assign이 오는게 좋다. 안그러면 문법오류 생길 수 있음.

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin       // reset == 1 말고 reset이라고만 써도 같은 동작 함.
            // init counter_r
            counter_r <= 0;  // reset이 1이면 0으로 초기화 해라.
        end else begin
            // to do
            counter_r <= counter_r + 1;
        end
    end

endmodule


module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @digit_sel begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
        endcase
    end
endmodule


module mux_4x1 (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] mux_out
);

    always @(*) begin   // * : 모든 입력을 감시, 단점: 상관 없는거 넣는 경우가 있다.
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
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);

    assign digit_1    = in_data % 10;
    assign digit_10   = (in_data / 10) % 10;
    assign digit_100  = (in_data / 100) % 10;
    assign digit_1000 = (in_data / 1000) % 10;

endmodule

module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data   // always 블록 안에서 값을 대입받는 신호는 reg 타입이어야 함.
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
            default:
            fnd_data = 8'hFF;  // 나머지 경우는 default를 실행.
        endcase
    end

endmodule

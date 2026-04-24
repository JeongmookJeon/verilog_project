`timescale 1ns / 1ps

module adder_1_10 (
    input clk,
    input rst,
    output [7:0] out
);
    logic srcsel, aload, outsel, alt10, sload;
    control_unit U_CONTROL_UNIT (
        .clk   (clk),
        .rst   (rst),
        .alt10 (alt10),
        .srcsel(srcsel),  //logic
        .aload (aload),
        .sload (sload),
        .outsel(outsel)
    );

    datapath U_DATAPATH (
        .clk   (clk),
        .rst   (rst),
        .srcsel(srcsel),
        .aload (aload),
        .sload (sload),
        .outsel(outsel),
        .alt10 (alt10),
        .out   (out)
    );

endmodule

module control_unit (
    input clk,
    input rst,
    input alt10,
    output logic srcsel,  //logic
    output logic aload,
    output logic sload,
    output logic outsel
);
    typedef enum logic [2:0] {
        s0,
        s1,
        s2,
        s3,
        s4
    } state_t;

    state_t c_state, n_state;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= s0;
        end else begin
            c_state <= n_state;
        end
    end
    always_comb begin
        n_state = c_state;
        srcsel  = 0;
        aload   = 0;
        outsel  = 0;
        case (c_state)
            s0: begin  // cpu가 처음 켜졌을 때.
                srcsel  = 0;
                aload   = 1;
                sload   = 0;
                outsel  = 0;
                n_state = s1;
            end
            s1: begin  //condition check(10보다 작은지 check)
                srcsel = 0;
                aload  = 0;
                sload  = 0;
                outsel = 0;  // 결과출력 x
                if (alt10) begin
                    n_state = s2;
                end else begin
                    n_state = s3;
                end
            end
            s2: begin  // 중간확인
                srcsel  = 1;
                aload   = 1;
                sload   = 1;
                outsel  = 0;  // areg값 외부 출력
                n_state = s1;

            end
            s3: begin  //업데이트 +1
                srcsel = 0;
                aload  = 0;
                sload  = 0;
                outsel = 1;
            end


        endcase
    end
endmodule


module datapath (
    input        clk,
    input        rst,
    input        srcsel,
    input        aload,
    input        sload,
    input        outsel,
    output       alt10,
    output [7:0] out
);
    logic [7:0] w_aluout, w_muxout, w_aregout, w_sregout, w_s_alu_regout;
    assign out = (outsel) ? w_sregout : 8'hz; // outsel이 1이면 areg에 저장된거 출력

    alt10_comp U_ALT10_COMP (  // 10 비교기
        .in_data(w_aregout),
        .alt10  (alt10)
    );
    mux2x1 U_MUX2X1 (  // 1이면  alu출력, 0이면 a(0)출력
        .a(0),
        .b(w_aluout),
        .srcsel(srcsel),
        .mux_out(w_muxout)
    );
    areg U_AREG (  // load가 1일때만 저장
        .clk(clk),
        .rst(rst),
        .aload(aload),
        .reg_in(w_muxout),
        .reg_out(w_aregout)
    );
    sreg U_SREG (
        .clk(clk),
        .rst(rst),
        .sload(sload),
        .reg_in(w_s_alu_regout),
        .reg_out(w_sregout)
    );
    alu U_ALU (  // a+b 모듈
        .a(w_aregout),
        .b(1),
        .alu_out(w_aluout)
    );
    alu U_S_ALU (  // a+b 모듈
        .a(w_sregout),
        .b(w_aluout),
        .alu_out(w_s_alu_regout)
    );
endmodule

module alt10_comp (  // 10 비교기
    input  [7:0] in_data,
    output       alt10
);
    assign alt10 = (in_data < 10);
endmodule

module mux2x1 (  // 1이면  alu출력, 0이면 a(0)출력
    input        srcsel,
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] mux_out
);
    assign mux_out = (srcsel) ? b : a;
endmodule

module areg (  // load가 1일때만 저장
    input        clk,
    input        rst,
    input        aload,
    input  [7:0] reg_in,
    output [7:0] reg_out
);
    logic [7:0] areg;
    assign reg_out = areg;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            areg <= 0;
        end else begin
            if (aload) begin
                areg <= reg_in;
            end
        end
    end
endmodule

module sreg (
    input        clk,
    input        rst,
    input        sload,
    input  [7:0] reg_in,
    output [7:0] reg_out
);
    logic [7:0] sreg;
    assign reg_out = sreg;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sreg <= 0;
        end else begin
            if (sload) begin
                sreg <= reg_in;
            end
        end
    end

endmodule

module alu (  // a+b 모듈
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

`timescale 1ns / 1ps

module dedicated_cpu0 (
    input clk,
    input rst,
    output [7:0] out
);
    logic asrcsel, aload, outsel, alt10;
    control_unit U_CONTROL_UNIT (.*);
    datapath U_DATAPATH (.*);
endmodule

module control_unit (
    input clk,
    input rst,
    input alt10,
    output logic asrcsel,  //logic
    output logic aload,
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
        asrcsel = 0;
        aload   = 0;
        outsel  = 0;
        case (c_state)
            s0: begin  // cpu가 처음 켜졌을 때.
                asrcsel = 0;  // 초기화 a를 선택
                aload   = 1;  // areg 값을 저장
                outsel  = 0;  // 결과 출력 x
                n_state = s1;
            end
            s1: begin  //condition check(10보다 작은지 check)
                asrcsel = 0;  //출력만 할 뿐 값을 더하거나 
                aload   = 0;  // 새로 저장하지 않는다.
                outsel  = 0;  // 결과출력 x
                if (alt10) begin
                    n_state = s2;
                end else begin
                    n_state = s4;
                end
            end
            s2: begin  // 중간확인
                asrcsel = 0;  //출력만하고 값을 더하지 않음.
                aload   = 0;  //값을 저장하지도 않음.
                outsel  = 1;  // areg값 외부 출력
                n_state = s3;

            end
            s3: begin  //업데이트 +1
                asrcsel = 1;  //alu가 계산한 값 내보내기
                aload   = 1;  // +1된값 저장.
                outsel  = 0;  //값을 바꾸는 중, 출력 안함.
                n_state = s1;  //condition check(10보다 작은지)
            end
            s4: begin  // 종료 및 대기
                asrcsel = 0;
                aload   = 0;
                outsel  = 1;  // 최종값 10 보여주기

            end

        endcase
    end


endmodule


module datapath (
    input        clk,
    input        rst,
    input        asrcsel,
    input        aload,
    input        outsel,
    output       alt10,
    output [7:0] out
);
    logic [7:0] w_aluout, w_muxout, w_regout;
    assign out = (outsel) ? w_regout : 8'hz; // outsel이 1이면 areg에 저장된거 출력

    alt10_comp U_ALT10_COMP (  // 10 비교기
        .in_data(w_regout),
        .alt10  (alt10)
    );

    mux2x1 U_MUX2X1 (  // 1이면  alu출력, 0이면 a(0)출력
        .a(0),
        .b(w_aluout),
        .asrcsel(asrcsel),
        .mux_out(w_muxout)
    );
    areg U_AREG (  // load가 1일때만 저장
        .clk(clk),
        .rst(rst),
        .aload(aload),
        .reg_in(w_muxout),
        .reg_out(w_regout)
    );
    alu U_ALU (  // a+b 모듈
        .a(w_regout),
        .b(1),
        .alu_out(w_aluout)
    );
endmodule

module alt10_comp (  // 10 비교기
    input  [7:0] in_data,
    output       alt10
);
    assign alt10 = (in_data < 10);

endmodule

module mux2x1 (  // 1이면  alu출력, 0이면 a(0)출력
    input        asrcsel,
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] mux_out
);
    assign mux_out = (asrcsel) ? b : a;
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

module alu (  // a+b 모듈
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

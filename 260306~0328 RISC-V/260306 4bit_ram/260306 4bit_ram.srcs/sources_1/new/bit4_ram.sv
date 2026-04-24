`timescale 1ns / 1ps


module bit4_ram (
    input logic clk,
    input logic rst,
    output logic [7:0] out
);
    // Control Unit과 Datapath를 연결할 제어 신호들
    logic rf_srcsel, we, lq10;
    logic [1:0] raddr0, raddr1, waddr;

    control_unit U_CU (.*);
    datapath U_DP (.*);
endmodule



module control_unit (
    input logic clk,
    input logic rst,
    input logic lq10,  // Datapath에서 올라오는 i <= 10 비교 결과
    output logic rf_srcsel,     // 0이면 상수 '1' 선택, 1이면 ALU 결과 선택
    output logic [1:0] raddr0,  // 읽기 주소 0
    output logic [1:0] raddr1,  // 읽기 주소 1
    output logic [1:0] waddr,  // 쓰기 주소
    output logic we  // Write Enable (레지스터 파일 쓰기 허용)
);
    typedef enum logic [2:0] {
        s0,
        s1,
        s2,
        s3,
        s4,
        s5,
        s6
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
        n_state   = c_state;
        rf_srcsel = 0;
        raddr0    = 2'b00;
        raddr1    = 2'b00;
        waddr     = 2'b00;
        we        = 0;
        case (c_state)
            s0: begin  // LD R3 = 1
                rf_srcsel = 0;
                raddr0    = 0;
                raddr1    = 0;
                waddr     = 3;
                we        = 1;
                n_state   = s1;
            end
            s1: begin  // R1 = R0 + R0 (i = 0 초기화)
                rf_srcsel = 1;
                raddr0    = 0;
                raddr1    = 0;
                waddr     = 1;
                we        = 1;
                n_state   = s2;
            end
            s2: begin  // R2 = R0 + R0 (sum = 0 초기화)
                rf_srcsel = 1;
                raddr0 = 0;
                raddr1 = 0;
                waddr = 2;
                we = 1;
                n_state = s3;
            end
            s3: begin  // 조건 검사 (Lq10 == 1)
                rf_srcsel = 0;
                raddr0 = 1;
                raddr1 = 0;
                waddr = 0;
                we = 0;
                if (lq10 == 1) n_state = s4;
                else n_state = s6;
            end
            s4: begin  // R2 = R1 + R2 (sum = sum + i)
                rf_srcsel = 1;
                raddr0 = 1;
                raddr1 = 2;
                waddr = 2;
                we = 1;
                n_state = s5;
            end
            s5: begin  // R1 = R1 + R3 (i = i + 1)
                rf_srcsel = 1;
                raddr0 = 1;
                raddr1 = 3;
                waddr = 1;
                we = 1;
                n_state = s3;  // S3로 돌아가서 루프 반복
            end
            s6: begin  // Halt & 출력
                rf_srcsel = 0;
                raddr0 = 2;
                raddr1 = 0;
                waddr = 0;
                we = 0;
                n_state = s6;  // 무한 대기
            end
        endcase
    end
endmodule

module datapath (
    input        clk,
    input        rst,
    input        we,
    input  [1:0] raddr0,
    input  [1:0] raddr1,
    input  [1:0] waddr,
    input        rf_srcsel,
    output       lq10,
    output [7:0] out
);
    logic [7:0] rdata0_out, rdata1_out, rf_srcsel_out, alu_out;


    register_file U_REG_FILE (  //register file 단순 저장공간
        .clk(clk),
        .rst(rst),
        .we(we),
        .raddr0(raddr0),
        .raddr1(raddr1),
        .waddr(waddr),
        .wdata(rf_srcsel_out),
        .rdata0(rdata0_out),
        .rdata1(rdata1_out)
    );


    mux2x1 U_MUX2X1 (
        .a  (1),
        .b  (alu_out),
        .sel(rf_srcsel),
        .out(rf_srcsel_out)
    );



    ilq10 U_ILQ10 (
        .in_data(rdata0_out),
        .ilq10  (lq10)
    );



    alu U_ALU (  //a+b 가산기
        .a(rdata0_out),
        .b(rdata1_out),
        .alu_out(alu_out)
    );
    assign out = rdata0_out;

endmodule


module register_file (  //register file 단순 저장공간
    input              clk,
    input              rst,
    input              we,
    input        [1:0] raddr0,
    input        [1:0] raddr1,
    input        [1:0] waddr,
    input        [7:0] wdata,
    output logic [7:0] rdata0,
    output logic [7:0] rdata1
);
    logic [7:0] rf[0:3];  // 8bit reg r0~3
    //assign rdata0 = (raddr0 == 2'd0) ? 0 : rf[raddr0]; // rf에 있는 raddr0를 rdata0로 밖으로 꺼내겠다
    //assign rdata1 = (raddr1 == 2'd0) ? 0 : rf[raddr1];
    assign rdata0 = rf[raddr0];
    assign rdata1 = rf[raddr1];
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 4; i++)
            rf[i] <= 8'd0;  // registerfile 초기화
        end else begin
            if (we) begin
                if (waddr != 0) begin
                    rf[waddr] <= wdata;
                end
            end
        end
    end
endmodule


module mux2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] out
);
    assign out = (sel) ? b : a;
endmodule

module ilq10 (
    input  [7:0] in_data,
    output       ilq10
);
    assign ilq10 = (in_data <= 10) ? 1 : 0;
endmodule

module alu (  //a+b 가산기
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

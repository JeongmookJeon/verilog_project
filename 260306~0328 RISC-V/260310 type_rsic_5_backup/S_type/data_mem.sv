`timescale 1ns / 1ps
`include "define.vh"

module data_mem (  // dwdata를 dmem의 dwaddr에 넣어준다
    input         clk,
    input         rst,
    input         dwe,
    input [2:0] funct3,
    input  [31:0] dwaddr,
    input  [31:0] dwdata,
    output [31:0] drdata
);
    logic [31:0] dmem[0:31];
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (funct3)
                3'b000:
                dmem[dwaddr][7:0]  <= dwdata[7:0];   // sb: 하위 8비트만 수정
                3'b001:
                dmem[dwaddr][15:0] <= dwdata[15:0];  // sh: 하위 16비트만 수정
                3'b010: dmem[dwaddr] <= dwdata;  // sw: 32비트 전체 수정
                default: dmem[dwaddr] <= dwdata;
            endcase
        end
    end
    assign drdata = dmem[dwaddr[31:2]];
endmodule
// byte address
/* 
    logic [7:0] dmem[0:31];
    always_ff @(posedge clk) begin

        if (dwe) begin
            dmem[dwaddr]   <= dwdata[7:0];
            dmem[dwaddr+1] <= dwdata[15:8];
            dmem[dwaddr+2] <= dwdata[23:16];
            dmem[dwaddr+3] <= dwdata[31:24];
        end
    end
    assign drdata = {
        dmeme[dwaddr], dmeme[dwaddr+1], dmeme[dwaddr+2], dmeme[dwaddr+3]
    };
*/
//word address

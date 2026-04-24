`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input         clk,
    input         rst,
    input         dwe,
    input  [ 2:0] i_funct3,
    input  [31:0] daddr,
    input  [31:0] dwdata, 
    output [31:0] drdata
);
    logic [31:0] dmem[0:31];

    initial begin  // 초기값 세팅
        for (int i = 0; i < 32; i++) begin
            dmem[i] = 32'h00000000;
        end
    end
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b000:  dmem[daddr[31:2]][7:0] <= dwdata[7:0];  // sb
                3'b001:  dmem[daddr[31:2]][15:0] <= dwdata[15:0];  // sh
                3'b010:  dmem[daddr[31:2]] <= dwdata;  // sw
                default: dmem[daddr[31:2]] <= dwdata;
            endcase
        end
    end
    assign drdata = dmem[daddr[31:2]];
endmodule

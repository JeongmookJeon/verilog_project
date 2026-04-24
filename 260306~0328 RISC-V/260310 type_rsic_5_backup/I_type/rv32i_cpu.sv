`timescale 1ns / 1ps
`include "define.vh"
module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    output [31:0] instr_addr,
    output [ 2:0] o_funct3,
    output        dwe,
    output [31:0] daddr,
    output [31:0] dwdata


);

    logic rf_we, alu_src, rfwd_src;
    logic [3:0] alu_control;
    control_unit U_CONTROL_UNIT (
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .alu_src(alu_src),
        .alu_control(alu_control),
        .rfwd_src(rfwd_src),
        .o_funct3(o_funct3),
        .dwe(dwe)
    );

    rv32i_datapath U_DATAPATH (.*);
endmodule
module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       alu_src,
    output logic       rfwd_src,
    output logic [3:0] alu_control,
    output logic [2:0] o_funct3,
    output logic       dwe
);
    always_comb begin
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 1'b0;
        o_funct3    = 3'b000;
        dwe         = 1'b0;
        case (opcode)
            `R_TYPE: begin // R-type to write register file, alu_control == funct7[5], funct3
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = {funct7[5], funct3};  // 6번째 bit만 비교
                rfwd_src    = 1'b0;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 1'b0;
                o_funct3    = funct3;
                dwe         = 1'b1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 1'b0;
                o_funct3    = funct3;
                dwe         = 1'b1;
            end
            `I_TYPE: begin
                rf_we   = 1'b1;
                alu_src = 1'b1;
                if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rfwd_src = 1'b0;
                o_funct3 = funct3;
                dwe      = 1'b0;
            end
        endcase

    end
endmodule

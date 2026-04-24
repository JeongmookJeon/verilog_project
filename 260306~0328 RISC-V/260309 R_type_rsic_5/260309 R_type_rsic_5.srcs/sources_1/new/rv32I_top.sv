`timescale 1ns / 1ps
`include "define.vh"

module rv32I_top (
    input clk,
    input rst
);

    logic [31:0] instr_addr, instr_data;

    instruction_mem U_INSTRUTION_MEM (.*);
    rv32i_cpu U_RV32I (.*);

endmodule
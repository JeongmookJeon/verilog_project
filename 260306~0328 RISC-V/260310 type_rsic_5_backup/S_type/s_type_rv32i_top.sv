`timescale 1ns / 1ps
`include "define.vh"

module rv32I_top (
    input clk,
    input rst
);
    logic        dwe;
    logic [31:0] instr_addr, instr_data, dwaddr, dwdata, drdata;
    logic  [2:0] funct3;

    // 명령어(instr_data)에서 funct3 자리(14~12번 비트)를 떼어내서 연결해줍니다!
    assign funct3 = instr_data[14:12]; 

    // (.*) 덕분에 위에서 만든 funct3가 data_mem으로 쏙 들어갑니다.
    instruction_mem U_INSTRUTION_MEM (.*);
    rv32i_cpu       U_RV32I          (.*);
    data_mem        U_DATA_MEM       (.*);

endmodule
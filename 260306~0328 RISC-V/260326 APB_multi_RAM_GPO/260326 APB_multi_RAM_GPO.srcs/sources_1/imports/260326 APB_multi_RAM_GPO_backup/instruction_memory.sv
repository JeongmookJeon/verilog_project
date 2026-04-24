`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:1024];

    initial begin
       // $readmemh("risc_v_rv32i_rom.mem", rom);
       // $readmemh("U_APB_BRAM.mem", rom);
     $readmemh("APB_GPO.mem", rom);
    end

    assign instr_data = rom[instr_addr[31:2]];

endmodule

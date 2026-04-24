`timescale 1ns / 1ps

module instruction_memory (

    input  [31:0] instr_addr,
    output [31:0] instr_data

);


    logic [31:0] rom[0:31];


    initial begin

        rom[0] = 32'h004182b3;  // ADD x5.x3.x4
        rom[1] = 32'h00812123;  // SW x2 2(x8), SW x2,x8,2
        rom[2] = 32'h00212383;  // LW x7, x2, 2
        rom[3] = 32'h00438413;  // ADDI x8, x7, 4
        rom[4] = 32'h00840463;  // BEQ x8, x8 , 8
        rom[5] = 32'h004182b3;  // ADD x7, x8 , 8
        rom[6] = 32'h00812123;  // SW x2 2(x8), SW x2,x8,2

        // rom[0] = 32'h403202b3;  // SUB x5.x3.x4
        //rom[0] = 32'h004192b3;  // SLL x5.x3.x4
        //rom[0] = 32'h0041a2b3;  // SLT x5.x3.x4
        //rom[0] = 32'h0041b2b3;  // SLTU x5.x3.x4
        //rom[0] = 32'h0041c2b3;  // XOR x5.x3.x4
        //rom[0] = 32'h0041d2b3;  // SRL x5.x3.x4
        //rom[0] = 32'h4041d2b3;  // SRA x5.x3.x4
        //rom[0] = 32'h0041e2b3;  // OR x5.x3.x4
        //rom[0] = 32'h0041f2b3;  // AND x5.x3.x4


        // rom[2] = 32'h0041a2b3;  // SLT x5, x3, x4  -> x5는 1이 나와야 함
        // rom[3] = 32'h0041b2b3;  // SLTU x5, x3, x4 -> x5는 0이 나와야 함


        //rom[6] = 32'h0041d2b3; // SRL x5, x3, x4 -> x5는 32'h4000_0000
        //rom[7] = 32'h4041d2b3; // SRA x5, x3, x4 -> x5는 32'hC000_0000

    end


    assign instr_data = rom[instr_addr[31:2]];


endmodule

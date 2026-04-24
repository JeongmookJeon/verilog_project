`timescale 1ns / 1ps
`include "define.vh"

module instruction_mem ( //주소를 넣으면 해당 주소의  data가 나온다.
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_data
);
    logic [31:0] rom[0:31];

    initial begin
        // 초기화: 모든 rom 공간을 0으로 설정
        for (int i = 0; i < 32; i++) rom[i] = 32'h00000000;

        // --- [IL-타입: Load 계열 (노란색)] ---
        // 1. LB (Load Byte): x3 = M[x1 + 0] (8-bit sign-extended) [cite: 111, 289]
        rom[0]  = 32'h00008183;

        // 2. LH (Load Halfword): x4 = M[x1 + 2] (16-bit sign-extended) [cite: 111, 287]
        rom[1]  = 32'h00209203;

        // 3. LW (Load Word): x5 = M[x1 + 4] (32-bit) [cite: 111, 286]
        rom[2]  = 32'h0040A283;

        // 4. LBU (Load Byte Unsigned): x6 = M[x1 + 1] (8-bit zero-extended) [cite: 111, 288]
        rom[3]  = 32'h0010C303;

        // 5. LHU (Load Half Unsigned): x7 = M[x1 + 2] (16-bit zero-extended) [cite: 111, 288]
        rom[4]  = 32'h0020D383;

        // --- [I-타입: 산술/논리 계열 (파란색)] ---
        // 6. ADDI: x2 = x1 + 10 [cite: 111, 1018]
        rom[5]  = 32'h00A08113;

        // 7. SLTI: x1 = (x2 < -1) ? 1 : 0 (signed) [cite: 111, 1020]
        rom[6]  = 32'hFFF12093;

        // 8. SLTIU: x1 = (x2 < 10) ? 1 : 0 (unsigned) [cite: 111, 1021]
        rom[7]  = 32'h00A13093;

        // 9. XORI: x2 = x3 ^ 5 [cite: 111, 1023]
        rom[8]  = 32'h0051C113;

        // 10. ORI: x3 = x4 | 15 [cite: 111, 1023]
        rom[9]  = 32'h00F26193;

        // 11. ANDI: x4 = x5 & 7 [cite: 111, 1023]
        rom[10] = 32'h0072F213;

        // --- [I-타입: 쉬프트 계열] ---
        // 12. SLLI: x5 = x6 << 2 (Logical Left Shift) [cite: 111, 1028]
        rom[11] = 32'h00231293;

        // 13. SRLI: x6 = x7 >> 3 (Logical Right Shift) 
        rom[12] = 32'h0033D313;

        // 14. SRAI: x7 = x1 >>> 4 (Arithmetic Right Shift) [cite: 111, 1012]
        rom[13] = 32'h4040D393;
    end

    assign instr_data = rom[instr_addr[31:2]];
endmodule

`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:127];

    initial begin
       // $readmemh("rv32i.mem",rom);  // 파일에서 읽어와서 rom에 저장


                  
        // [U-Type] 상위 20비트 즉치값 로드
        rom[0] = 32'h123450b7;  // LUI   x1, 0x12345    (x1 = 0x12345000)
        rom[1] = 32'h00000117;  // AUIPC x2, 0
        // [I-Type] ALU 연산
        rom[2] = 32'h7ff08193;  // ADDI  x3, x1, 2047   (x3 = x1 + 2047)
        rom[3] = 32'hfff0a213;  // SLTI  x4, x1, -1     (x4 = x1 < -1 ? 1 : 0)
        rom[4]  = 32'h0ff0b293; // SLTIU x5, x1, 255    (x5 = x1 < 255(unsigned) ? 1 : 0)
        rom[5] = 32'h0550c313;  // XORI  x6, x1, 85     (x6 = x1 ^ 0x55)
        rom[6] = 32'h0aa0e393;  // ORI   x7, x1, 170    (x7 = x1 | 0xAA)
        rom[7] = 32'h0ff0f413;  // ANDI  x8, x1, 255    (x8 = x1 & 0xFF)
        rom[8] = 32'h00409493;  // SLLI  x9, x1, 4      (x9 = x1 << 4)
        rom[9] = 32'h0040d513;  // SRLI  x10, x1, 4     (x10 = x1 >> 4, 논리)
        rom[10] = 32'h4040d593; // SRAI  x11, x1, 4     (x11 = x1 >>> 4, 산술)

        // [R-Type] ALU 연산
        rom[11] = 32'h00418633;  // ADD   x12, x3, x4    (x12 = x3 + x4)
        rom[12] = 32'h404186b3;  // SUB   x13, x3, x4    (x13 = x3 - x4)
        rom[13] = 32'h00419733;  // SLL   x14, x3, x4    (x14 = x3 << x4[4:0])
        rom[14] = 32'h0041a7b3;  // SLT   x15, x3, x4    (x15 = x3 < x4 ? 1 : 0)
        rom[15] = 32'h0041b833; // SLTU  x16, x3, x4    (x16 = x3 < x4(u) ? 1 : 0)
        rom[16] = 32'h0041c8b3;  // XOR   x17, x3, x4    (x17 = x3 ^ x4)
        rom[17] = 32'h0041d933;  // SRL   x18, x3, x4    (x18 = x3 >> x4[4:0])
        rom[18] = 32'h4041d9b3;  // SRA   x19, x3, x4    (x19 = x3 >>> x4[4:0])
        rom[19] = 32'h0041ea33;  // OR    x20, x3, x4    (x20 = x3 | x4)
        rom[20] = 32'h0041fab3;  // AND   x21, x3, x4    (x21 = x3 & x4)

        // [S-Type] 메모리 Store
        rom[21] = 32'h00c10023;  // SB    x12, 0(x2)     (Mem[x2][7:0] = x12)
        rom[22] = 32'h00d11123;  // SH    x13, 2(x2)     (Mem[x2+2][15:0] = x13)
        rom[23] = 32'h00e12223;  // SW    x14, 4(x2)     (Mem[x2+4][31:0] = x14)

        // [I-Type] 메모리 Load
        rom[24] = 32'h00010b03; // LB    x22, 0(x2)     (x22 = Mem[x2] 부호확장)
        rom[25] = 32'h00211b83; // LH    x23, 2(x2)     (x23 = Mem[x2+2] 부호확장)
        rom[26] = 32'h00412c03;  // LW    x24, 4(x2)     (x24 = Mem[x2+4])
        rom[27] = 32'h00014c83;  // LBU   x25, 0(x2)     (x25 = Mem[x2] 0확장)
        rom[28] = 32'h00215d03; // LHU   x26, 2(x2)     (x26 = Mem[x2+2] 0확장)

        // [B-Type] 조건부 분기 (Branch)
        rom[29] = 32'h00d60463; // BEQ   x12, x13, +8   (x12 == x13 이면 PC+8)
        rom[30] = 32'h00d61463; // BNE   x12, x13, +8   (x12 != x13 이면 PC+8)
        rom[31] = 32'h00d64463;  // BLT   x12, x13, +8   (x12 < x13 이면 PC+8)
        rom[32] = 32'h00d65463; // BGE   x12, x13, +8   (x12 >= x13 이면 PC+8)
        rom[33] = 32'h00d66463; // BLTU  x12, x13, +8   (x12 < x13(u) 이면 PC+8)
        rom[34] = 32'h00d67463; // BGEU  x12, x13, +8   (x12 >= x13(u) 이면 PC+8)

        // [J & I-Type] 점프 (Jump)
        rom[35] = 32'h01000def;  // JAL   x27, +16       (x27 = PC+4, PC += 16)
        rom[36] = 32'h004d8e67; // JALR  x28, x27, +4   (x28 = PC+4, PC = x27+4)
        
    end  // 나머지는 X가 될 것임

    assign instr_data = rom[instr_addr[31:2]]; // 1씩 증가되도록 함 (원래는 4씩 증가인데 비트를 잘라버림)

endmodule

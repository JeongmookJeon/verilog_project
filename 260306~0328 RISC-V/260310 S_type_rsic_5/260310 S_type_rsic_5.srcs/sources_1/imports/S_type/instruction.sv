`timescale 1ns / 1ps
`include "define.vh"
module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_data
);
    // 32비트 명령어가 들어갈 공간 32개 선언
    logic [31:0] rom[0:31];
    initial begin
        // [SB] Store Byte: 맨 뒤 1바이트(8비트)만 저장 테스트
        rom[0] = 32'h00A08023;  // sb x10, 0(x1)  -> 주소 0번지에 '78'만 저장
        rom[1] = 32'h00B080A3;  // sb x11, 1(x1)  -> 주소 1번지에 'DD'만 저장
        rom[2] = 32'h00C08123;  // sb x12, 2(x1)  -> 주소 2번지에 '66'만 저장

        // [SH] Store Halfword: 맨 뒤 2바이트(16비트)만 저장 테스트
        rom[3] = 32'h00A09223;  // sh x10, 4(x1)  -> 주소 4번지에 '5678' 저장
        rom[4] = 32'h00B09323;  // sh x11, 6(x1)  -> 주소 6번지에 'CCDD' 저장
        rom[5] = 32'h00C09423;  // sh x12, 8(x1)  -> 주소 8번지에 '7766' 저장

        // [SW] Store Word: 32비트 전체(4바이트) 저장 테스트
        rom[6] = 32'h00A0A623;  // sw x10, 12(x1) -> 주소 12번지에 '12345678' 전체 저장
        rom[7] = 32'h00B0A823;  // sw x11, 16(x1) -> 주소 16번지에 'AABBCCDD' 전체 저장
        rom[8] = 32'h00C0AA23;  // sw x12, 20(x1) -> 주소 20번지에 '99887766' 전체 저장
    end


    // PC 주소(0, 4, 8...)를 배열 인덱스(0, 1, 2...)로 변환하여 출력
    assign instr_data = rom[instr_addr[31:2]];

endmodule
/*
    initial begin stype
        rom[0] = 32'h004182b3;
        rom[1] = 32'h00810123;  //SW x2, 2(x8), SW x2, x8,2
    end

*/
/* rtype random
  initial begin
        rom[0] = 32'h002082b3;  // 주소 0  : ADD  x5, x1, x2  (x1 + x2)
        rom[1] = 32'h407302b3;  // 주소 4  : SUB  x5, x6, x7  (x6 - x7)
        rom[2] = 32'h009412b3;  // 주소 8  : SLL  x5, x8, x9  (x8 << x9)
        rom[3] = 32'h00b522b3;  // 주소 12 : SLT  x5, x10, x11 (x10 < x11)
        rom[4] = 32'h00d632b3; // 주소 16 : SLTU x5, x12, x13 (x12 < x13 unsigned)
        rom[5] = 32'h00f742b3;  // 주소 20 : XOR  x5, x14, x15 (x14 ^ x15)
        rom[6] = 32'h011852b3;  // 주소 24 : SRL  x5, x16, x17 (x16 >> x17)
        rom[7] = 32'h413952b3;  // 주소 28 : SRA  x5, x18, x19 (x18 >>> x19)
        rom[8] = 32'h015a62b3;  // 주소 32 : OR   x5, x20, x21 (x20 | x21)
        rom[9] = 32'h017b72b3;  // 주소 36 : AND  x5, x22, x23 (x22 & x23)
    end
    */
/* rtype normal
    initial begin
        // R-Type 10종  (rs1=x3, rs2=x4, rd=x5 기준)
        rom[0]  = 32'h004182b3; // 주소 0  : ADD  x5, x3, x4
        rom[1]  = 32'h404182b3; // 주소 4  : SUB  x5, x3, x4
        rom[2]  = 32'h004192b3; // 주소 8  : SLL  x5, x3, x4
        rom[3]  = 32'h0041a2b3; // 주소 12 : SLT  x5, x3, x4
        rom[4]  = 32'h0041b2b3; // 주소 16 : SLTU x5, x3, x4
        rom[5]  = 32'h0041c2b3; // 주소 20 : XOR  x5, x3, x4
        rom[6]  = 32'h0041d2b3; // 주소 24 : SRL  x5, x3, x4
        rom[7]  = 32'h4041d2b3; // 주소 28 : SRA  x5, x3, x4
        rom[8]  = 32'h0041e2b3; // 주소 32 : OR   x5, x3, x4
        rom[9]  = 32'h0041f2b3; // 주소 36 : AND  x5, x3, x4
        
        // 나머지 0으로 초기화 
        for (int i = 10; i < 32; i++) begin
            rom[i] = 32'd0;
        end
    end
    */

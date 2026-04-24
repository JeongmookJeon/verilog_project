module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_data
);
    // 32비트 명령어가 들어갈 공간 32개 선언
    logic [31:0] rom [0:31]; 

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

    // PC 주소(0, 4, 8...)를 배열 인덱스(0, 1, 2...)로 변환하여 출력
    assign instr_data = rom[instr_addr[31:2]]; 
    
endmodule
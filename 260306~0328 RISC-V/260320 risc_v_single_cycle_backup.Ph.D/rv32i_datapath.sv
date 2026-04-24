`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         jal,
    input         jalr,
    input         branch,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    input  [ 2:0] rfwd_src,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;
    logic [31:0] rfwd_data, auipc, j_type;
    logic btaken;

    assign daddr  = alu_result;
    assign dwdata = rd2;

    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .btaken         (btaken),      // from alu comparator
        .branch         (branch),      // form control unit for B-type
        .jal            (jal),
        .jalr           (jalr),
        .imm_data       (imm_data),
        .rs1            (rd1),
        .program_counter(instr_addr),
        .pc_4_out       (j_type),
        .pc_imm_out     (auipc)
    );

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .RA1  (instr_data[19:15]),
        .RA2  (instr_data[24:20]),
        .WA   (instr_data[11:7]),
        .Wdata(rfwd_data),
        .rf_we(rf_we),
        .RD1  (rd1),
        .RD2  (rd2)
    );

    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0    (rd2),
        .in1    (imm_data),
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );

    alu U_ALU (
        .rd1        (rd1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result),
        .btaken     (btaken)
    );

    // to register file
    // write back
    mux_5x1 U_WB_MUX (
        .in0    (alu_result),  // alu_result
        .in1    (drdata),      // from data memory
        .in2    (imm_data),    // from imm extend, for LUI_TYPE
        .in3    (auipc),       // from PC + imm extend, for AUIPC
        .in4    (j_type),      // from PC + 4, for JAL/JALR
        .mux_sel(rfwd_src),
        .out_mux(rfwd_data)
    );

endmodule

module mux_5x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input        [31:0] in2,      // sel 2
    input        [31:0] in3,      // sel 3
    input        [31:0] in4,      // sel 4
    input        [ 2:0] mux_sel,
    output logic [31:0] out_mux
);
    // 우선 순위 필요 없음 -> always_comb
    // full_case 이기 때문에 초기화 필요 없음
    always_comb begin
        case (mux_sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            default: out_mux = 32'hxxxx;  // 버그 찾기 위해 x로
        endcase
    end
endmodule

module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);
    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])  // opcode
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end

            `I_TYPE, `IL_TYPE: begin  // load
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end

            `B_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}},
                    instr_data[7],  // imm[11]
                    instr_data[30:25],  // imm[10:5]
                    instr_data[11:8],  // imm[4:1]
                    1'b0  // imm[0]
                };

            end
            `LUI_TYPE, `AUIPC_TYPE: begin
                imm_data = {{instr_data[31:12]}, 12'b0};
            end

            `JL_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end

            `J_TYPE: begin
                imm_data = {
                    {12{instr_data[31]}},  //20 :12bit extend
                    instr_data[19:12],  //19:12  8bit
                    instr_data[20],  //11     1bt
                    instr_data[30:21],  //10:1 = 10bit
                    1'b0  // 1bit
                };
            end


        endcase
    end
endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    input         rf_we,
    output [31:0] RD1,
    output [31:0] RD2
);
    logic [31:0] register_file[0:31];  // x0 muxt have zero
`ifdef SIMULATION
    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif
    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[WA] <= Wdata;
        end
    end
    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;


endmodule

module alu (
    input        [31:0] rd1,          // RS1
    input        [31:0] rd2,          // RS2
    input        [ 3:0] alu_control,  // funct7[6], funct3 : 4bit
    output logic [31:0] alu_result,   // alu result
    output logic        btaken
);

    always_comb begin
        alu_result = 0;
        case (alu_control)  // 명령어
            `ADD: alu_result = rd1 + rd2;  // add RD = RS1 + RS2
            `SUB: alu_result = rd1 - rd2;  // sub RD = RS1 - RS2
            `SLL: alu_result = rd1 << rd2[4:0];  // sll rd = rs1 << rs2
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 :
                0;  // slt rd = (rs1 < rs2) ? 1:0 // $signed -> 부호 처리
            `SLTU:
            alu_result = (rd1 < rd2) ? 1 : 0;  // sltu rd = (rs1 < rs2) ? 1:0
            `XOR: alu_result = rd1 ^ rd2;  // xor rd = rs1 ^ rs2
            `SRL: alu_result = rd1 >> rd2[4:0];  // srl rd = rs1 >> rs2
            `SRA:
            alu_result = $signed(rd1) >>>
                rd2[4:0];  // sra rd = rs1 >>> rs2, msb extention // sra: arithmetic right shift 산술 우 시프트 (msb로 채워 나감) // shift 대상을 signed로 바꿔야 확장된다?
            `OR: alu_result = rd1 | rd2;  // or rd = rs1 | rs2
            `AND: alu_result = rd1 & rd2;  // and rd = rs1 & rs2

        endcase
    end

    // B-type comparator
    always_comb begin
        btaken = 1'b0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1'b1;  // true : pc = pc + imm
                else btaken = 1'b0;  // false : pc = pc +4
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1'b1;  // true : pc = pc + imm
                else btaken = 1'b0;  // false : pc = pc +4
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2)) btaken = 1'b1;
                else btaken = 1'b0;
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2)) btaken = 1'b1;
                else btaken = 1'b0;
            end

            `BLTU: begin
                if (rd1 < rd2) btaken = 1'b1;  // true : pc = pc + imm
                else btaken = 1'b0;  // false : pc = pc +4
            end
            `BGEU: begin
                if (rd1 >= rd2) btaken = 1'b1;  // true : pc = pc + imm
                else btaken = 1'b0;  // false : pc = pc +4
            end
            default: btaken = 1'b0;
        endcase
    end
endmodule

module program_counter (
    input         clk,
    input         rst,
    input         btaken,
    input         branch,
    input         jal,
    input         jalr,
    input  [31:0] imm_data,
    input  [31:0] rs1,
    output [31:0] program_counter,
    output [31:0] pc_4_out,
    output [31:0] pc_imm_out
);
    logic [31:0] pc_next, pc_jtype;
    mux_2x1 U_PC_JTYPE_MUX (  //jalr
        .in0(program_counter),
        .in1(rs1),
        .mux_sel(jalr),
        .out_mux(pc_jtype)
    );
    mux_2x1 PC_NEXT_MUX (
        .in0(pc_4_out),
        .in1(pc_imm_out),
        .mux_sel(jal | (btaken & branch)),
        .out_mux(pc_next)
    );
    pc_alu U_PC_ALU_IMM (
        .a(imm_data),
        .b(pc_jtype),
        .pc_alu_out(pc_imm_out)
    );
    pc_alu U_PC_4 (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)
    );
    register U_REGISTER (
        .clk     (clk),
        .rst     (rst),
        .data_in (pc_next),
        .data_out(program_counter)
    );
endmodule

module mux_2x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input               mux_sel,
    output logic [31:0] out_mux
);
    assign out_mux = (mux_sel) ? in1 : in0;
endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;
endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end
    assign data_out = register;
endmodule

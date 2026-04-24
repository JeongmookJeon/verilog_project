`timescale 1ns / 1ps
`include "define.vh"



module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         branch,
    input         jal,
    input         jalr,
    input         alu_src,
    input  [ 2:0] rf_wb_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata,
    input  [31:0] drdata
);
    logic [31:0] wb_data_mux5x1, imm_data, rd1, rd2, imm_2_alu;
    logic [31:0] mux_5x1_in_pc_4, mux_5x1_in_imm, alu_result;
    logic btaken;
    assign dwdata = rd2;
    assign daddr  = alu_result;
    program_counter U_PROGRAM_COUNTER (
        .clk(clk),
        .rst(rst),
        .btaken(btaken),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .imm_data(imm_data),
        .rs1(rd1),
        .pc_4_out(mux_5x1_in_pc_4),
        .pc_imm_out(mux_5x1_in_imm),
        .program_counter(instr_addr)
    );

    register_file U_REGISTER_FILE (
        .clk(clk),
        .rst(rst),
        .ra1(instr_data[19:15]),
        .ra2(instr_data[24:20]),
        .wa(instr_data[11:7]),
        .wdata(wb_data_mux5x1),
        .rf_we(rf_we),
        .rd1(rd1),
        .rd2(rd2)
    );
    mux_2x1 U_MUX_rd2_imm (
        .a(rd2),
        .b(imm_data),
        .mux_sel(alu_src),
        .mux_out(imm_2_alu)

    );
    imm_extender U_IMM_EXTENDER (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );
    alu U_ALU (
        .rd1        (rd1),          //rs1
        .rd2        (imm_2_alu),    //rs2
        .alu_control(alu_control),
        .btaken     (btaken),
        .alu_result (alu_result)
    );
    mux_5x1 U_MUX_5x1 (
        .in0        (alu_result),       //alu_result
        .in1        (drdata),           //rdata
        .in2        (imm_data),         //lui
        .in3        (mux_5x1_in_imm),   // auipc
        .in4        (mux_5x1_in_pc_4),  // jal/jalr
        .mux_5x1_sel(rf_wb_src),
        .mux_5x1_out(wb_data_mux5x1)
    );


endmodule

module mux_5x1 (
    input        [31:0] in0,          //alu_result
    input        [31:0] in1,          //rdata
    input        [31:0] in2,          //lui
    input        [31:0] in3,          // auipc
    input        [31:0] in4,          // jal/jalr
    input        [ 2:0] mux_5x1_sel,
    output logic [31:0] mux_5x1_out
);
    always_comb begin
        case (mux_5x1_sel)
            3'b000:  mux_5x1_out = in0;
            3'b001:  mux_5x1_out = in1;
            3'b001:  mux_5x1_out = in2;
            3'b001:  mux_5x1_out = in3;
            3'b001:  mux_5x1_out = in4;
            default: mux_5x1_out = 32'hxxxx;
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

module alu (
    input        [31:0] rd1,          //rs1
    input        [31:0] rd2,          //rs2
    input        [ 3:0] alu_control,
    output logic        btaken,
    output logic [31:0] alu_result
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

module register_file (
    input               clk,
    input               rst,
    input  logic [ 4:0] ra1,
    input  logic [ 4:0] ra2,
    input  logic [ 4:0] wa,
    input  logic [31:0] wdata,
    input               rf_we,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] register_file[0:31];
`ifdef SIMULATION
    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif
    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[wa] <= wdata;
        end
    end
    //read하는거니까 rd가 왼쪽에!
    assign rd1 = (ra1 != 0) ? register_file[ra1] : 0;
    assign rd2 = (ra2 != 0) ? register_file[ra2] : 0;
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
    output [31:0] pc_4_out,
    output [31:0] pc_imm_out,
    output [31:0] program_counter
);

    logic [31:0] o_jmux_out, pc_reg_mux2x1;
    mux_2x1 U_MUX_J (
        .a(program_counter),
        .b(rs1),
        .mux_sel(jalr),
        .mux_out(o_jmux_out)
    );
    mux_2x1 U_MUX_PC_IMM (
        .a(pc_4_out),
        .b(pc_imm_out),
        .mux_sel(jal | (btaken & branch)),
        .mux_out(pc_reg_mux2x1)
    );
    pc_alu U_PC_IMM (
        .a(imm_data),
        .b(o_jmux_out),
        .pc_alu_out(pc_imm_out)
    );
    pc_alu U_PC_ALU (
        .a(32'h4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)
    );
    pc_register U_PC_REG(  // we 발생 했을때 data를 저장할 수 있음.
        .clk(clk),
        .rst(rst),
        .data_in(pc_reg_mux2x1),
        .data_out(program_counter)
    );

endmodule

module mux_2x1 (
    input  [31:0] a,
    input  [31:0] b,
    input         mux_sel,
    output [31:0] mux_out
);
    assign mux_out = (mux_sel) ? b : a;

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;

endmodule

module pc_register (  // we 발생 했을때 data를 저장할 수 있음.
    input               clk,
    input               rst,
    input  logic [31:0] data_in,
    output logic [31:0] data_out
);
    logic [31:0] register;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 32'b0;
        end else begin
            register <= data_in;
        end
    end
    assign data_out = register;
endmodule

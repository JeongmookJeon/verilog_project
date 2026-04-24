`timescale 1ns / 1ps
`include "define.vh"


module rv32i_datapath (
    input         clk,
    input         rst,
    input         pc_en,
    input         rf_we,
    input         jal,
    input         jalr,
    input         branch,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    input  [ 2:0] rf_wb_src,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);
    logic [31:0] imm_data,alu_result, alurs2_data;
    logic [31:0] rfwb_data, auipc, j_type;
    logic btaken;
    // decoder
    logic [31:0]
        i_dec_rs1, o_dec_rs1, i_dec_rs2, o_dec_rs2, i_dec_imm, o_dec_imm;
    // execute
    logic [31:0] o_exe_rs2, o_exe_alu_result;
    // mem
    logic [31:0] o_mem_drdata;
    // write back to register file

    assign daddr  = o_exe_alu_result;
    assign dwdata = o_exe_rs2;

    // fetch, Execute
    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .pc_en          (pc_en),
        .btaken         (btaken),      // from alu comparator
        .branch         (branch),      // from Control unit for B-type
        .jal            (jal),
        .jalr           (jalr),
        .imm_data       (o_dec_imm),
        .rs1            (o_dec_rs1),
        .program_counter(instr_addr),
        .pc_4_out       (j_type),
        .pc_imm_out     (auipc)
    );

    // decode

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .ra1(instr_data[19:15]),
        .ra2(instr_data[24:20]),
        .wa(instr_data[11:7]),
        .wdata(rfwb_data),
        .rf_we(rf_we),
        .rd1(i_dec_rs1),
        .rd2(i_dec_rs2)
    );
    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    // decode output register
    register U_DEC_REG_RS1 (
        .clk(clk),
        .rst(rst),
        .data_in(i_dec_rs1),
        .data_out(o_dec_rs1)
    );

    register U_DEC_REG_RS2 (
        .clk(clk),
        .rst(rst),
        .data_in(i_dec_rs2),
        .data_out(o_dec_rs2)
    );

    register U_DEC_IMM_EXT (
        .clk(clk),
        .rst(rst),
        .data_in(imm_data),
        .data_out(o_dec_imm)
    );
    // execute

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0(o_dec_rs2),  // sel 0
        .in1(o_dec_imm),  // sel 1
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );
    alu U_ALU (
        .rd1(o_dec_rs1),
        .rd2(alurs2_data),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .btaken(btaken)
    );

    // execute registe for ALU result, RS2
    register U_EXE_ALU_RESULT (
        .clk(clk),
        .rst(rst),
        .data_in(alu_result),
        .data_out(o_exe_alu_result)  // to DAddr 
    );
    register U_EXE_REG_RS2 (
        .clk(clk),
        .rst(rst),
        .data_in(o_dec_rs2),  // from alu result
        .data_out(o_exe_rs2)  // to Data MEM_Wdata
    );
    // MEM to WB 
    register U_MEM_REG_DRDATA (
        .clk(clk),
        .rst(rst),
        .data_in(drdata),  // from alu result
        .data_out(o_mem_drdata)  // to Data MEM_Wdata
    );


    // Write Back to Register File

    // to register file
    mux_5x1 U_WB_MUX (
        .in0    (alu_result),  // from ALU Result , because of process with execute state
        .in1    (o_mem_drdata),            // from data memory
        .in2    (o_dec_imm),         // from imm extend, for LUI
        .in3    (auipc),             // from pc + imm extend, for AUIPC
        .in4    (j_type),            // from PC + 4, for JAL/JALR
        .mux_sel(rf_wb_src),
        .out_mux(rfwb_data)
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

    always_comb begin
        case (mux_sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            default: out_mux = 32'hxxxx;
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
            `JL_TYPE, `I_TYPE, `IL_TYPE: begin  // load
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `B_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}},
                    instr_data[7],  // imm bit 11
                    instr_data[30:25],  // imm bit 10:5
                    instr_data[11:8],  // imm bit 4:1
                    1'b0
                };
            end
            `UA_TYPE, `UL_TYPE: begin
                imm_data = {instr_data[31:12], {12{1'b0}}};
            end
            `J_TYPE: begin
                imm_data = {
                    {12{instr_data[31]}},  // 20    :12bit extend
                    instr_data[19:12],  // 19:12 :8bit
                    instr_data[20],  // 11    :1bit
                    instr_data[30:21],  // 10:1  :10bit
                    1'b0
                };
            end
        endcase
    end

endmodule
module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] ra1,
    input  [ 4:0] ra2,
    input  [ 4:0] wa,
    input  [31:0] wdata,
    input         rf_we,
    output [31:0] rd1,
    output [31:0] rd2
);
    logic [31:0] register_file[1:31];  // x0 must have zero value
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
    // output CL
    assign rd1 = (ra1 != 0) ? register_file[ra1] : 0;
    assign rd2 = (ra2 != 0) ? register_file[ra2] : 0;
endmodule

module alu (
    input        [31:0] rd1,          // RS1
    input        [31:0] rd2,          // RS2
    input        [ 3:0] alu_control,  // funct7[6],funct3 : 4bit
    output logic [31:0] alu_result,   // alu result
    output logic        btaken
);

    always_comb begin
        alu_result = 0;
        case (alu_control)
            `ADD: alu_result = rd1 + rd2;  // add RD  = RS1 + RS2
            `SUB: alu_result = rd1 - rd2;  // sub rd = rs1 - rs2
            `SLL: alu_result = rd1 << rd2[4:0];  // sll rd = rs1 << rs2
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 :
                0;  // slt rd = (rs1 < rs2) ? 1:0
            `SLTU:
            alu_result = (rd1 < rd2) ? 1 : 0;  // sltu rd = (rs1 < rs2) ? 1:0
            `XOR: alu_result = rd1 ^ rd2;  // xor rd = rs1 ^ rs2
            `SRL: alu_result = rd1 >> rd2[4:0];  // SRL rd = rs1 >> rs2
            `SRA:
            alu_result = $signed(rd1) >>>
                rd2[4:0];  // SRA rd = rs1 >> rs2 , msb extention, arithmetic right shift
            `OR: alu_result = rd1 | rd2;  // or RD  = RS1 | RS2
            `AND: alu_result = rd1 & rd2;  // and RD  = RS1 & RS2
        endcase
    end

    // B-type comparator
    always_comb begin
        btaken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2))
                    btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2))
                    btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BLTU: begin
                if (rd1 < rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BGEU: begin
                if (rd1 >= rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
        endcase
    end

endmodule

module program_counter (
    input         clk,
    input         rst,
    //input [31:0] instr_addr
    input         pc_en,            // from Control unit for PC register
    input         btaken,           // from alu for B-type
    input         branch,           // from Control unit for B-type
    input         jal,
    input         jalr,
    input  [31:0] imm_data,
    input  [31:0] rs1,
    output [31:0] program_counter,
    output [31:0] pc_4_out,         // for J type, PC +4
    output [31:0] pc_imm_out        // for UA type , PC + imm
);
    logic [31:0] o_jmux_out, o_pc4_imm_out, o_pc4_imm_reg_in;
    pc_alu U_PC4_ALU (  // pc alu =  a+b
        .a(32'h4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)
    );
    mux_2x1 U_JMUX (
        .in0(program_counter),
        .in1(rs1),
        .mux_sel(jalr),
        .out_mux(o_jmux_out)
    );
    pc_alu U_IMM_ALU (  // pc alu =  a+b
        .a(imm_data),
        .b(o_jmux_out),
        .pc_alu_out(pc_imm_out)
    );
    mux_2x1 U_PC_IMM_MUX (
        .in0(pc_4_out),
        .in1(pc_imm_out),
        .mux_sel(jal | (branch & btaken)),
        .out_mux(o_pc4_imm_out)
    );

    register U_REG (  // 순차로직 register
        .clk(clk),
        .rst(rst),
        .data_in(o_pc4_imm_out),
        .data_out(o_pc4_imm_reg_in)
    );
    register_en U_PC_REG (  // 'en' signal!! register 저장
        .clk(clk),
        .rst(rst),
        .en(pc_en),
        .data_in(o_pc4_imm_reg_in),
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

module pc_alu (  // pc alu =  a+b
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;
endmodule

module register (  // 순차로직 register
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

module register_en (  // 'en' signal!! register 저장
    input         clk,
    input         rst,
    input         en,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            if (en) register <= data_in;
        end
    end
    assign data_out = register;
endmodule

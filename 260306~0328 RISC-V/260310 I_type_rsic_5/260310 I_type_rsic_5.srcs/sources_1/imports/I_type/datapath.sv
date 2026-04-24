`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] drdata,
    input         rfwd_src,
    output [31:0] instr_addr,
    output [31:0] instr_data,
    output [31:0] daddr,
    output [31:0] dwdata
);
    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;
    logic [31:0] rfwb_data;
    assign daddr  = alu_result;
    assign dwdata = rd2;

    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .program_counter(instr_addr)
    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(rfwb_data),
        .rf_we(rf_we),
        .RD1(rd1),
        .RD2(rd2)
    );
    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );
    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0(rd2),     //sel 0
        .in1(imm_data),     //sel1
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );
    alu U_ALU (
        .rd1(rd1),
        .rd2(alurs2_data),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );
    //to register
    mux_2x1 U_WB_REGFILE (
        .in0(alu_result),     //sel 0
        .in1(drdata),     //sel1
        .mux_sel(rfwd_src),
        .out_mux(rfwb_data)
    );


endmodule

module mux_2x1 (
    input [31:0] in0,
    input [31:0] in1,
    input mux_sel,
    output [31:0] out_mux
);
    assign out_mux = (mux_sel) ? in1 : in0;
endmodule

module imm_extender (  // ALU에 넣어주기위해 32bit가 필요하다.
    input [31:0] instr_data,
    output logic [31:0] imm_data
);
    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])  //opcode가 들어오면
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `IL_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `I_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
        endcase
    end
endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,    // intruction RS1
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    input         rf_we,
    output [31:0] RD1,
    output [31:0] RD2
);
    logic [31:0] register_file[0:31];

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif
    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[WA] <= Wdata;
        end
    end
    // output CL
    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;



endmodule

module alu (
    input        [31:0] rd1,
    input        [31:0] rd2,
    input        [ 3:0] alu_control,  // define의 4'b0_000값  
    output logic [31:0] alu_result
);
    always_comb begin
        alu_result = 0;
        case (alu_control)
            `ADD: alu_result = rd1 + rd2;  //add RD = RS1 + RS2
            `SUB: alu_result = rd1 - rd2;  //sub rd = rs1 - rs2
            `SLL: alu_result = rd1 << rd2[4:0];  //sll rd = rs1 << rs2
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 :
                0;  //slt rd = (rs1 << rs2) ? 1:0
            `SLTU: alu_result = (rd1 < rd2) ? 1 : 0;  // sltu : 위와 동일
            `XOR: alu_result = rd1 ^ rd2;  // XOR rd = rs1 ^ rs2
            `SRL: alu_result = rd1 >> rd2[4:0];  // SRL rd = rs1 >> rs2
            `SRA:
            alu_result = $signed(rd1) >>>
                rd2[4:0];  // SRA rd = rs1 >>> rs2, msb extention, arithmetic
            `OR: alu_result = rd1 | rd2;  //  or RD = RS1 | RS2
            `AND: alu_result = rd1 & rd2;  //and RD = RS1 & RS2
        endcase
    end
endmodule

module program_counter (
    input clk,
    input rst,
    //input  [31:0] instr_add,
    output logic [31:0] program_counter
);
    logic [31:0] pc_alu_out;
    pc_alu U_PC_ALU (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_alu_out)
    );
    register U_REGISTER (
        .clk(clk),
        .rst(rst),
        .data_in(pc_alu_out),
        .data_out(program_counter)
    );

endmodule

module pc_alu (  // instruction 주소 4byte씩 더하기
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

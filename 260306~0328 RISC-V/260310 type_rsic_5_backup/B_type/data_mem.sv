`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [ 2:0] i_funct3,  // o_funct3
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    /* byte address
    logic [7:0] dmem[0:31];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
        end else begin
            if (dwe) begin
                dmem[dwaddr+0] <= dwdata[7:0];
                dmem[dwaddr+1] <= dwdata[15:8];
                dmem[dwaddr+2] <= dwdata[23:16];
                dmem[dwaddr+3] <= dwdata[31:24];
            end
        end
    end

    assign drdata = {
        dmem[dwaddr], dmem[dwaddr+1], dmem[dwaddr+2], dmem[dwaddr+3]
    };
    */

    // word address
    logic [31:0] dmem[0:31];

    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b010: dmem[daddr[31:2]] <= dwdata;  // SW
                3'b001: begin  // SH
                    if (daddr[1]) dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                    else dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                end
                3'b000: begin  // SB
                    case (daddr[1:0])
                        2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
            endcase
        end
    end


    always_comb begin
        case (i_funct3)
            3'b000: begin  // LB 
                case (daddr[1:0])
                    2'b00: drdata = {{24{daddr[7]}}, daddr[7:0]};
                    2'b01: drdata = {{24{daddr[15]}}, daddr[15:8]};
                    2'b10: drdata = {{24{daddr[23]}}, daddr[23:16]};
                    2'b11: drdata = {{24{daddr[31]}}, daddr[31:24]};
                endcase
            end
            3'b001: begin  // LH 
                if (daddr[1]) drdata = {{16{daddr[31]}}, daddr[31:16]};
                else drdata = {{16{daddr[15]}}, daddr[15:0]};
            end
            3'b010:  drdata = daddr;  // LW
            3'b100: begin  // LBU 
                case (daddr[1:0])
                    2'b00: drdata = {24'd0, daddr[7:0]};
                    2'b01: drdata = {24'd0, daddr[15:8]};
                    2'b10: drdata = {24'd0, daddr[23:16]};
                    2'b11: drdata = {24'd0, daddr[31:24]};
                endcase
            end
            default: drdata = daddr;
        endcase
    end

endmodule

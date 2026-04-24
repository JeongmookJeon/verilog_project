`timescale 1ns / 1ps



module imm_extender (
    input clk,
    input rst,
    input [11:0] in_data,
    output [31:0] out_data
);

   // assign out_data = {20'h0 + in_data};

    always_comb begin
        if (rst) begin
            out_data <= 0;
        end else begin
            out_data <= {20'h0 + in_data};
        end
    end

endmodule



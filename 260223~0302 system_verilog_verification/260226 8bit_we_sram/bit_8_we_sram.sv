`timescale 1ns / 1ps

module bit_8_we_sram (  // sram이 뭔지 확인!!!
    input              clk,
    input  logic [3:0] addr,
    input  logic [7:0] wdata,
    input              we,
    output logic [7:0] rdata
);
    logic [7:0] ram[0:15];
    always_ff @(posedge clk) begin : blockName
        if (we) begin
            ram[addr] <= wdata;
        end
    end
    assign rdata = ram[addr];
endmodule

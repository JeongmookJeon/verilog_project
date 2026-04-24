`timescale 1ns / 1ps

module BRAM (

    // BUS Global signal
    input               PCLK,
    input               PRESET,
    // APB Interface Signal
    input        [31:0] PADDR,    // need register
    input        [31:0] PWDATA,   // need register
    input               PENABLE,
    input               PWRITE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);


    logic [31:0] bram[0:1024];  // word :  1024*4byte : 4K

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge PCLK) begin

        if (PSEL & PENABLE & PWRITE) begin
            bram[PADDR[11:2]] <= PWDATA;  // SW
        end
    end

    assign PRDATA = bram[PADDR[11:2]];
endmodule

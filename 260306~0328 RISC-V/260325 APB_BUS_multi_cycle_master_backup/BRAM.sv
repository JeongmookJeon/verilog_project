`timescale 1ns / 1ps

module BRAM (  //pg. RAM Slave
    //BUS global signal
    input               PCLK,
    //APB Interface Signal
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PENABLE,
    input               PWRITE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    //ram
    logic [31:0] bram[0:1024];  //1024*4byte

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge PCLK) begin
        if (PSEL & PENABLE & PWRITE) bram[PADDR[11:2]] <= PWDATA;  // SW
    end

    assign PRDATA = bram[PADDR[11:2]];


endmodule

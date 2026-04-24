`timescale 1ns / 1ps


module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        mode,
    input  logic [31:0] s,
    output logic        c
);

    assign {c, s} = {mode} ? a - b : a + b;
endmodule

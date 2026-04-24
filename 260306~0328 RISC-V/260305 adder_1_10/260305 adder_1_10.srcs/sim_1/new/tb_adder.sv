`timescale 1ns / 1ps

module tb_adder_1_10 ();
    logic clk, rst;
    logic [7:0] out;

    adder_1_10 dut (
        .clk(clk),
        .rst(rst),
        .out(out)
    );
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst = 1;
        #20;
        rst = 0;
        #1000;
        $stop;
    end
endmodule
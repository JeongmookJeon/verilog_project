`timescale 1ns / 1ps

module tb_adder ();
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
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        repeat (11) @(posedge clk);
        $stop;
    end
endmodule

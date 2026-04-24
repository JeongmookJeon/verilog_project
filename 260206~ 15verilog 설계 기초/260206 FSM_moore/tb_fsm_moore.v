`timescale 1ns / 1ps

module tb_fsm_moore ();

    reg clk, reset;
    reg  [2:0] sw;
    wire [2:0] led;

    fsm_moore dut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;
        sw = 3'b000;

        #10;
        reset = 0;

    #10; sw = 3'b001; // S0 -> S1 20
    #10; sw = 3'b010; // S1 -> S2 30
    #10; sw = 3'b100; // S2 -> S3 40
    #10; sw = 3'b111; // S3 -> S4 50
    #30; sw = 3'b000; // S4 -> S0 60 
    

        #20;
        $stop;
    end

endmodule

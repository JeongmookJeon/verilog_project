`timescale 1ns / 1ps

module tb_bounce ();
    reg clk, reset, i_btn;
    wire o_btn;

    btn_debounce dut (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn),
        .o_btn(o_btn)
    );

    always #5 clk = ~clk;

    initial begin

        #0 clk = 0;
        reset = 1;
        i_btn = 0;

        #10;
        reset = 0;
        i_btn = 1;
        #100;
        i_btn = 0;
        #10;

        i_btn = 1;
        #10;
        i_btn = 0; 
        #20;
        i_btn = 1;
        #50;
        i_btn = 0;
        #30;
        i_btn = 1;
    


        $stop;


    end
endmodule

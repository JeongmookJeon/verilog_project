`timescale 1ns / 1ps

module tb_uart_tx ();

    parameter BAUD_9600 = 104_160;
    reg  clk;  // need to for btn_down 100msec
    reg  rst;
    reg  btn_down;
    wire uart_tx;
    uart_top DUT (
        .clk(clk),
        .rst(rst),
        .btn_down(btn_down),
        .uart_tx(uart_tx)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        btn_down = 0;
        #20;
        //rst
        rst = 0;
        //btndown, tx start
        btn_down = 1'b1;
        #100_000;
        btn_down = 1'b0;



        #(BAUD_9600 * 16);
        $stop;
    end




endmodule

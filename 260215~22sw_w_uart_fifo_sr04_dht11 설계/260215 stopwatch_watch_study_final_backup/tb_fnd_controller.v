`timescale 1ns / 1ps

module tb_fnd_controller ();
    reg clk, rst, sel_display;
    reg  [23:0] fnd_in_data;

    wire [ 3:0] fnd_digit;
    wire [ 7:0] fnd_data;

    fnd_controller dut (
        .clk(clk),
        .rst(rst),
        .sel_display(sel_display),
        .fnd_in_data(fnd_in_data),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    always #5 clk = ~clk;
    initial begin
        #0;
        clk = 0;
        rst = 1;
        fnd_in_data = 24'b0;
        #10;
        rst = 0;
        sel_display = 1;
        fnd_in_data = {5'd12, 6'd34, 6'd56, 7'd78};
        #200000;
        $stop;



    end
endmodule

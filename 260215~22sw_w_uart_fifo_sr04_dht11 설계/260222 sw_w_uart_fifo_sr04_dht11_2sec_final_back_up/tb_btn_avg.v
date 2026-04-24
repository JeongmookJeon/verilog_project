`timescale 1ns / 1ps


module tb_btn_avg();

    reg clk, rst, btn_r,btn_l,btn_u,btn_d,uart_rx,i_echo;
    reg [5:0] sw;
    wire uart_tx, o_trig;
    wire dhtio;
    wire [7:0]fnd_data;
    wire [3:0] fnd_digit;

top_uart_S_W_D dut (

    .clk(clk),
    .rst(rst),
    .sw(sw),
    .btn_r(btn_r),      // run_stop / start Trigger
    .btn_l(btn_l),      // clear
    .btn_u(btn_u),      // up
    .btn_d(btn_d),      // down
    .uart_rx(uart_rx),    // PC -> FPGA
    .i_echo(i_echo),     // SR04 Echo
    .uart_tx(uart_tx),    // FPGA -> PC
    .o_trig(o_trig),     // SR04 Trigger
    .dhtio(dhtio),      // dht11 inout port
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);
    
    always #5 clk = ~ clk;
    
    initial begin
        clk = 0;
        rst = 1;
        uart_rx = 0;
        sw = 6'b110000;
        
        #100;
        rst = 0;
        
        uart_rx= 1;
        #100000;
        uart_rx = 0;
        
        
        #52080;
        uart_rx = 0;
        
        #104160;
        uart_rx = 0;
        #104160;
        uart_rx = 1;
        
        #104160;
        uart_rx = 0;
        #104160;
        uart_rx = 0;
        #104160;
        uart_rx = 1;
        #104160;
        uart_rx = 1;
        #104160;
        uart_rx = 1;
        #104160;
        uart_rx = 0;
        #1000000;

        uart_rx= 1;
        #10000000;
        
        
        $stop;
    end
endmodule

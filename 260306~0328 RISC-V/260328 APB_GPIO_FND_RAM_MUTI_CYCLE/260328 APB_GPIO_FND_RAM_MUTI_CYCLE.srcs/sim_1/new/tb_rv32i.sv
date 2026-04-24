`timescale 1ns / 1ps

module tb_rv32i_sim ();

    logic          clk;
    logic          rst;
    logic   [ 7:0] gpi;
    logic   [ 7:0] gpo;
    wire    [ 7:0] gpio;
    logic   [15:0] gpio_i;
    logic   [15:0] gpio_o;
    logic   [ 3:0] fnd_digit;
    logic   [ 7:0] fnd_data;
    logic          rx;
    logic          tx;
    logic   [ 7:0] test_data;

    integer        i = 0;
    parameter TARGET_BAUD = 115200;
    localparam BAUDRATE_CYCLE = 1_000_000_000 / TARGET_BAUD;
    task uart_sender();
        begin
            // uart test pattern
            // start 
            rx = 0;
            #(BAUDRATE_CYCLE);
            // data
            for (i = 0; i < 8; i = i + 1) begin
                rx = test_data[i];
                #(BAUDRATE_CYCLE);
            end
            // stop
            rx = 1'b1;
            #(BAUDRATE_CYCLE);
        end
    endtask

    rv32I_mcu dut (
        .clk      (clk),
        .rst      (rst),
        .GPI      (gpi),
        .GPO      (gpo),
        .GPIO     (gpio),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data),
        .rx  (rx),
        .tx  (tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        gpi = 8'b11110011;
        test_data = 8'd11;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        #97000;
        uart_sender();
        #50;
        test_data = 8'd12;
        uart_sender();
        #1000;
        $stop;
    end

endmodule

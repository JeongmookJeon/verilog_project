`timescale 1ns / 1ps

module i2c_slave_top (
    input  logic       sys_clock,
    input  logic       reset,
    input  logic [7:0] sw,
    output logic [7:0] led,

    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data,

    input logic scl,
    inout logic sda
);

    logic [7:0] received_count;

    I2C_SLAVE u_slave (
        .clk(sys_clock),
        .reset(reset),
        .tx_data(sw),
        .rx_data(received_count),
        .done(),
        .busy(),
        .scl(scl),
        .sda(sda)
    );

    assign led = received_count;

    fnd_controller u_fnd_cntr (
        .clk(sys_clock),
        .reset(reset),
        .fnd_in_data({6'b0, received_count}),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule

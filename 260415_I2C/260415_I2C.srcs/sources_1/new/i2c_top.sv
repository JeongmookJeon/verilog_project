`timescale 1ns / 1ps

module i2c_top (
    input  logic        clk,
    input  logic        reset,
    // command port
    input  logic        cmd_start,
    input  logic        cmd_write,
    input  logic        cmd_read,
    input  logic        cmd_stop,
    input  logic [ 7:0] m_tx_data,
    input  logic [ 7:0] s_tx_data,
    input  logic        ack_in,
    // internal output
    output logic [ 7:0] m_rx_data,
    output logic [ 7:0] s_rx_data,
    output logic        m_done,
    output logic        s_done,
    output logic        ack_out,
    output logic        m_busy,
    output logic        s_busy
);

    wire scl, sda;

    pullup (scl);
    pullup (sda);

    I2C_MASTER U_I2C_MASTER (
        .*,
        .tx_data(m_tx_data),
        .rx_data(m_rx_data),
        .done(m_done),
        .busy(m_busy),
        .scl(scl),
        .sda(sda)
    );

    I2C_SLAVE U_I2C_SLAVE (
        .*,
        .tx_data(s_tx_data),
        .rx_data(s_rx_data),
        .busy(s_busy),
        .done(s_done),
        .scl(scl),
        .sda(sda)
    );

endmodule

`timescale 1ns / 1ps

module dht_11 (
    input clk,
    input rst,
    input start,
    input dht_data,          // 읽기 전용
    output reg dht_valid,
    output reg [39:0] dht_done
);
    // 100MHz 기준 (1us = 100 tick)
    localparam T_19MS = 19_000 * 100;
    localparam T_30US = 30 * 100;
    localparam T_80US = 80 * 100;
    localparam T_40US = 40 * 100;

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam WAIT  = 3'd2;
    localparam DATA  = 3'd3;
    localparam STOP  = 3'd4;
    reg [2:0] state;
    reg[5:0] bit_cnt_next;
    reg[39:0]shift_reg;
    reg dht_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter_reg;
        end

    end

endmodule

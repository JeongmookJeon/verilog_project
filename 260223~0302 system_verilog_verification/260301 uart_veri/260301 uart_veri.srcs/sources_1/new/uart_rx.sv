`timescale 1ns / 1ps

module uart_rxtop (
    input        clk,
    input        rst,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    // 내부 연결 신호
    wire b_tick;

    // Baud Tick Generator
    baud_tick u_baud_tick (
        .clk(clk),
        .rst(rst),
        .b_tick(b_tick)
    );

    // UART RX
    UARTRX u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule


module UARTRX (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 2'b0;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg <= 3'd0;
            done_reg <= 1'b0;
            buf_reg <= 8'd0;
        end else begin
            c_state <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            done_reg <= done_next;
            buf_reg <= buf_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        bit_cnt_next = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        done_next = done_reg;
        buf_next = buf_reg;
        case (c_state)
            IDLE: begin
                bit_cnt_next = 3'd0;
                b_tick_cnt_next = 5'd0;
                done_next = 1'b0;
                buf_next = 8'd0;
                if (b_tick && !rx) begin
                    n_state = START;
                end
            end
            START: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 5'd7) begin
                        b_tick_cnt_next = 5'd0;
                        n_state = DATA;                      
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 5'd15) begin
                        b_tick_cnt_next = 5'd0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 3'd7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 5'd15) begin
                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
        endcase
    end

endmodule

module baud_tick (
    input clk,
    input rst,
    output reg b_tick
);
    parameter BAUDRATE = 9600;
    parameter F_COUNT = 100_000_000 / (BAUDRATE * 16);  //parameter F_COUNT = 100_000_000 / BAUDRATE;

    reg [$clog2(F_COUNT) - 1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                b_tick <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end

endmodule

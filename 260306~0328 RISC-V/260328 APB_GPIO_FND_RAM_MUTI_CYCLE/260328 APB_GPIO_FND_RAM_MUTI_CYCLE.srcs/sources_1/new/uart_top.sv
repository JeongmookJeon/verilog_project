`timescale 1ns / 1ps

module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_next, bit_cnt_reg;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;
    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;
        case (c_state)
            IDLE: begin
                done_next = 1'b0;
                b_tick_cnt_next = 5'd0;
                bit_cnt_next = 3'd0;

                if (b_tick == 1 & (!rx)) begin
                    buf_next = 8'd0;
                    n_state  = START;
                end

            end
            START: begin
                if (b_tick == 1) begin
                    if ((b_tick_cnt_reg == 7)) begin
                        b_tick_cnt_next = 0;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end

                end
            end
            DATA: begin
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
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
                if (b_tick == 1) begin
                    if ((b_tick_cnt_reg == 15)) begin

                        n_state   = IDLE;
                        done_next = 1'b1;

                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       uart_tx,
    output       tx_busy,
    output       tx_done
);
    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg tx_reg, tx_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg busy_reg, busy_next, done_reg, done_next;
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
            b_tick_cnt_reg  <= 4'h0;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        busy_next = busy_reg;
        done_next = done_reg;
        data_in_buf_next = data_in_buf_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 3'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 0;
                done_next       = 0;
                if (tx_start == 1) begin
                    n_state = START;
                    busy_next = 1'b1;
                    data_in_buf_next = tx_data;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in_buf_reg[0];

                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin

                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 4'h0;
                            n_state = STOP;
                        end else begin
                            b_tick_cnt_next = 4'h0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};

                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;

                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module baud_tick_sampling_divide_3types (
    input clk,
    input rst,
    input [1:0] i_baud_rate,
    output reg b_tick
);
    parameter BAUDRATE0 = 9600;
    parameter BAUDRATE1 = 19200;
    parameter BAUDRATE2 = 115200;
    parameter SAMPLING = 16;
    parameter F_COUNT0 = 100_000_000 / (BAUDRATE0 * SAMPLING);
    parameter F_COUNT1 = 100_000_000 / (BAUDRATE1 * SAMPLING);
    parameter F_COUNT2 = 100_000_000 / (BAUDRATE2 * SAMPLING);

    // reg for counter
    reg [$clog2(F_COUNT0)-1:0] counter_reg;

    reg [$clog2(F_COUNT0)-1:0] counter_target;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == counter_target) begin
                b_tick = 1'b1;
                counter_reg <= 0;
            end else begin
                b_tick = 1'b0;
            end
        end
    end

    always @(*) begin
        case (i_baud_rate)
            2'b00: counter_target = F_COUNT0 - 1;
            2'b01: counter_target = F_COUNT1 - 1;
            2'b10: counter_target = F_COUNT2 - 1;
            2'b11: counter_target = 0;
        endcase
    end

endmodule




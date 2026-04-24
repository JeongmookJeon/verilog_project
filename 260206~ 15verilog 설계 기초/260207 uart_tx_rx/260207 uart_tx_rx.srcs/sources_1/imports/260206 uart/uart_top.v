`timescale 1ns / 1ps

module uart_top (
    input  clk,
    input  rst,
    //input  btn_down,
    input  uart_rx,
    output uart_tx


);

    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data;

    // btn_debounce U_BD_TX_START (
    //     .clk  (clk),
    //     .rst  (rst),
    //     .i_btn(btn_down),
    //     .o_btn(w_tx_start)
    // );

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(w_rx_done),
        .b_tick(w_b_tick),
        .tx_data(w_rx_data),
        .tx_busy(),
        .tx_done(),
        .uart_tx(uart_tx)
    );
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)

    );

    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );
endmodule

module uart_rx (
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


    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= 2'd0;
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

    //next, output
    always @(*) begin

        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                b_tick_cnt_next = 5'd0;
                bit_cnt_next    = 3'd0;
                done_next       = 1'b0;
                    buf_next = 8'd0;
                if (b_tick & !rx) begin
                    n_state  = START;
                end
            end

            START: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
            DATA: begin
                if (b_tick) begin
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
                if (b_tick)
                    if (b_tick_cnt_reg == 15) begin

                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end

            end
        endcase

    end

endmodule




//b_tick 1~7을 DATA 로변경
module uart_tx ( //
    input clk,
    input rst,
    input tx_start,
    input b_tick,
    input [7:0] tx_data,

    output tx_busy,
    output tx_done,
    output uart_tx
);

    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    //state reg
    reg [1:0] c_state, n_state;  //currenttate, nextstate
    reg tx_reg, tx_next;  //outpur sL로 내보내기위해

    //baud tick counter
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    //busy, done
    reg busy_reg, busy_next, done_reg, done_next;

    //data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    //tick 4비트 16카운터
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;



    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    //SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            b_tick_cnt_reg  <= 4'h0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
        end
    end

    //next cl
    always @(*) begin
        n_state          = c_state;
        tx_next          = tx_reg;
        bit_cnt_next     = bit_cnt_reg;
        b_tick_cnt_next  = b_tick_cnt_reg;
        busy_next        = busy_reg;
        done_next        = done_reg;
        data_in_buf_next = data_in_buf_reg;

        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 1'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 1'b0;
                done_next       = 1'b0;
                if (tx_start) begin
                    n_state          = START;
                    busy_next        = 1'b1;
                    data_in_buf_next = tx_data;
                end
            end



            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


            DATA: begin
                tx_next = data_in_buf_reg[0]; //  lsb0번째 비트를 uart_tx핀으로 보낼준비
                if (b_tick) begin
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

                if (b_tick) begin
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



module baud_tick ( // tick을 9600bps를(1초 9600bit)를 *16해서 더 정밀한 검출
    input rst,
    input clk,

    output reg b_tick
);
    parameter BAUDRATE = 9600 * 16;
    parameter F_COUNT = 100_000_000 / (BAUDRATE);
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg = 0;
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

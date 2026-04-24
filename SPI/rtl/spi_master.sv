`timescale 1ns / 1ps

module spi_master (
    input logic clk,
    input logic rst,
    input logic cpol,  // idle 0: low, 1: high
    input logic cpha,  // first sampling, 0: first edge, 1: second edge
    input logic [7:0] clk_div,
    input logic [7:0] tx_data,
    input logic start,
    input logic miso,
    output logic [7:0] rx_data,
    output logic done,
    output logic busy,
    output logic sclk,
    output logic mosi,
    output logic cs_n  // cs
);

    typedef enum bit [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;
    logic [7:0] div_cnt;
    logic half_tick;  // sclk (master -> slave)
    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [3:0] bit_cnt;
    logic step, sclk_r;

    assign sclk = sclk_r;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1'b1;
                    half_tick <= 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            cs_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            step         <= 1'b0;
            rx_data      <= 0;
            sclk_r       <= cpol;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi         <= 1'bz;
                    cs_n         <= 1'b1;
                    sclk_r       <= cpol;
                    rx_shift_reg <= 0;
                    if (start) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 0;
                        step         <= 1'b0;
                        busy         <= 1'b1;
                        cs_n         <= 1'b0;
                        state        <= START;
                    end
                end
                START: begin
                    if (!cpha) begin
                        mosi <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        // end else begin
                        //     rx_shift_reg <= {
                        //         rx_shift_reg[6:0], miso
                        //     };  // receive from lsb
                    end
                    state <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 1'b0) begin
                            // DATA_LOW: receive
                            step <= 1'b1;
                            if (!cpha) begin
                                if (bit_cnt <= 7) begin
                                    rx_shift_reg <= {
                                        rx_shift_reg[6:0], miso
                                    };  // receive from lsb
                                    bit_cnt <= bit_cnt + 1'b1;
                                end else begin  // bit_cnt == 7
                                    state   <= STOP;
                                    rx_data <= rx_shift_reg;
                                    bit_cnt <= 0;
                                end
                            end else begin
                                // if (bit_cnt < 8) begin
                                mosi <= tx_shift_reg[7];  // send from msb
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                //bit_cnt <= bit_cnt + 1'b1;
                                // end else begin  // bit_cnt == 7
                                //     state   <= STOP;
                                //     rx_data <= rx_shift_reg;
                                //     bit_cnt <= 0;
                                // end
                            end
                        end else begin
                            // DATA_HIGH: send
                            step <= 1'b0;
                            if (!cpha) begin
                                mosi <= tx_shift_reg[7];  // send from msb
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end else begin
                                if (bit_cnt <= 7) begin
                                    rx_shift_reg <= {
                                        rx_shift_reg[6:0], miso
                                    };  // receive from lsb
                                    bit_cnt <= bit_cnt + 1'b1;
                                end else begin
                                    state   <= STOP;
                                    // rx_data <= {rx_shift_reg[6:0], miso};
                                    rx_data <= rx_shift_reg;
                                    bit_cnt <= 0;
                                end
                            end
                        end
                    end
                end

                STOP: begin
                    sclk_r <= 1'b0;
                    cs_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'bz;
                    state  <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

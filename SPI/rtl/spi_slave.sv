`timescale 1ns / 1ps

// cpol 0, cpha 0
module spi_slave (
    input clk,
    input rst,
    input sclk,
    input cs_n,
    input mosi,
    input [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic miso,
    output logic done,
    output logic busy
);

    typedef enum bit [2:0] {
        IDLE,
        START,
        DATA_TX,
        DATA_RX,
        STOP
    } spi_state_e;

    spi_state_e c_state, n_state;

    logic [7:0] rx_data_next;
    logic [7:0] tx_shift_reg, tx_shift_next, rx_shift_reg, rx_shift_next;
    logic [3:0] bit_cnt_reg, bit_cnt_next;
    logic miso_next;
    logic done_next, busy_next;

    logic sclk_pedge, sclk_nedge;

    edge_detector U_EDGE_DETECTOR (
        .clk(clk),
        .rst(rst),
        .data_in(sclk),
        .pedge(sclk_pedge),
        .nedge(sclk_nedge)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            rx_data      <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            miso         <= 0;
            done         <= 0;
            busy         <= 0;
            bit_cnt_reg  <= 0;
        end else begin
            c_state      <= n_state;
            rx_data      <= rx_data_next;
            tx_shift_reg <= tx_shift_next;
            rx_shift_reg <= rx_shift_next;
            miso         <= miso_next;
            done         <= done_next;
            busy         <= busy_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    always_comb begin
        n_state = c_state;
        rx_data_next = rx_data;
        tx_shift_next = tx_shift_reg;
        rx_shift_next = rx_shift_reg;
        miso_next = miso;
        done_next = done;
        busy_next = busy;
        bit_cnt_next = bit_cnt_reg;

        case (c_state)
            IDLE: begin
                miso_next = 1'b0;
                done_next = 1'b0;
                busy_next = 1'b0;
                if (!cs_n) begin
                    tx_shift_next = tx_data;
                    rx_shift_next = 0;
                    bit_cnt_next = 0;
                    busy_next = 1'b1;
                    n_state = START;
                end
            end
            START: begin  // adapted to SPI master tx timing...
                    miso_next = tx_shift_reg[7];
                if (sclk_pedge) begin
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    n_state = DATA_RX;
                end
            end
            DATA_RX: begin
                    rx_shift_next = {rx_shift_reg[6:0], mosi};
                    n_state = DATA_TX;
            end
            DATA_TX: begin
                if (sclk_nedge) begin
                    miso_next = tx_shift_reg[7];
                end
                if (sclk_pedge) begin
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    n_state = DATA_RX;
                    if (bit_cnt_reg == 3'd7) begin
                        bit_cnt_next = 0;
                        n_state = STOP;
                    end
                    bit_cnt_next++;
                end
            end
            STOP: begin
                // if (sclk_nedge) begin
                rx_data_next = rx_shift_reg;
                done_next = 1'b1;
                busy_next = 1'b0;
                n_state = IDLE;
                // end
            end
        endcase
    end

endmodule


module edge_detector (
    input        clk,
    input        rst,
    input        data_in,
    output logic pedge,
    output logic nedge
);
    logic ff;  //1;//, ff2;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ff <= 1'd0;
        end else begin
            ff <= data_in;
            // ff <= {ff[0], data_in};
        end
    end

    assign pedge = ~ff & data_in;  // 0 -> 1
    assign nedge = ff & ~data_in;  // 1 -> 0

endmodule

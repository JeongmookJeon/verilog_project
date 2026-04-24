`timescale 1ns/1ps

module spi_slave #(
    parameter CPOL = 0,
    parameter CPHA = 0
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       SCLK,
    input  logic       MOSI,
    output logic       MISO,
    input  logic       CS_n,
    input  logic       tx_updata,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       busy
);
    localparam [0:0] RECV_LV = ( (~CPOL)&(~CPHA) ) | ( CPOL&CPHA ); // 00 11

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        SEND,
        RECEIVE,
        WAIT
    } spi_slave_e;

    spi_slave_e state;
    logic [2:0] bit_cnt;
    logic [7:0] tx_shift_reg, rx_shift_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            MISO         <= 0;
            state        <= IDLE;
            bit_cnt      <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_done      <= 1'b0;
            busy         <= 1'b0;
        end
        else begin
            case(state)
                IDLE   : begin
                    rx_done      <= 1'b0;
                    busy         <= 1'b0;
                    bit_cnt      <= 0;
                    rx_shift_reg <= 0;
                    if (!CS_n && (SCLK == (~RECV_LV))) begin
                        state <= SEND;
                        busy  <= 1'b1;
                    end
                    else begin
                        if (tx_updata) tx_shift_reg <= tx_data;
                    end
                end
                SEND   : begin
                    MISO <= tx_shift_reg[7];
                    if (SCLK == RECV_LV) state <= RECEIVE;
                end
                RECEIVE: begin
                    rx_shift_reg <= { rx_shift_reg[6:0], MOSI };
                    state        <= WAIT;
                end
                WAIT   : begin
                    if (SCLK == (~RECV_LV)) begin
                        if (bit_cnt == 7) begin
                            rx_done <= 1'b1;
                            busy    <= 1'b0;
                            state   <= IDLE;
                        end
                        else begin
                            tx_shift_reg <= { tx_shift_reg[6:0], 1'b0 };
                            bit_cnt      <= bit_cnt + 1;
                            state        <= SEND;
                        end
                    end
                end
            endcase
        end
    end

    assign rx_data = rx_shift_reg;

endmodule

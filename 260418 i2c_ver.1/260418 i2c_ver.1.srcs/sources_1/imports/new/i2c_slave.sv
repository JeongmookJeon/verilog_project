`timescale 1ns / 1ps

module I2C_SLAVE (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,
    // internal i2c port
    input  logic       scl,
    inout  logic       sda
);

    logic sda_o, sda_i;
    logic [3:0] fnd_digit;
    logic [7:0] fnd_data;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave u_i2c_slave (.*);

    fnd_controller u_fnd_controller (
        .*,
        .fnd_in_data({6'b0,rx_data}),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule

module i2c_slave #(
    parameter logic [6:0] SLAVE_ADDR = 7'h5A
) (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,
    // internal i2c port
    input  logic       scl,
    input  logic       sda_i,
    output logic       sda_o
);

    // edge detector
    logic [2:0] scl_sync, sda_sync;
    logic scl_rise, scl_fall, scl_high;
    logic sda_rise, sda_fall;
    logic start_signal, stop_signal;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            scl_sync <= 3'b111;
            sda_sync <= 3'b111;
        end else begin
            scl_sync <= {scl_sync[1:0], scl};
            sda_sync <= {sda_sync[1:0], sda_i};
        end
    end

    assign scl_rise = (scl_sync[2:1] == 2'b01);
    assign scl_fall = (scl_sync[2:1] == 2'b10);
    assign scl_high = (scl_sync[1] == 1'b1);

    assign sda_fall = (sda_sync[2:1] == 2'b10);
    assign sda_rise = (sda_sync[2:1] == 2'b01);

    assign start_signal = (scl_sync[1] == 1'b1) && (sda_sync[2:1] == 2'b10);
    assign stop_signal = (scl_sync[1] == 1'b1) && (sda_sync[2:1] == 2'b01);

    // FSM
    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        ADDR_ACK,
        W_DATA,
        R_DATA,
        W_ACK,
        R_ACK,
        STOP
    } i2c_state_e;
    i2c_state_e state;

    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [3:0] bit_cnt;

    assign busy = (state != IDLE);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            sda_o <= 1;
            done <= 0;
            bit_cnt <= 0;
        end else if (start_signal) begin
            state   <= ADDR;
            bit_cnt <= 0;
            sda_o   <= 1;
        end else if (stop_signal) begin
            state <= IDLE;
            sda_o <= 1;
        end else begin
            done <= 0;
            case (state)
                IDLE: sda_o <= 1;

                ADDR: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_sync[1]};
                        if (bit_cnt == 7) begin
                            state   <= ADDR_ACK;
                            bit_cnt <= 0;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                // ADDR_ACK: begin
                //     if (rx_shift_reg[7:1] == SLAVE_ADDR) begin
                //         if (scl_fall && bit_cnt == 0) begin
                //             sda_o   <= 0;
                //             bit_cnt <= 1;
                //         end else if (scl_fall && bit_cnt == 1) begin
                //             state <= (rx_shift_reg[0]) ? R_DATA : W_DATA;
                //             if (rx_shift_reg[0]) tx_shift_reg <= tx_data;
                //             sda_o   <= 1;
                //             bit_cnt <= 0;
                //         end
                //     end else begin
                //         if (scl_rise) state <= IDLE;
                //     end
                // end

                ADDR_ACK: begin
                    if (rx_shift_reg[7:1] == SLAVE_ADDR) begin
                        if (scl_fall && bit_cnt == 0) begin
                            sda_o   <= 0;
                            bit_cnt <= 1;
                        end else if (scl_fall && bit_cnt == 1) begin
                            if (rx_shift_reg[0]) begin  // READ
                                state <= R_DATA;
                                // [수정 핵심] Master가 첫 클럭을 띄우기 전에 MSB를 미리 출력!
                                sda_o <= tx_data[7];
                                tx_shift_reg <= {tx_data[6:0], 1'b0};
                                bit_cnt <= 1;
                            end else begin  // WRITE
                                state   <= W_DATA;
                                sda_o   <= 1;
                                bit_cnt <= 0;
                            end
                        end
                    end
                end

                W_DATA: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_sync[1]};
                        if (bit_cnt == 7) begin
                            state   <= W_ACK;
                            bit_cnt <= 0;
                            rx_data <= {rx_shift_reg[6:0], sda_sync[1]};
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                W_ACK: begin
                    if (scl_fall && bit_cnt == 0) begin
                        sda_o   <= 0;
                        bit_cnt <= 1;
                    end else if (scl_fall && bit_cnt == 1) begin
                        state   <= W_DATA;
                        sda_o   <= 1;
                        done    <= 1;
                        bit_cnt <= 0;
                    end
                end

                R_DATA: begin
                    if (scl_fall) begin
                        if (bit_cnt == 8) begin
                            state   <= R_ACK;
                            bit_cnt <= 0;
                            sda_o   <= 1;
                        end else begin
                            sda_o        <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_cnt      <= bit_cnt + 1;
                        end
                    end
                end

                R_ACK: begin
                    if (scl_rise) begin
                        bit_cnt <= (sda_sync[1] == 1'b0) ? 4'd1 : 4'd2;
                    end
                    if (scl_fall) begin
                        if (bit_cnt == 4'd1) begin
                            state        <= R_DATA;
                            sda_o        <= tx_data[7];
                            tx_shift_reg <= {tx_data[6:0], 1'b0};
                            bit_cnt      <= 1;
                        end else begin
                            state <= IDLE;
                            done <= 1;
                            bit_cnt <= 0;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

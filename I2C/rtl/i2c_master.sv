`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns / 1ps

module I2C_Master (  // Top I2C Master
    input  logic       clk,
    input  logic       rst,
    // command port
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    // internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    // external port
    output logic       scl,
    inout              sda
);
    logic sda_o, sda_i;
    assign sda_i = sda;
    assign sda   = (sda_o) ? 1'bz : 1'b0;  // GND

    i2c_master u_i2c_master (.*);


endmodule


module i2c_master (
    input  logic       clk,
    input  logic       rst,
    // command port
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    // internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    // external port
    output logic       scl,
    output logic       sda_o,
    input  logic       sda_i
);


    typedef enum bit [2:0] {
        IDLE,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e state;

    localparam FREQ = ((100_000_000) / (100_000 * 4));

    logic [$clog2(FREQ)-1:0] div_cnt;
    logic qtr_tick;
    logic scl_r, sda_r;
    logic [1:0] step;
    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic is_read;  // flag
    logic ack_in_r;
    logic [2:0] bit_cnt;


    assign scl   = scl_r;
    assign sda_o = sda_r;

    assign busy  = (state != IDLE);  //(state == IDLE) ? 1'b0 : 1'b1;

    // qtr_tick generator
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == FREQ - 1) begin  // SCL = 100Khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1'b1;
                qtr_tick <= 1'b0;
            end
        end
    end

    // state machine
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            rx_data <= 0;
            done    <= 1'b0;
            ack_out <= 1'b1;  // 1'bx?
            // busy    <= 1'b0;
            scl_r   <= 1'b1;  // 1'bx?
            sda_r   <= 1'b1;  // 1'bx?
            step    <= 2'd0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            is_read <= 1'b0;
            bit_cnt <= 0;
            ack_in_r <= 1;  // NACK in default
        end else begin
            case (state)
                IDLE: begin
				//`uvm_info("I2C_Master", $sformatf("[%0t] Now IDLE", $time), UVM_DEBUG)
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    done <= 1'b0;
                    // busy  <= 1'b0;
                    if (cmd_start) begin
				`uvm_info("I2C_Master", $sformatf("[%0t] IDLE -> START", $time), UVM_DEBUG)
                        state <= START;
                        step  <= 2'd0;
                        // busy  <= 1'b1;
                    end
                end
                START: begin
                    if (qtr_tick) begin
				`uvm_info("I2C_Master", $sformatf("[%0t] Now START, qtr_tick(step)=%0d", $time, step), UVM_DEBUG)
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b1;  // HIGH in idle
                                sda_r <= 1'b1;  // HIGH in idle
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                // scl_r <= 1'b1;
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                // scl_r <= 1'b1;
                                // sda_r <= 1'b0;
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                // sda_r <= 1'b0;
                                step  <= 2'd0;
                                done <= 1'b1;
                                state <= WAIT_CMD;
				`uvm_info("I2C_Master", $sformatf("[%0t] START -> WAIT_CMD", $time), UVM_DEBUG)
                            end
                        endcase
                    end
                end
                WAIT_CMD: begin
				`uvm_info("I2C_Master", $sformatf("[%0t] Now WAIT_CMD", $time), UVM_DEBUG)
                    done <= 1'b0;
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt <= 0;
                        is_read <= 1'b0;
                        state <= DATA;
				`uvm_info("I2C_Master", $sformatf("[%0t] WAIT_CMD -> DATA, WR_mode, tx_data=0x%0h", $time, tx_data), UVM_DEBUG)
                    end else if (cmd_read) begin
                        rx_shift_reg <= 8'h0;
                        bit_cnt <= 0;
                        is_read <= 1'b1;
                        ack_in_r <= ack_in;
                        state <= DATA;
				`uvm_info("I2C_Master", $sformatf("[%0t] WAIT_CMD -> DATA, RD_mode, ack_in=%0b", $time, ack_in), UVM_DEBUG)
                    end else if (cmd_stop) begin
                        state <= STOP;
				`uvm_info("I2C_Master", $sformatf("[%0t] WAIT_CMD -> STOP", $time), UVM_DEBUG)
                    end else if (cmd_start) begin
                        state <= START;
				`uvm_info("I2C_Master", $sformatf("[%0t] WAIT_CMD -> START", $time), UVM_DEBUG)
                    end
                end
                DATA: begin
                    if (qtr_tick) begin
						if (is_read) begin
							`uvm_info("I2C_Master", $sformatf("[%0t] Now DATA(READ), qtr_tick(step)=%0d, bit_cnt=%0d, rx_data=0x%0h, rx_shift_reg=0x%0h", $time, step, bit_cnt, rx_data, rx_shift_reg), UVM_DEBUG)
						end else begin
							`uvm_info("I2C_Master", $sformatf("[%0t] Now DATA(WRITE), qtr_tick(step)=%0d, bit_cnt=%0d, tx_data=0x%0h, tx_shift_reg=0x%0h", $time, step, bit_cnt, tx_data, tx_shift_reg), UVM_DEBUG)
						end
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];  // default HIGH
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (is_read) begin
                                    rx_shift_reg <= {rx_shift_reg, sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;
                                if (bit_cnt == 7) begin
                                    bit_cnt <= 0;
                                    state <= DATA_ACK;
				`uvm_info("I2C_Master", $sformatf("[%0t] DATA -> DATA_ACK", $time), UVM_DEBUG)
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1;
                                end
                            end
                        endcase
                    end
                end
                DATA_ACK: begin
                    if (qtr_tick) begin
				`uvm_info("I2C_Master", $sformatf("[%0t] Now DATA_ACK, qtr_tick(step)=%0d", $time, step), UVM_DEBUG)
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                if (is_read) begin
                                    sda_r <= ack_in_r;
                                end else begin
                                    sda_r <= 1'b1;  // sda input setting
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (!is_read) begin  // receive ACK
                                    ack_out <= sda_i;
                                end
                                if (is_read) begin
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
				`uvm_info("I2C_Master", $sformatf("[%0t] DATA_ACK -> WAIT_CMD, is_read=%b, ack_out=%b", $time, is_read, ack_out), UVM_DEBUG)
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
				`uvm_info("I2C_Master", $sformatf("[%0t] Now STOP, qtr_tick(step)=%0d", $time, step), UVM_DEBUG)
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;  // HIGH in idle
                                sda_r <= 1'b0;  // HIGH in idle
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                // sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                // scl_r <= 1'b1;
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                // scl_r <= 1'b1;
                                // sda_r <= 1'b1;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
				`uvm_info("I2C_Master", $sformatf("[%0t] STOP -> IDLE", $time), UVM_DEBUG)
                            end
                        endcase
                    end
                end
                // default: begin

                // end
            endcase
        end
    end

endmodule

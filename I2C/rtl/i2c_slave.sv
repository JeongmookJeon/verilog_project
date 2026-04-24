`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns / 1ps

module i2c_slave (
    input              clk,
    input              rst,
    input        [7:0] tx_data,
    input              scl,      // inout actually?
    inout              sda,
    output logic [7:0] rx_data,
    output logic       sending,
    output logic       done
);
    localparam SLA = 7'h12;

    typedef enum bit [2:0] {
        IDLE,
        START,
        START_ACK,
        DATA,
        // DATA_RX,
        // DATA_TX,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e c_state, n_state;

    logic [7:0] tx_shift_reg, tx_shift_next, rx_shift_reg, rx_shift_next;
    logic is_read;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [2:0] stop_cnt_reg, stop_cnt_next;
    logic p_sda, n_sda;
    logic p_scl, n_scl;
    logic phase_reg, phase_next;
    logic sda_next, sda_o;
    logic is_ack_reg, is_ack_next;
    logic done_next;

    assign sda = (sda_o) ? 1'bz : 1'b0;
    assign sending = (is_read && (c_state == DATA)) ? 1'b1 : 1'b0;

    edge_detector U_EDGE_DETECTOR_SDA (
        .clk(clk),
        .rst(rst),
        .data_in(sda),
        .pedge(p_sda),
        .nedge(n_sda)
    );

    edge_detector U_EDGE_DETECTOR_SCL (
        .clk(clk),
        .rst(rst),
        .data_in(scl),
        .pedge(p_scl),
        .nedge(n_scl)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt_reg  <= 0;
            stop_cnt_reg  <= 0;
            phase_reg    <= 0;
            sda_o        <= 1'b1;  // HIGH in default
            is_ack_reg   <= 0;
            done         <= 0;
        end else begin
            c_state      <= n_state;
            tx_shift_reg <= tx_shift_next;
            rx_shift_reg <= rx_shift_next;
            bit_cnt_reg  <= bit_cnt_next;
            stop_cnt_reg  <= stop_cnt_next;
            phase_reg    <= phase_next;
            sda_o        <= sda_next;
            is_ack_reg   <= is_ack_next;
            done         <= done_next;
        end
    end

    always_comb begin
        n_state = c_state;
        tx_shift_next = tx_shift_reg;
        rx_shift_next = rx_shift_reg;
        bit_cnt_next = bit_cnt_reg;
        stop_cnt_next = stop_cnt_reg;
        phase_next = phase_reg;
        sda_next = sda_o;
        is_ack_next = is_ack_reg;
        done_next = done;

        case (c_state)
            IDLE: begin
                tx_shift_next = 0;
                rx_shift_next = 0;
                bit_cnt_next = 0;
                phase_next = 1'b0;
                sda_next = 1'b1;  // HIGH in default
				//`uvm_info("I2C_Slave", $sformatf("[%0t] Now IDLE", $time), UVM_DEBUG)
                if (scl && n_sda) begin
                    n_state   = START;
                    done_next = 0;
					`uvm_info("I2C_Slave", $sformatf("[%0t] IDLE -> START", $time), UVM_DEBUG)
                end
            end
            START: begin
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now START, bit_cnt_reg=%0d, rx_r=0x%0h, rx_n=0x%0h", $time, bit_cnt_reg, rx_shift_reg, rx_shift_next), UVM_DEBUG)
                    done_next = 0;
                sda_next = 1'b1;
                if (p_scl) begin
                    rx_shift_next = {rx_shift_reg, sda};
                    if (bit_cnt_reg == 7) begin
                        bit_cnt_next = 0;

                        if (rx_shift_next[7:1] == SLA) begin
						`uvm_info("I2C_Slave", $sformatf("[%0t] START -> START_ACK", $time), UVM_DEBUG)
                            // n_state = DATA;
                            n_state = START_ACK;
                            is_read = rx_shift_next[0];

							/*
                            if (is_read) begin
                                tx_shift_next = tx_data;
                                // sda_next = 1'b1;  // HIGH in default
                            end else begin
							*/
							if (!is_read) begin
                                sda_next = 1'b0;  // ACK
                                // sda_next = 1'bz;
                            end
                        end else begin
						`uvm_info("I2C_Slave", $sformatf("[%0t] START -> IDLE", $time), UVM_DEBUG)
                            n_state = IDLE;
                        end
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                    end
                end
            end
            START_ACK: begin
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now START_ACK", $time), UVM_DEBUG)
                    done_next = 0;
                sda_next = 1'b0;  // ACK LOW
                if (n_scl) begin
                    bit_cnt_next = bit_cnt_reg + 1'b1;
                    if (bit_cnt_reg == 1) begin
						//`uvm_info("I2C_Slave", $sformatf("[%0t] START_ACK -> DATA : is_read=%0b, tx_data=0x%0h", $time, is_read, tx_data), UVM_DEBUG)
                        n_state = DATA;
                        rx_shift_next = 0;
                        bit_cnt_next = 0;
                        if (is_read) begin
                            sda_next = tx_data[7];
                            tx_shift_next = {tx_data[6:0], 1'b0};
                            //sda_next = tx_shift_reg[7];
                            //tx_shift_next = {tx_shift_reg[6:0], 1'b0};
							`uvm_info("I2C_Slave", $sformatf("[%0t] START_ACK -> DATA : is_read=%0b, tx_data=0x%0h, tx_r=0x%0h, tx_n=0x%0h", $time, is_read, tx_data, tx_shift_reg, tx_shift_next), UVM_DEBUG)
                        end else begin
                            sda_next = 1'd1;  // HIGH in default
                        end
                    end
                end
            end
            // WAIT_CMD: begin

            // end
            DATA: begin
                    done_next = 0;
                if (is_read) begin
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now DATA, bit_cnt_reg=%0d, tx_r=0x%0h, tx_n=0x%0h, is_read=%0b", $time, bit_cnt_reg, tx_shift_reg, tx_shift_next, is_read), UVM_DEBUG)
                    if (n_scl) begin
                        // send data at SCL LOW
                        sda_next = tx_shift_reg[7];
                        tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                        // if (phase_reg) begin

                        // end else begin
                        //     phase_next = 1'b1;
                        // end
                        if (bit_cnt_reg == 7) begin
                            sda_next = 1'b1;
                            bit_cnt_next = 0;
                            n_state = DATA_ACK;
						`uvm_info("I2C_Slave", $sformatf("[%0t] DATA -> DATA_ACK", $time), UVM_DEBUG)
                            // if (!is_read) begin
                            //     sda_next = 1'b0;  // ACK
                            // end
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end
                end else begin
                    if (p_scl) begin
                        // receive data at SCL HIGH
                        rx_shift_next = {rx_shift_reg, sda};
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now DATA, bit_cnt_reg=%0d, rx_r=0x%0h, rx_n=0x%0h, is_read=%0b", $time, bit_cnt_reg, rx_shift_reg, rx_shift_next, is_read), UVM_DEBUG)
                        if (bit_cnt_reg == 7) begin
                            sda_next = 1'b1;
                            bit_cnt_next = 0;
                            n_state = DATA_ACK;
						`uvm_info("I2C_Slave", $sformatf("[%0t] DATA -> DATA_ACK", $time), UVM_DEBUG)
                            // if (!is_read) begin
                            //     sda_next = 1'b0;  // ACK
                            // end
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end
                end

            end
            DATA_ACK: begin
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now DATA_ACK, rx_shift_reg=0x%0h, rx_shift_next=0x%0h", $time, rx_shift_reg, rx_shift_next), UVM_DEBUG)
                //done_next = 1'b1;
                if (is_read) begin
                    tx_shift_next = tx_data;
                    if (p_scl) begin
                        bit_cnt_next = bit_cnt_reg + 1;
                        // receive ACK(0), Halt if NACK(1)
                        // if (!sda) begin
                        // ACK LOW
                        // tx_shift_next = tx_data;
                        // n_state = DATA;
                        // end else begin
                        if (!sda) begin
                            is_ack_next = 1;
                        end
                    end else if (n_scl) begin
                        if (bit_cnt_reg == 1) begin
                            bit_cnt_next = 0;
                            is_ack_next  = 0;
                            if (is_ack_reg) begin
                                n_state = DATA;
						`uvm_info("I2C_Slave", $sformatf("[%0t] DATA_ACK -> DATA", $time), UVM_DEBUG)
                                sda_next = tx_shift_reg[7];
                                tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                                // bit_cnt_next = bit_cnt_reg + 1'b1;
                            end else begin
								stop_cnt_next = 0;
                                n_state = STOP;
						`uvm_info("I2C_Slave", $sformatf("[%0t] DATA_ACK -> STOP", $time), UVM_DEBUG)
                            end
                            	done_next = 1'b1;
                        end
                    end
                end else if (!is_read && n_scl) begin
                    // send ACK
                    sda_next = 1'b0;  // ACK LOW
                    rx_data = rx_shift_reg;
                    bit_cnt_next = bit_cnt_reg + 1;
                    if (bit_cnt_reg == 1) begin
                        sda_next = 1'b1;  // HIGH in default
                        bit_cnt_next = 0;
                        rx_shift_next = 0;
						stop_cnt_next = 0;
                        n_state = STOP;
                        done_next = 1'b1;
						`uvm_info("I2C_Slave", $sformatf("[%0t] DATA_ACK -> STOP", $time), UVM_DEBUG)
                    end
                end
            end
            STOP: begin
					`uvm_info("I2C_Slave", $sformatf("[%0t] Now STOP", $time), UVM_DEBUG)
                done_next = 1'b1;
                if (p_sda && scl) begin
                    n_state = IDLE;
						`uvm_info("I2C_Slave", $sformatf("[%0t] STOP -> IDLE", $time), UVM_DEBUG)
                end else if (p_scl) begin
				
				// end else if (p_sda && !scl) begin

                    stop_cnt_next = stop_cnt_reg + 1;
                    if (stop_cnt_reg == 3) begin
                    // if (stop_cnt_reg == 3) begin

        //        end else if ((p_scl)&&(stop_cnt_reg == 2)) begin	// same timing withMASTER DATA(n-1) -> DATA(n) in continious data transaction
				
				// end else if (p_sda && !scl) begin
                        n_state = DATA;
						stop_cnt_next = 0;
						bit_cnt_next = 0;
						`uvm_info("I2C_Slave", $sformatf("[%0t] STOP -> DATA", $time), UVM_DEBUG)
					end
						if (!is_read) begin	// need to get sda data (timing problem)
							// receive data at SCL HIGH
							rx_shift_next = {rx_shift_reg, sda};
							`uvm_info("I2C_Slave", $sformatf("[%0t] receive data in STOP, bit_cnt_reg=%0d, rx_r=0x%0h, rx_n=0x%0h, is_read=%0b", $time, bit_cnt_reg, rx_shift_reg, rx_shift_next, is_read), UVM_DEBUG)
                   
                            bit_cnt_next = bit_cnt_reg + 1'b1;

						end
				end	
				
				// if (n_scl && is_read) begin	
				// end
            end
            default: begin
                n_state = IDLE;
            end
        endcase
    end
endmodule

module edge_detector (
    input clk,
    input rst,
    input data_in,
    output logic pedge,
    output logic nedge
);
    logic ff;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ff <= 1'b0;
        end else begin
            ff <= data_in;
        end
    end
    assign pedge = (!ff) & data_in;  // 0 -> 1
    assign nedge = ff & (!data_in);  // 1 -> 0

endmodule

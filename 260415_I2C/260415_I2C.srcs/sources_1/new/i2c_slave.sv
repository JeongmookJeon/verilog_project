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

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave u_i2c_slave (.*);

endmodule

module i2c_slave #(
    parameter logic [6:0] SLAVE_ADDR = 7'h5A,
    parameter logic [3:0] MAX_BYTES  = 4'd4  // ★ 수신 제한 바이트 설정 (4바이트 후 NACK)
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

    // edge detector & synchronizer
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

    // I2C Start & Stop Condition
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
        R_ACK
    } i2c_state_e;

    i2c_state_e state;

    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [3:0] bit_cnt;
    logic [3:0] byte_cnt; // ★ 데이터 수신 횟수를 세는 카운터 추가

    assign busy = (state != IDLE);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            sda_o    <= 1;
            done     <= 0;
            bit_cnt  <= 0;
            byte_cnt <= 0;
            rx_data  <= 0;
        end else if (start_signal) begin
            state    <= ADDR;
            bit_cnt  <= 0;
            byte_cnt <= 0; // 통신 시작 시 카운터 초기화
            sda_o    <= 1;
        end else if (stop_signal) begin
            state <= IDLE;
            sda_o <= 1;
        end else begin
            done <= 0;

            case (state)
                IDLE: sda_o <= 1;

                // [1] 주소 수신
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

                // [2] 주소 일치 여부 확인 및 ACK 출력
                ADDR_ACK: begin
                    if (rx_shift_reg[7:1] == SLAVE_ADDR) begin
                        if (scl_fall && bit_cnt == 0) begin
                            sda_o   <= 0;
                            bit_cnt <= 1;
                        end else if (scl_fall && bit_cnt == 1) begin
                            if (rx_shift_reg[0]) begin
                                // Read 모드: 첫 비트 즉시 선출력 (Setup Time 확보)
                                state        <= R_DATA;
                                tx_shift_reg <= {tx_data[6:0], 1'b0};
                                sda_o        <= tx_data[7];
                                bit_cnt      <= 1;  // 이미 1비트 출력함
                            end else begin
                                // Write 모드: 정상 진행
                                state   <= W_DATA;
                                sda_o   <= 1;
                                bit_cnt <= 0;
                            end
                        end
                    end else begin
                        if (scl_rise) state <= IDLE;
                    end
                end

                // [3] Master -> Slave 데이터 수신
                W_DATA: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_sync[1]};
                        if (bit_cnt == 7) begin
                            state <= W_ACK;
                            bit_cnt <= 0;
                            byte_cnt <= byte_cnt + 1; // ★ 1바이트 수신 완료
                            rx_data <= {rx_shift_reg[6:0], sda_sync[1]};
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                // [4] 데이터 수신 응답 (★ NACK 한도 로직 포함)
                W_ACK: begin
                    if (scl_fall && bit_cnt == 0) begin
                        // ★ 설정한 바이트 수(4)에 도달하면 NACK(1), 아니면 ACK(0)
                        if (byte_cnt == MAX_BYTES) begin
                            sda_o <= 1;  // 수신 거부 (NACK)
                        end else begin
                            sda_o <= 0;  // 정상 수신 (ACK)
                        end
                        bit_cnt <= 1;
                    end else if (scl_fall && bit_cnt == 1) begin
                        // NACK를 띄웠다면 통신 강제 종료 (IDLE)
                        if (byte_cnt == MAX_BYTES) begin
                            state <= IDLE;
                        end else begin
                            state <= W_DATA;  // 계속 수신
                        end
                        sda_o   <= 1;
                        done    <= 1;
                        bit_cnt <= 0;
                    end
                end

                // [5] Slave -> Master 데이터 송신
                R_DATA: begin
                    if (scl_fall) begin
                        if (bit_cnt == 7) begin
                            state <= R_ACK;
                            bit_cnt <= 0;
                            sda_o   <= 1; // Master가 응답할 수 있도록 버스 비우기
                        end else begin
                            sda_o        <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_cnt      <= bit_cnt + 1;
                        end
                    end
                end

                // [6] 데이터 송신 후 Master의 응답 확인 (꼼수 제거, 즉결 처분)
                R_ACK: begin
                    // 상승 에지에서 마스터의 마음을 바로 읽고 
                    // 기다림 없이 상태를 전이시킵니다!
                    if (scl_rise) begin
                        if (sda_sync[1] == 1'b0) begin
                            // Master가 0(ACK)을 보냄 -> 다음 데이터 송신
                            state        <= R_DATA;
                            tx_shift_reg <= tx_data;
                            bit_cnt      <= 0;
                        end else begin
                            // Master가 1(NACK)을 보냄 -> 송신 종료
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

`timescale 1ns / 1ps

module I2C_MASTER (
    input  logic       clk,
    input  logic       reset,
    //command port
    input  logic       cmd_write,
    input  logic       cmd_start,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    //internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    output logic       scl,
    inout  logic       sda         //in out port
);
    logic sda_o, sda_i;


    //tri state buffer
    assign sda_i = sda; //sda_i는 내부 입력 port, sda는 외부에서 오는 신호
    assign sda = sda_o ? 1'bz : 1'b0;  //tri state buffer

    i2c_master U_i2c_master (
        .*,
        .sda_o(sda_o),
        .sda_i(sda_i)
    );

endmodule

module i2c_master (
    input  logic       clk,
    input  logic       reset,
    //command port
    input  logic       cmd_write,
    input  logic       cmd_start,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    //internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    output logic       scl,
    output logic       sda_o,
    input  logic       sda_i
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e       state;
    logic       [7:0] div_cnt;
    logic             qtr_tick;
    logic scl_r, sda_r;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       is_read;
    logic       ack_in_r;


    assign scl   = scl_r;
    assign sda_o = sda_r;
    // IDEL이 아니면 '1' (조건연산자)
    assign busy  = (state != IDLE);

    // 100Khz tick = qtr_tick
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 250 - 1) begin  // scl(clk) : 100Khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            // I2C에 스펙에 따르면 처음에 1로 나가야함. 
            scl_r        <= 1'b1;
            // I2C에 스펙에 따르면 처음에 1로 나가야함. 
            sda_r        <= 1'b1;
            // busy         <= 1'b0;
            step         <= 0;
            done         <= 1'b0;
            tx_shift_reg <= 8'b0;
            rx_shift_reg <= 8'b0;
            is_read      <= 1'b0;
            bit_cnt      <= 0;
            ack_in_r     <= 1'b1;  //초기 nack상태
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    // busy  <= 1'b0;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 0;
                        //busy  <= 1'b1;
                    end
                end
                // wave form 참고 // qtr_tick 당 400Khz
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;// tb의 wait(done)이야!!!
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                //[ADDRESS frame] rw포함해서 8bit를 전부 보낸다.
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        //write 신호일 때
                        tx_shift_reg <= tx_data;  //저장해(address +r/w)
                        bit_cnt <= 0;
                        is_read <= 1'b0;  //read신호가 아니야 flag 역할
                        state <= DATA;
                    end else if (cmd_read) begin
                        //read 신호일 때
                        rx_shift_reg <= 0;
                        bit_cnt <= 0;
                        is_read <= 1'b1;  //read신호야 flag 역할
                        ack_in_r <= ack_in; // slave의 data를 계속 받을건지?
                        state <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end

                end
                //[data frame]data 송수신 구간.(보내거나(write), sampling 하거나(read))
                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                //read가 아닐때(write라는 뜻!!!!) MSB를 내보내겠다. 
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (is_read) begin
                                    //수신 받음.(sampling)
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin //read가 아니면 shift시키겠다.
                                    //shift, 다음 bit준비. 
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;
                                if (bit_cnt == 7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt = bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                //ack 보내고(다 받음 or 다 전송)
                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r = 1'b0;
                                if (is_read) begin
                                    //들어온 ack신호를 reg로 해서 latching
                                    //바로 나갈 수 있기 떄문에 잠시 저장
                                    sda_r <= ack_in_r;
                                end else begin
                                    sda_r <= 1'b1;  // sda input 설정, sda high impedence 설정
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r = 1'b1;
                                step <= 2'd2;
                            end
                            2'd2: begin
                                scl_r = 1'b1;
                                //ack 수신
                                if (!is_read) begin
                                    //마스터가 host(CPU)에  보내는 신호
                                    ack_out <= sda_i;
                                end
                                if (is_read) begin
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1; //tb의 두번째 wait(done)!!!!
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end


endmodule

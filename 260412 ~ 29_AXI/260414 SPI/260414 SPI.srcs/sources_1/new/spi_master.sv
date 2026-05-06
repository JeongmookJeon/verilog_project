`timescale 1ns / 1ps

module spi_master (
    input logic clk,
    input logic reset,
    input logic cpol,  //idle 상태일 때 0 : LOW일때 출력, 1: HIGH 일때 출력
    input logic cpha,  //FIRST sampling 0 : first edge sampling, 1: second edge
    // 내가 10mhz로 동작시키고싶으면 4를 넣어줘야함.
    input logic [7:0] clk_div,
    // data는 8bit로 설정 
    input logic [7:0] tx_data,
    input logic start,  // 데이터 보낼 신호(다음clk start state)
    output logic [7:0] rx_data,
    output logic done,
    output logic busy,
    output logic sclk,
    output logic mosi,  //[master] out slave in
    input logic miso,  // master in [slave] out
    output logic cs_n  //  active low signal
);
    //
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;
    logic [7:0] div_cnt;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;  // 8bit siganl reg & count
    logic step;
    logic half_tick;
    logic sclk_r;  // sclk register

    //10Mhz clk make
    assign sclk = sclk_r;

    //clk 발생.데이터가 송,수신 할 때만 clk이 발생한다. 
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end
        end
    end

    // always안에 있는 변수들은 무조건 FF형태이다.
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
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
            sclk_r       <= cpol;  // 레지스터값
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi <= 1'b1;
                    cs_n <= 1'b1;
                    sclk_r <= cpol; // cpol로 입력시키면 polartiy에 맞춰서 동작한다. 
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
                    if(!cpha)begin  // 초기 송신(보내고 shift, 보내고 shift)
                        //7번째 bit를 보냄(MSB)
                        mosi <= tx_shift_reg[7];
                        //7번쨰 bit부터 0으로 채워짐
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        //2. 10Mhz clk make
                        sclk_r <= ~sclk_r;  //clk 토글
                        //첫번째 tick이면
                        //송신구간인지 수신구간인지 판단(첫번째  tick, 두번째 tick인지 판단)
                        if (step == 0) begin  //수신구간
                            step <= 1'b1;
                            if (!cpha) begin
                                //슬래이브 준값을 마스터가 저장
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end else begin
                                //7번째 bit를 보냄(MSB)
                                mosi <= tx_shift_reg[7];
                                //7번쨰 bit부터 0으로 채워짐
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                            //두번째 tick이면
                        end else begin  //송신 구간
                            step <= 1'b0;
                            if (!cpha) begin
                                if (bit_cnt < 7) begin
                                    mosi <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end else begin
                                //미소 값 수신
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end
                            //8번째 bit cnt일때 바로 내보낼거냐 한번 더 받고 내보낼거냐
                            if (bit_cnt == 7) begin
                                state <= STOP;
                                if (!cpha) begin
                                    rx_data <= rx_shift_reg;
                                end else begin
                                    //rx_data <= rx_shift_reg;
                                    rx_data <= {rx_shift_reg[6:0], miso};
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end
                STOP: begin
                    sclk_r <= 1'b0;
                    cs_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'b1;  //high일때가 zero인 상태
                    state  <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

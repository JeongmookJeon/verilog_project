`timescale 1ns / 1ps

module sr04_controller (
    input         clk,        // 100MHz System Clock
    input         rst,
    input         start,      // 측정 시작 신호
    input         echo,       // 센서 Echo 입력
    output        trigger,    // 센서 Trigger 출력
    output [15:0] dist_data,  // 거리 데이터 (cm)
    output        done        // 완료 신호
);

    // 1. 상태 정의
    localparam IDLE     = 3'd0, 
               START    = 3'd1,  
               WAIT     = 3'd2,  
               DISTANCE = 3'd3,  
               STANDBY  = 3'd4;

    // 1. 1us 만들기: 100MHz(10ns) x 100개 = 1000ns = 1us
    localparam US_TICK_MAX = 7'd99;

    // 2. 60ms 만들기: 1us x 60,000개 = 60,000us = 60ms
    localparam DELAY_60MS = 22'd60_000;


    // 레지스터 정의
    reg [2:0] c_state, n_state;
    reg [6:0] tick_cnt_reg, tick_cnt_next;  // 0~99 (1us 세는 용도)
    reg [21:0] us_cnt_reg, us_cnt_next;  // 시간(us) 누적 (거리 & 60ms 대기용)
    reg [15:0] dist_reg, dist_next;
    reg trig_reg, trig_next;
    reg done_reg, done_next;

    // 출력 연결
    assign trigger   = trig_reg;
    assign dist_data = dist_reg;
    assign done      = done_reg;

    // Sequential Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            tick_cnt_reg <= 7'd0;
            us_cnt_reg   <= 22'd0;
            dist_reg     <= 16'd0;
            trig_reg     <= 1'b0;
            done_reg     <= 1'b0;
        end else begin
            c_state      <= n_state;
            tick_cnt_reg <= tick_cnt_next;
            us_cnt_reg   <= us_cnt_next;
            dist_reg     <= dist_next;
            trig_reg     <= trig_next;
            done_reg     <= done_next;
        end
    end

    // Combinational Logic
    always @(*) begin
        // 기본값 설정
        n_state       = c_state;
        tick_cnt_next = tick_cnt_reg;
        us_cnt_next   = us_cnt_reg;
        dist_next     = dist_reg;
        trig_next     = trig_reg;
        done_next     = done_reg;

        // 1us 틱 생성기 (0~99 카운트)
        if (tick_cnt_reg == US_TICK_MAX) tick_cnt_next = 7'd0;
        else tick_cnt_next = tick_cnt_reg + 1;

        case (c_state)
            IDLE: begin
                done_next = 1'b0;
                trig_next = 1'b0;
                if (start) begin
                    n_state       = START;
                    tick_cnt_next = 7'd0;
                    us_cnt_next   = 22'd0;
                end
            end

            // Trigger 10us 발생
            START: begin
                trig_next = 1'b1;
                // 1us 지날 때마다 확인
                if (tick_cnt_reg == US_TICK_MAX) begin
                    if (us_cnt_reg == 10) begin  // 10us 도달
                        trig_next   = 1'b0;
                        us_cnt_next = 22'd0;
                        n_state     = WAIT;
                    end else begin
                        us_cnt_next = us_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                if (echo == 1'b1) begin
                    n_state       = DISTANCE;
                    tick_cnt_next = 7'd0;
                    us_cnt_next   = 22'd0;
                end
            end

            DISTANCE: begin
                if (echo == 1'b0) begin
                    // 측정 종료 및 계산
                    dist_next   = us_cnt_reg / 58;
                    done_next   = 1'b1;

                    // STANDBY로 이동
                    n_state     = STANDBY;
                    us_cnt_next = 22'd0;
                end else begin
                    // Echo High 유지 중 -> 시간 측정
                    if (tick_cnt_reg == US_TICK_MAX) begin
                        us_cnt_next = us_cnt_reg + 1;
                    end
                end
            end

            // 60ms 대기 (60,000us)
            STANDBY: begin
                done_next = 1'b0;

                if (tick_cnt_reg == US_TICK_MAX) begin
                    // us_cnt_reg가 1us마다 1씩 증가함
                    // 60,000이 되면 60ms가 지난 것
                    if (us_cnt_reg >= DELAY_60MS) begin
                        n_state = IDLE;
                    end else begin
                        us_cnt_next = us_cnt_reg + 1;
                    end
                end
            end

            default: n_state = IDLE;
        endcase
    end

endmodule

module tick_gen_1us (
    input clk,
    input rst,
    output reg o_tick  // 1us마다 1이 됨
);

    // 100MHz / 100 = 1MHz (1us)
    parameter F_COUNT = 100;

    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick      <= 0;
        end else begin
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;  // Tick!
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick      <= 1'b0;
            end
        end
    end

endmodule

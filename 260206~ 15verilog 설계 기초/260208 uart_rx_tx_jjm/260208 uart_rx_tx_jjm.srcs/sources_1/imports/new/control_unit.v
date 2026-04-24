`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_sel_mode,  // sw[1] : 0:stopwatch, 1: watch
    input i_mode,      // sw[0]
    input i_run_stop,  // btn_r (Right Button)
    input i_clear,     // btn_l (Left Button)
    input i_down_u,    // btn_u (Up Button -> Watch Down Left 역할)
    input i_down_d,    // btn_d (Down Button -> Watch Down Right 역할)

    output reg o_mode,
    output reg o_run_stop,
    output reg o_clear,

    output reg o_watch_up_l,    // Watch Up Left (시/초 증가)
    output reg o_watch_up_r,    // Watch Up Right (분/밀리초 증가)
    output reg o_watch_down_u,  // Watch Down Left (시/초 감소)
    output reg o_watch_down_d,  // Watch Down Right (분/밀리초 감소)
    output reg o_watch_change   // Watch 수정 모드 활성화
);

    reg [1:0] current_st, next_st;
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    // 1. 순차 회로 (State Register) - 기존 구조 유지
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else begin
            current_st <= next_st;
        end
    end

    // 2. 조합 논리 회로 (Next State Logic & Output Logic) - 기존 구조 유지
    always @(*) begin
        // Latch 방지를 위한 기본값 설정
        next_st = current_st;
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        o_mode = 1'b0;

        o_watch_change = 1'b0;
        o_watch_up_l = 1'b0;
        o_watch_up_r = 1'b0;
        o_watch_down_u = 1'b0;
        o_watch_down_d = 1'b0;

        // 모드에 따른 분기
        if (i_sel_mode == 0) begin
            // [스톱워치 모드] (FSM 동작)
            o_mode = i_mode;  // Stopwatch Datapath의 Up/Down 모드 전달

            case (current_st)
                STOP: begin
                    o_run_stop = 0;
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st = RUN;
                    end else if (i_clear == 1) begin
                        next_st = CLEAR;
                    end else begin
                        next_st = STOP;
                    end
                end

                RUN: begin
                    o_run_stop = 1;  // Run 상태 유지
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st = STOP;
                    end else begin
                        next_st = RUN;
                    end
                end

                CLEAR: begin
                    o_run_stop = 0;
                    o_clear = 1;  // Clear 신호 발생
                    next_st = STOP; // 한번 클리어 후 바로 정지 상태로 복귀
                end

                default: begin
                    next_st = STOP;
                    o_clear = 0;
                    o_run_stop = 0;
                end
            endcase

        end else begin
            // [시계 모드] (Bypass 동작)
            o_watch_change = i_mode;  // 수정 모드(sw[0])

            // 버튼 매핑 (왼쪽/오른쪽 위치에 맞춰 매핑)
            o_watch_up_l = i_clear;  // Left 버튼 -> 시/초 증가
            o_watch_up_r = i_run_stop;  // Right 버튼 -> 분/밀리초 증가

            // [수정된 부분] 0으로 죽어있던 Down 신호를 입력과 연결
            o_watch_down_u = i_down_u;    // Up 버튼(mapping상 down_u) -> 시/초 감소
            o_watch_down_d = i_down_d;    // Down 버튼(mapping상 down_d) -> 분/밀리초 감소
        end
    end

endmodule

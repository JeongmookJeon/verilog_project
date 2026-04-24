`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_sel_mode,            // sw[1] : 0:stopwatch, 1: watch
    input i_mode,
    input i_run_stop,            // Right Button (Down 역할 가정)
    input i_clear,               // Left Button (Up 역할 가정)
    output reg o_mode,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_watch_up_r,     // 분, msec (Down 버튼으로 수정)
    output reg o_watch_up_l,     // 시간, 초 (Up 버튼으로 수정)
    output reg o_watch_down_u,   // 시간, 초 (Down 포트)
    output reg o_watch_down_d,   // 분, msec (Down 포트)
    output reg o_watch_change
);
    reg [1:0] current_st, next_st;
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10; 

    // Stopwatch 상태 머신
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else begin
            current_st <= next_st;
        end
    end

    // 조합 논리 회로 (Next State Logic & Output Logic)
    always @(*) begin
        // 1. 모든 출력의 기본값(Default) 설정 (Latch 방지)
        next_st = current_st;
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        o_mode = 1'b0;
        o_watch_change = 1'b0;
        
        o_watch_up_l = 1'b0;
        o_watch_up_r = 1'b0;
        o_watch_down_u = 1'b0;  // 새로 추가된 포트 초기화
        o_watch_down_d = 1'b0;  // 새로 추가된 포트 초기화

        // 2. 모드에 따른 동작 분기
        if (i_sel_mode == 0) begin
            // [스톱워치 모드]
            o_mode = i_mode;
            case (current_st)
                STOP: begin
                    o_run_stop = 0;
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st = RUN;
                    end else if (i_clear == 1) begin
                        next_st = CLEAR;
                    end else begin 
                        next_st = current_st;
                    end
                end
                RUN: begin
                    o_run_stop = 1;
                    o_clear = 0;
                    if (i_run_stop == 1) begin
                        next_st = STOP;
                    end else begin
                        next_st = current_st; // 수정: next_st_stop -> next_st
                    end
                end
                CLEAR: begin
                    o_run_stop = 0;
                    o_clear = 1;
                    next_st = STOP;       // 수정: next_st_stop -> next_st
                end
                default: begin
                    next_st = current_st;
                    o_clear = 0;
                    o_run_stop = 0;
                end
            endcase

        end else begin
            // [시계 모드] (Watch)
            o_watch_change = i_mode; 
            o_watch_up_l   = i_clear;
            o_watch_up_r   = i_run_stop;

            // 추가된 Down 포트들 (현재 입력 버튼 부족으로 0으로 설정하거나 필요시 연결)
            // 만약 실제로 값을 '내리는' 동작을 하려면 별도의 스위치 조합이 필요합니다.
            o_watch_down_u = 1'b0; 
            o_watch_down_d = 1'b0;
        end
    end

endmodule
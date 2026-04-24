`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,

    // switches
    input i_sel_mode,  // sw[1] : 0=stopwatch, 1=watch
    input i_mode,      // sw[0] : stopwatch(up/down), watch(change)

    // buttons
    input btn_l,
    input btn_r,
    input btn_m,  // clear 전용
    input btn_u,
    input btn_d,

    // stopwatch outputs
    output reg o_mode,
    output reg o_run_stop,
    output reg o_clear,

    // watch outputs
    output reg o_watch_l,      // 시간 / 초 선택
    output reg o_watch_r,      // 분 / ms 선택
    output reg o_watch_u,      // UP
    output reg o_watch_d,      // DOWN
    output reg o_watch_change
);

    // stopwatch FSM
    reg [1:0] current_st, next_st;
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    // 순차회로 : 상태 레지스터
    always @(posedge clk or posedge reset) begin
        if (reset) current_st <= STOP;
        else current_st <= next_st;
    end

    // 조합논리 : 상태 전이 + 출력
    always @(*) begin
        // default (latch 방지)
        next_st        = current_st;

        o_mode         = 1'b0;
        o_run_stop     = 1'b0;
        o_clear        = 1'b0;

        o_watch_l      = 1'b0;
        o_watch_r      = 1'b0;
        o_watch_u      = 1'b0;
        o_watch_d      = 1'b0;
        o_watch_change = 1'b0;

        // STOPWATCH MODE
        if (i_sel_mode == 1'b0) begin
            o_mode = i_mode;  // up / down 선택

            case (current_st)
                STOP: begin
                    if (btn_r) next_st = RUN;
                    else if (btn_m) next_st = CLEAR;
                end

                RUN: begin
                    o_run_stop = 1'b1;
                    if (btn_r) next_st = STOP;
                end

                CLEAR: begin
                    o_clear = 1'b1;
                    next_st = STOP;
                end
            endcase
        end  // WATCH MODE
        else begin
            o_watch_change = i_mode;

            // 시간 / 초 선택
            if (btn_l) o_watch_l = 1'b1;

            // 분 / ms 선택
            if (btn_r) o_watch_r = 1'b1;

            // UP / DOWN 조합
            if (btn_u) o_watch_u = 1'b1;
            if (btn_d) o_watch_d = 1'b1;

            // btn_m 은 watch reset 용도로만 (필요 시)
            if (btn_m) o_clear = 1'b1;
        end
    end

endmodule

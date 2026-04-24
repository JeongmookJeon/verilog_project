`timescale 1ns / 1ps `timescale 1ns / 1ps `timescale 1ns / 1ps

module TOP_counter_10000 (
    input clk,
    input rst,
    input [2:0] sw,  // sw[0]:Mode/Change, sw[1]:Sel_Mode, sw[2]:Sel_Display
    input btn_r,  // run_stop (Right Button)
    input btn_l,  // clear (Left Button)
    input btn_down_u,  // T18 (Down Up)
    input btn_down_d,  // U17 (Down Down)
    output [7:0] fnd_data,
    output [3:0] fnd_digit
);

    // 1. 내부 전선 선언
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_watch_stopwatch_select;

    wire w_mode, w_run_stop, w_clear;
    wire w_watch_change, w_watch_up_r, w_watch_up_l;
    wire w_watch_down_u, w_watch_down_d;  // Control Unit의 Dummy wire

    // 버튼 디바운싱 출력
    wire o_btn_run_stop, o_btn_clear;
    wire o_btn_down_u, o_btn_down_d;

    assign w_watch_stopwatch_select = (sw[1]) ? w_watch_time : w_stopwatch_time;

    // 2. 버튼 디바운싱
    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );
    btn_debounce U_BD_DOWN_U (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_down_u),
        .o_btn(o_btn_down_u)
    );
    btn_debounce U_BD_DOWN_D (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_down_d),
        .o_btn(o_btn_down_d)
    );

    // 3. Control Unit
    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        .i_run_stop(o_btn_run_stop),
        .i_clear(o_btn_clear),
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_watch_change(w_watch_change),
        .o_watch_up_r(w_watch_up_r),
        .o_watch_up_l(w_watch_up_l)
    );

    // 4. Stopwatch Datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .mode(w_mode),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .msec(w_stopwatch_time[6:0]),
        .sec(w_stopwatch_time[12:7]),
        .min(w_stopwatch_time[18:13]),
        .hour(w_stopwatch_time[23:19])
    );

    // 5. Watch Datapath (중복 연결 수정됨)
    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .sel_display(sw[2]),
        .change(w_watch_change),

        // [수정 완료] 중복 없이 한 번만 연결합니다.
        .up_l(w_watch_up_l),  // Control Unit의 신호를 연결
        .up_r(w_watch_up_r),  // Control Unit의 신호를 연결

        .down_l(o_btn_down_u),  // 실제 버튼 연결
        .down_r(o_btn_down_d),  // 실제 버튼 연결

        .msec(w_watch_time[6:0]),
        .sec (w_watch_time[12:7]),
        .min (w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

    // 6. FND Controller
    fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .sel_display(sw[2]),
        .fnd_in_data(w_watch_stopwatch_select),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule



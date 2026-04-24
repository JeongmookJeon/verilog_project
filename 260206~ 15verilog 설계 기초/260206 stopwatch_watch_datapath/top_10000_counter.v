`timescale 1ns / 1ps `timescale 1ns / 1ps `timescale 1ns / 1ps

module TOP_counter_10000 (
    input clk,
    input reset,
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
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );
    btn_debounce U_BD_DOWN_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_down_u),
        .o_btn(o_btn_down_u)
    );
    btn_debounce U_BD_DOWN_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_down_d),
        .o_btn(o_btn_down_d)
    );

    // 3. Control Unit
    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        .i_run_stop(o_btn_run_stop),
        .i_clear(o_btn_clear),
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_watch_change(w_watch_change),
        .o_watch_up_r(w_watch_up_r),
        .o_watch_up_l(w_watch_up_l),
        .o_watch_down_u(w_watch_down_u),
        .o_watch_down_d(w_watch_down_d)
    );

    // 4. Stopwatch Datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
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
        .reset(reset),
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
        .reset(reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_watch_stopwatch_select),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule



module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_msec_tick;
    wire w_sec_tick, w_min_tick, w_hour_tick;


    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );
    tick_gen_100hz U_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );
endmodule

//msec, sec, min, hour
module tick_counter #(  //0~99
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign o_count = counter_reg;
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                //down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
                //up
            end else begin
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end

            end
        end
    end
endmodule
`timescale 1ns / 1ps

module tick_gen_100hz (  // 0.01초 생성기
    input clk,
    input reset,
    input run_stop,  // 수정됨: i_run_stop -> run_stop (이름 통일),
    output reg o_tick_100hz
);
    // 100MHz / 100 = 1MHz (1usec) -> 1000개 -> 1ms -> 100ms
    // 실제 보드용: 100_000_000 / 100
    // 시뮬레이션용: 값을 작게 (예: 100) 줄여서 확인하세요. 
    parameter F_COUNT = 100_000_000/100; //  이거전부 붙여   100_000_000/100; 

    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            o_tick_100hz <= 0;
        end else begin
            // [수정 포인트 1] 변수명 변경 (i_run_stop -> run_stop)
            if (run_stop) begin
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    r_counter <= r_counter + 1;
                    o_tick_100hz <= 1'b0;
                end
            end else begin
                // [수정 포인트 2] 멈췄을 때 로직 추가 (중요!)
                // 멈춰있을 때는 틱을 발생시키지 않아야 안전합니다.
                o_tick_100hz <= 1'b0;
                // (선택사항) 멈췄을 때 카운터를 유지할지 0으로 밀지 결정
                // 보통 스톱워치는 멈췄다 다시 가면 이어서 세야 하므로 r_counter는 유지합니다.
            end
        end
    end

endmodule

// 아래에 배치되어있던 10000 counter은 없앴음.

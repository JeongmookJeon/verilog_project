`timescale 1ns / 1ps

module TOP_counter_10000 (
    input clk,
    input reset,
    input [2:0] sw,
    // sw[0] : stopwatch up/down , watch change
    // sw[1] : 0=stopwatch, 1=watch
    // sw[2] : display select

    input btn_r,  // run/stop or watch right select
    input btn_l,  // watch left select
    input btn_u,  // up
    input btn_d,  // down
    input btn_m,  // clear

    output [7:0] fnd_data,
    output [3:0] fnd_digit
);

    // 1. 내부 신호
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_fnd_time;

    // control_unit → stopwatch
    wire w_mode;
    wire w_run_stop;
    wire w_clear;

    // control_unit → watch
    wire w_watch_l;
    wire w_watch_r;
    wire w_watch_u;
    wire w_watch_d;
    wire w_watch_change;

    // debounce outputs
    wire d_btn_r;
    wire d_btn_l;
    wire d_btn_u;
    wire d_btn_d;
    wire d_btn_m;


    // 2. 표시 선택

    assign w_fnd_time = (sw[1]) ? w_watch_time : w_stopwatch_time;


    // 3. Button Debounce

    btn_debounce BD_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(d_btn_r)
    );

    btn_debounce BD_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(d_btn_l)
    );

    btn_debounce BD_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(d_btn_u)
    );

    btn_debounce BD_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(d_btn_d)
    );

    btn_debounce BD_M (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_m),
        .o_btn(d_btn_m)
    );


    // 4. Control Unit (두뇌)

    control_unit U_CONTROL_UNIT (
        .clk  (clk),
        .reset(reset),

        // switches
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),

        // buttons (debounced)
        .btn_l(d_btn_l),
        .btn_r(d_btn_r),
        .btn_u(d_btn_u),
        .btn_d(d_btn_d),
        .btn_m(d_btn_m),

        // stopwatch outputs
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),

        // watch outputs
        .o_watch_l(w_watch_l),
        .o_watch_r(w_watch_r),
        .o_watch_u(w_watch_u),
        .o_watch_d(w_watch_d),
        .o_watch_change(w_watch_change)
    );


    // 5. Stopwatch Datapath

    stopwatch_datapath U_STOPWATCH (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .run_stop(w_run_stop),
        .clear(w_clear),

        .msec(w_stopwatch_time[6:0]),
        .sec (w_stopwatch_time[12:7]),
        .min (w_stopwatch_time[18:13]),
        .hour(w_stopwatch_time[23:19])
    );


    // 6. Watch Datapath

    watch_datapath U_WATCH (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),
        .change(w_watch_change),

        .up_l  (w_watch_l),
        .up_r  (w_watch_r),
        .down_l(w_watch_u),
        .down_r(w_watch_d),

        .msec(w_watch_time[6:0]),
        .sec (w_watch_time[12:7]),
        .min (w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

    // 7. FND Controller
    fnd_controller U_FND (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_fnd_time),
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

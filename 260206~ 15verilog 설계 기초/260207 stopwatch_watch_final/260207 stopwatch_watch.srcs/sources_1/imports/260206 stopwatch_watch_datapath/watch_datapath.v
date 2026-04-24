`timescale 1ns / 1ps

module watch_datapath (
    input        clk,
    input        reset,
    input        sel_display,
    input        up_l,         // Left Up (Hour, Sec)
    input        up_r,         // Right Up (Min, Msec)
    input        down_l,       // New: Left Down (o_watch_down_u 연결)
    input        down_r,       // New: Right Down (o_watch_down_d 연결)
    input        change,       // sw[0] = 1 change, sw[0] =0 ongoing
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    tick_gen_100hz U_TICK (
        .clk(clk),
        .reset(reset),
        .run_stop(!change),
        .o_tick_100hz(w_tick_100hz)
    );

    // [Hour Counter]
    // 수정: up_l, down_l 연결 (나머지는 0)
    tick_counter_watch #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .FIRST(12)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .change(change & sel_display),
        .up_l(up_l),
        .up_r(1'b0),
        .down_l(down_l),  // Down 입력 연결
        .down_r(1'b0),
        .o_tick(),
        .o_count(hour)
    );

    // [Min Counter]
    // 수정: up_r, down_r 연결
    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .change(change & sel_display),
        .up_r(up_r),
        .up_l(1'b0),
        .down_l(1'b0),
        .down_r(down_r),  // Down 입력 연결
        .o_tick(w_hour_tick),
        .o_count(min)
    );


    // [Sec Counter]
    // 수정: up_l, down_l 연결
    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .change(change & !sel_display),
        .up_l(up_l),
        .up_r(1'b0),
        .down_l(down_l),  // Down 입력 연결
        .down_r(1'b0),
        .o_tick(w_min_tick),
        .o_count(sec)
    );


    // [Msec Counter]
    // 수정: up_r, down_r 연결
    tick_counter_watch #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .FIRST(0)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .change(change & !sel_display),
        .up_r(up_r),
        .up_l(1'b0),
        .down_l(1'b0),
        .down_r(down_r),  // Down 입력 연결
        .o_tick(w_sec_tick),
        .o_count(msec)
    );

endmodule


module tick_counter_watch #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    FIRST = 12
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      change,
    input                      up_l,
    input                      up_r,
    input                      down_l,  // New input
    input                      down_r,  // New input
    output reg                 o_tick,
    output     [BIT_WIDTH-1:0] o_count
);

    //counter reg
    reg [BIT_WIDTH-1 : 0] counter_reg, counter_next;

    assign o_count = counter_reg;

    //state reg
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= FIRST;
        end else counter_reg <= counter_next;
    end

    //next counter logic
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 0;

        // 1. 증가 (Increment): 시간이 흐르거나(Tick) || 수정모드에서 Up 버튼 누름
        if ((i_tick && !change) || (change && (up_l || up_r))) begin
            if (counter_reg == (TIMES - 1)) begin
                o_tick = 1;
                counter_next = 0;
            end else begin
                counter_next = counter_reg + 1;
                o_tick = 0;
            end
        end  // 2. 감소 (Decrement): 수정모드에서 Down 버튼 누름
        else if (change && (down_l || down_r)) begin
            o_tick = 0; // 수동 조작 시에는 보통 자리올림/내림(Carry/Borrow)을 발생시키지 않음
            if (counter_reg == 0) begin
                counter_next = TIMES - 1; // 0에서 내리면 최대값으로 (예: 00초 -> 59초)
            end else begin
                counter_next = counter_reg - 1;
            end
        end  // 3. 유지 (Hold)
        else begin
            counter_next = counter_reg;
            o_tick = 0;
        end
    end

endmodule

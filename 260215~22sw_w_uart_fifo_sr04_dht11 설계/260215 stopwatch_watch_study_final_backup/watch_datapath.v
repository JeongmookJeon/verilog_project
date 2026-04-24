`timescale 1ns / 1ps

module watch_datapath (
    input        clk,
    input        rst,
    input        change,
    input        sel_display,
    input        up_r,
    input        up_l,
    input        down_r,
    input        down_l,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    tick_counter_watch #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .FIRST(12)
    ) hour_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .change(change & sel_display),
        .down_l(down_l),
        .down_r(1'b0),
        .up_l(up_l),
        .up_r(1'b0),
        .o_tick(),
        .o_count(hour)
    );

    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) min_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .change(change & sel_display),
        .down_l(1'b0),
        .down_r(down_r),
        .up_l(1'b0),
        .up_r(up_r),
        .o_tick(w_hour_tick),
        .o_count(min)
    );

    tick_counter_watch #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .FIRST(0)
    ) sec_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .change(change & !sel_display),
        .down_l(down_l),
        .down_r(1'b0),
        .up_l(up_l),
        .up_r(1'b0),
        .o_tick(w_min_tick),
        .o_count(sec)
    );

    tick_counter_watch #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .FIRST(0)
    ) msec_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .change(change & !sel_display),
        .down_l(1'b0),
        .down_r(down_r),
        .up_l(1'b0),
        .up_r(up_r),
        .o_tick(w_sec_tick),
        .o_count(msec)
    );

    tick_gen_100hz U_TICK (
        .clk(clk),
        .rst(rst),
        .run_stop(!change),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter_watch #(
    parameter BIT_WIDTH = 7,
    parameter TIMES = 100,
    parameter FIRST = 12
) (
    input                      clk,
    input                      rst,
    input                      i_tick,
    input                      change,
    input                      down_l,
    input                      down_r,
    input                      up_l,
    input                      up_r,
    output reg                 o_tick,
    output     [BIT_WIDTH-1:0] o_count
);
    reg [BIT_WIDTH-1:0] counter_r, counter_next;
    assign o_count = counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= FIRST;
        end else begin
            counter_r <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_r;
        o_tick = 1'b0;
        //증가 : 시간이 흐르거나 수정모드, 수정모드에서 버튼 up
        if ((i_tick && !change) || (change && (up_r || up_l)))
            if (counter_r == (TIMES - 1)) begin
                o_tick = 1'b1;
                counter_next = 0;
            end else begin
                counter_next = counter_r + 1;
                o_tick = 1'b0;
            end
        // 감소 : 수정모드 버튼 down
        else if (change && (down_r || down_l)) begin
            o_tick = 1'b0;
            if (counter_r == 0) begin
                counter_next = TIMES - 1;
            end else begin
                counter_next = counter_r - 1;
            end
        end else begin
            counter_next = counter_r;
            o_tick = 0;
        end
    end

endmodule

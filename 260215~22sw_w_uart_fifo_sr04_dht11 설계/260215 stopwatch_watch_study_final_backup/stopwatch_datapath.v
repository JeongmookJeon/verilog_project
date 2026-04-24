`timescale 1ns / 1ps

module stopwatch_datapath (
    input clk,
    input rst,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_hour_tick, w_min_tick, w_sec_tick, w_msec_tick;
    wire w_tick_100hz;

    tick_counter_stopwatch #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_stopwatch #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_stopwatch #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_stopwatch #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter_stopwatch #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input rst,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);
    reg [(BIT_WIDTH)-1:0] counter_r, counter_next;
    assign o_count = counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst || clear) begin
            counter_r <= 0;
        end else begin
            counter_r <= counter_next;
        end
    end
    always @(*) begin
        counter_next = counter_r;
        o_tick = 1'b0;
        if (i_tick && run_stop) begin
            if (mode == 1'b1) begin
                if (counter_r == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_r - 1;
                    o_tick = 1'b0;
                end
            end else begin
                if (counter_r == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_r + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module tick_gen_100hz (
    input      clk,
    input      rst,
    input      run_stop,
    output reg o_tick_100hz
);
    parameter CLK_DIV = 100;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (run_stop) begin
                if (counter_r == (F_COUNT - 1)) begin
                    counter_r <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    counter_r <= counter_r + 1;
                    o_tick_100hz <= 1'b0;
                end
            end else begin
                o_tick_100hz <= 0;
            end
        end
    end

endmodule

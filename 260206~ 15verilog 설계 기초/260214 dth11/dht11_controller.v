`timescale 1ns / 1ps

module dht11_controller (
    input         clk,
    input         rst,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht11_done,
    output        dht11_valid,
    output [ 3:0] debug,
    inout         dhtio
);

    wire tick_10u;
    tick_gen_10u U_TICK_10u (
        .clk(clk),
        .rst(rst),
        .tick_10u(tick_10u)
    );
    //state
    parameter IDLE = 0, START =1, WAIT=2, SYNC_L=3, SYNC_H=4,
                DATA_STNC=5, DATA_C=6, STOP=7;
    reg [2:0] c_state, n_state;
    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;
    //for 19msec count bt 10usec tick
    reg [$clog2(1900)-1:0] tick_cnt_reg, tick_cnt_next;
    assign dhtio = (io_sel_reg) ? dhtio_reg : 1'bz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 3'b000;
            dhtio_reg <= 1'b1;
            io_sel_reg <= 1'b1;
            tick_cnt_reg <= 0;
        end else begin
            c_state <= n_state;
            dhtio_reg <= dhtio_next;
            io_sel_reg <= io_sel_next;
            tick_cnt_reg <= tick_cnt_next;
        end
    end
    //next, output
    always @(*) begin
        n_state    = c_state;
        dhtio_next = dhtio_reg;
        io_sel_next = io_sel_reg;
        tick_cnt_next <= tick_cnt_reg;
        case (c_state)
            IDLE: begin
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                dhtio_next = 1'b0;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 1900) begin // 여유주기위해 19msec 유지
                        tick_cnt_next = 0;  // 틱카운트 초기화
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin
                dhtio_next = 1'b1;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 3) begin
                        //for output to high-z
                        n_state = SYNC_L;
                        io_sel_next = 1'b0;
                    end
                end
            end
            SYNC_L : begin //10mse 5개 굳이 볼 필요 없이 dhtio를 읽으면 된다.
                if (tick_10u) begin
                    if(dhtio==1)begin // sync low와 sync high로 만들어줘서 끊어준것이다.(교수님)
                        //tick이 1일때냐 0일때냐만 판단한다.
                        n_state = SYNC_H;
                    end
                end
            end
            SYNC_H: begin
                if (tick_10u) begin
                    if (dhtio == 0) begin
                        n_state = DATA_STNC; // 노이즈 감소 위함. 시뮬레이션 해보자!! 37bit,38bit에서 멈출수도(노이즈 감소위함)
                    end
                end
            end
            DATA_STNC: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        n_state = DATA_C;
                    end
                end
            end
            DATA_C: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        // 나머지 완성해야한다. 아래부분 완성해야한다.
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        n_state = STOP;
                    end
                end
            end
            STOP: begin
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 5) begin
                        //output mode
                        dhtio_next = 1'b1;
                        io_sel_next = 1'b1;//////////////////
                        n_state = IDLE;
                    end
                end
            end
        endcase
    end


endmodule

module tick_gen_10u (
    input      clk,
    input      rst,
    output reg tick_10u
);
    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_10u    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_10u <= 1'b1;
            end else begin
                tick_10u <= 1'b0;
            end
        end
    end
endmodule

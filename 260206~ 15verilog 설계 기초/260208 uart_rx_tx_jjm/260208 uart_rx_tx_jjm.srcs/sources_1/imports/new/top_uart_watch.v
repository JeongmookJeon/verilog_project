`timescale 1ns / 1ps

module top_uart_watch (
    input clk,
    input reset,
    input [2:0] sw,     // 0 = mode/시계 수정 1= stwatch/watch 2 = 시간,분/초,밀리초
    input btn_r,  // run_stop / 시간,초 수정 
    input btn_l,  // clear/ 분,밀리초 수정
    input btn_u,  // up - 시간,초 수정 
    input btn_d,  // down - 분,밀리초 수정
    input uart_rx,  // PC의 TX
    output uart_tx,  // PC로 보낼 RX
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire w_rx_tx_data;
    wire w_rx_tx_done;
    wire [3:0] w_asc_btn;
    wire o_btn_l, o_btn_r, o_btn_u, o_btn_d;
    wire w_mode, w_run_stop, w_clear, w_up_l, w_up_r, w_down_u, w_down_d;
    wire w_change;
    wire [7:0] w_rx_data;  // UART RX로 받은 데이터
    wire w_rx_done;  // UART RX 완료 신호
    wire [3:0] w_ascii_data;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_fnd_in_data;

    // [NEW] Sender 관련 와이어 추가 =======================================
    wire w_send_trigger;  // 's' 키 입력 감지 신호
    wire w_sender_tx_start;  // Sender가 보내는 start 신호
    wire [7:0] w_sender_data;  // Sender가 보내는 데이터
    wire w_tx_busy;  // UART TX가 바쁜지 여부

    wire w_final_tx_start;    // 최종적으로 UART TX에 들어갈 start 신호
    wire [7:0] w_final_tx_data;  // 최종적으로 UART TX에 들어갈 data
    // ===================================================================

    assign w_asc_btn[0] = o_btn_l || w_ascii_data[2];
    assign w_asc_btn[1] = o_btn_r || w_ascii_data[3];
    assign w_asc_btn[2] = o_btn_d || w_ascii_data[0];
    assign w_asc_btn[3] = o_btn_u || w_ascii_data[1];

    // [NEW] 's' 키 (0x73) 입력 감지 로직
    assign w_send_trigger = (w_rx_done && (w_rx_data == 8'h73));

    // [NEW] MUX Logic: Sender가 보낼 데이터가 있으면 Sender 것을, 아니면 Loopback(RX 데이터)을 보냄
    assign w_final_tx_data = (w_sender_tx_start) ? w_sender_data : w_rx_data;
    assign w_final_tx_start = w_sender_tx_start | w_rx_done;


    // [MODIFIED] UART TOP 연결 수정 (입력 포트가 늘어남)
    uart_top U_UART (
        .clk       (clk),
        .rst       (reset),
        .uart_rx   (uart_rx),
        .uart_tx   (uart_tx),
        .rx_data   (w_rx_data),
        .rx_done   (w_rx_done),
        // 추가된 포트 연결
        .i_tx_start(w_final_tx_start),  // MUX 거친 신호 연결
        .i_tx_data (w_final_tx_data),   // MUX 거친 데이터 연결
        .o_tx_busy (w_tx_busy)          // Busy 신호 받아옴
    );

    // [NEW] Ascii Sender 인스턴스 추가
    ascii_sender U_ASCII_SENDER (
        .clk         (clk),
        .reset       (reset),
        .i_send_start(w_send_trigger),  // 's' 누르면 시작
        .i_tx_busy   (w_tx_busy),       // UART 바쁜지 확인

        // Watch 시간 데이터 연결
        .i_hour(w_watch_time[23:19]),
        .i_min (w_watch_time[18:13]),
        .i_sec (w_watch_time[12:7]),
        .i_msec(w_watch_time[6:0]),

        .o_tx_start(w_sender_tx_start),
        .o_tx_data (w_sender_data)
    );

    ascii_decoder U_ASCII (
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .ascii_data(w_ascii_data)
    );

    btn_debounce U_BTN_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_l)
    );
    btn_debounce U_BTN_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_r)
    );
    btn_debounce U_BTN_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_u)
    );
    btn_debounce U_BTN_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_d)
    );

    control_unit U_CONTROL (
        .clk(clk),
        .reset(reset),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        .i_run_stop(w_asc_btn[1]),
        .i_clear(w_asc_btn[0]),
        .i_down_u(w_asc_btn[3]),
        .i_down_d(w_asc_btn[2]),
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_watch_up_l(w_up_l),
        .o_watch_up_r(w_up_r),
        .o_watch_down_u(w_down_u),
        .o_watch_down_d(w_down_d),
        .o_watch_change(w_change)
    );

    stopwatch_datapath U_STOPWATCH (
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

    watch_datapath U_WATCH (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),        // [주의] 지난번에 수정한대로 sw[2] 유지
        .up_l(w_up_l),
        .up_r(w_up_r),
        .down_l(w_down_u),
        .down_r(w_down_d),
        .change(w_change),
        .msec(w_watch_time[6:0]),
        .sec(w_watch_time[12:7]),
        .min(w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

    mux_sel_stopwatch_watch U_MUX (
        .stopwatch_time(w_stopwatch_time),
        .watch_time(w_watch_time),
        .sel(sw[1]),
        .fnd_in_data(w_fnd_in_data)
    );

    fnd_controller U_FND_CNT (
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_fnd_in_data),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule

module ascii_decoder (
    input [7:0] rx_data,
    input rx_done,
    output reg [3:0] ascii_data
);

    always @(*) begin
        ascii_data = 4'b0000;
        if (rx_done) begin
            case (rx_data)
                8'h72: ascii_data = 4'b1000;  // r  run
                8'h6c: ascii_data = 4'b0100;  // l  clear
                8'h64: ascii_data = 4'b0001;  // d    time down
                8'h75: ascii_data = 4'b0010;  // u    min down

            endcase
        end
    end






endmodule

module mux_sel_stopwatch_watch (
    input [23:0] stopwatch_time,
    input [23:0] watch_time,
    input sel,
    output [23:0] fnd_in_data
);

    assign fnd_in_data = sel ? watch_time : stopwatch_time;

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
    tick_gen_100hz u_TICK (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH -1 : 0] o_count,
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
        o_tick = 0;
        if (i_tick & run_stop) begin
            if (mode) begin  //down count
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1;
                end else begin
                    o_tick = 0;
                    counter_next = counter_reg - 1;
                end
            end else begin  //up count
                if (counter_reg == TIMES - 1) begin
                    counter_next = 0;
                    o_tick = 1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 0;
                end
            end
        end
    end


endmodule



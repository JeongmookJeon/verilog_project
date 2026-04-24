`timescale 1ns / 1ps

module top_uart_S_W_D (
    input clk,
    input reset,

    // sw[3]: 거리 모드 (1=Distance, 0=Time)
    // sw[2]: Display Format (H:M / S:ms)
    // sw[1]: Watch / Stopwatch Select
    // sw[0]: Mode (Set / Run)
    input [3:0] sw,

    input btn_r,  // run_stop / 거리 측정 Trigger
    input btn_l,  // clear
    input btn_u,  // up
    input btn_d,  // down

    input  uart_rx,  // PC -> FPGA
    output uart_tx,  // FPGA -> PC

    output o_trig,   // SR04 Trigger
    input  i_echo,   // SR04 Echo

    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire w_rx_tx_data;
    wire w_rx_tx_done;
    wire [3:0] w_asc_btn;
    wire o_btn_l, o_btn_r, o_btn_u, o_btn_d;
    wire w_mode, w_run_stop, w_clear, w_up_l, w_up_r, w_down_u, w_down_d;
    wire        w_change;
    wire [ 7:0] w_rx_data;  
    wire        w_rx_done;
    wire [ 3:0] w_ascii_data;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_fnd_in_data;

    // 추가된 와이어
    wire [15:0] w_distance;  
    wire        w_send_trigger;  
    wire        w_sender_tx_start;  
    wire [ 7:0] w_sender_data;  
    wire        w_tx_busy;  
    wire        w_final_tx_start;  
    wire [ 7:0] w_final_tx_data;  

    // [수정] SR04 시작 신호 생성
    // 거리 모드(sw[3]=1)이고, 오른쪽 버튼(o_btn_r)이 눌렸을 때만 start 신호 발생
    wire w_sr04_start;
    assign w_sr04_start = (sw[3] == 1'b1) && o_btn_r;

    // MUX 선택 신호 생성
    wire [ 1:0] w_mux_sel;
    assign w_mux_sel = (sw[3]) ? 2'b10 : {1'b0, sw[1]};


    assign w_asc_btn[0] = o_btn_l || w_ascii_data[2];
    // [수정] 버튼 역할 분리: 거리 모드가 아닐 때만 Watch/Stopwatch 제어 신호로 전달
    assign w_asc_btn[1] = (sw[3] == 0) ? (o_btn_r || w_ascii_data[3]) : 1'b0; 
    assign w_asc_btn[2] = o_btn_d || w_ascii_data[0];
    assign w_asc_btn[3] = o_btn_u || w_ascii_data[1];

    // 's' 키 감지
    assign w_send_trigger = (w_rx_done && (w_rx_data == 8'h73));

    // UART 출력 MUX
    assign w_final_tx_data = (w_sender_tx_start) ? w_sender_data : w_rx_data;
    assign w_final_tx_start = w_sender_tx_start | w_rx_done;

    // FND MUX
    mux_sel_stopwatch_watch_distance U_MUX (
        .stopwatch_time(w_stopwatch_time),
        .watch_time(w_watch_time),
        .distance(w_distance),  
        .sel(w_mux_sel),  
        .fnd_in_data(w_fnd_in_data)
    );
    
    // UART TOP (수정된 버전 사용 필수)
    UART_TOP U_UART (
        .clk(clk),
        .rst(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // [수정] SR04 Controller 연결
    sr04_controller U_SR04 (
        .clk(clk),
        .rst(reset),
        // 위에서 만든 w_sr04_start 연결 (sw[3]=1 & btn_r 눌림)
        .start(w_sr04_start), 
        .echo(i_echo),
        .trigger(o_trig),
        .dist_data(w_distance),
        .done() // done 신호는 안 씀
    );

    // ASCII Sender
    ascii_sender U_ASCII_SENDER (
        .clk         (clk),
        .rst       (rst),
        .i_send_start(w_send_trigger),
        .i_tx_busy   (w_tx_busy),

        .i_mode(sw[3]),

        .i_distance(w_distance),
        .i_hour    (w_watch_time[23:19]),
        .i_min     (w_watch_time[18:13]),
        .i_sec     (w_watch_time[12:7]),
        .i_msec    (w_watch_time[6:0]),

        .o_tx_start(w_sender_tx_start),
        .o_tx_data (w_sender_data)
    );

    // (이하 모듈들은 동일)
    ascii_decoder U_ASCII (
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .ascii_data(w_ascii_data)
    );

    btn_debounce U_BTN_L (.clk(clk), .rst(reset), .i_btn(btn_l), .o_btn(o_btn_l));
    btn_debounce U_BTN_R (.clk(clk), .rst(reset), .i_btn(btn_r), .o_btn(o_btn_r));
    btn_debounce U_BTN_U (.clk(clk), .rst(reset), .i_btn(btn_u), .o_btn(o_btn_u));
    btn_debounce U_BTN_D (.clk(clk), .rst(reset), .i_btn(btn_d), .o_btn(o_btn_d));

    control_unit U_CONTROL (
        .clk(clk),
        .rst(reset),
        .i_sel_mode(sw[1]),
        .i_mode(sw[0]),
        // [중요] w_asc_btn[1]은 위에서 조건부 할당했으므로 거리 모드일 때는 0이 들어감 -> 오동작 방지
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
        .rst(reset),
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
        .rst(reset),
        .sel_display(sw[2]),
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

    fnd_controller U_FND_CNT (
        .clk(clk),
        .rst(reset),
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

module mux_sel_stopwatch_watch_distance (
    input [23:0] stopwatch_time,
    input [23:0] watch_time,
    input [15:0] distance,
    input [1:0] sel,
    output reg [23:0] fnd_in_data
);
    always @(*) begin
        case (sel)
            2'd0:
            fnd_in_data = stopwatch_time;  // sw[3]=0, sw[1]=0 (스톱워치)
            2'd1: fnd_in_data = watch_time;  // sw[3]=0, sw[1]=1 (시계)
            2'd2:
            fnd_in_data = {
                8'h00, distance
            };  // sw[3]=1 (거리, 상위비트 0채움)
            default: fnd_in_data = stopwatch_time;
        endcase
    end

endmodule

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

    wire w_tick_100hz, w_msec_tick;
    wire w_sec_tick, w_min_tick, w_hour_tick;


    tick_counter #(
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
    tick_counter #(
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
    tick_counter #(
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
    tick_counter #(
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
    tick_gen_100hz u_TICK (
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input rst,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH -1 : 0] o_count,
    output reg o_tick
);



    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign o_count = counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst | clear) begin
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



`timescale 1ns / 1ps

module top_uart_watch (
    input clk,
    input rst,
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

    wire [3:0] w_asc_btn;
    wire o_btn_l, o_btn_r, o_btn_u, o_btn_d;
    wire w_mode, w_run_stop, w_clear, w_up_l, w_up_r, w_down_u, w_down_d;
    wire w_change;
    wire [7:0] w_rx_data;  // UART RX로 받은 데이터
    wire w_rx_done;  // UART RX 완료 신호
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
    wire [3:0] w_control_in;
    assign w_asc_btn[0] = o_btn_l || w_control_in[2];  // ㅣ 과 연결   버튼과 데이터를 연결
    assign w_asc_btn[1] = o_btn_r || w_control_in[3];  // r 과 연결
    assign w_asc_btn[2] = o_btn_d || w_control_in[0];  // d 과 연결
    assign w_asc_btn[3] = o_btn_u || w_control_in[1];  // u 과 연결

    // [NEW] 's' 키 (0x73) 입력 감지 로직
    assign w_send_trigger = (w_rx_done && (w_rx_data == 8'h73));

    // [NEW] MUX Logic: Sender가 보낼 데이터가 있으면 Sender 것을, 아니면 Loopback(RX 데이터)을 보냄
    assign w_final_tx_data = (w_sender_tx_start) ? w_sender_data : w_rx_data;
    assign w_final_tx_start = w_sender_tx_start | w_rx_done;


    // [MODIFIED] UART TOP 연결 수정 (입력 포트가 늘어남)
    uart_top U_UART (
        .clk       (clk),
        .rst       (rst),
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
        .rst       (rst),
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



    btn_debounce U_BTN_L (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_l),
        .o_btn(o_btn_l)
    );
    btn_debounce U_BTN_R (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_r),
        .o_btn(o_btn_r)
    );
    btn_debounce U_BTN_U (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_u),
        .o_btn(o_btn_u)
    );
    btn_debounce U_BTN_D (
        .clk  (clk),
        .rst(rst),
        .i_btn(btn_d),
        .o_btn(o_btn_d)
    );

    control_unit U_CONTROL (
        .clk(clk),
        .rst(rst),
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
        .rst(rst),
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
        .rst(rst),
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
        .rst(rst),
        .sel_display(sw[2]),
        .fnd_in_data(w_fnd_in_data),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
    ascii_decoder U_ASCII (
        .clk(clk),
        .rst(rst),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .ascii_data(w_control_in)
    );

endmodule

module ascii_decoder (
    input clk,
    input rst,
    input [7:0] rx_data,
    input rx_done,
    output reg [3:0] ascii_data
);

    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            ascii_data <= 4'b0000;
        end else begin
            ascii_data <= 4'b0000;
            if (rx_done) begin
                case (rx_data)
                    8'h72:   ascii_data <= 4'b1000;          // r -> Run/Stop
                    8'h6c:   ascii_data <= 4'b0100;         // l -> Clear
                    8'h64:   ascii_data <= 4'b0001;          // d -> Down
                    8'h75:   ascii_data <= 4'b0010;          // u -> Up
                    default: ascii_data <= 4'b0000;
                endcase
            end
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

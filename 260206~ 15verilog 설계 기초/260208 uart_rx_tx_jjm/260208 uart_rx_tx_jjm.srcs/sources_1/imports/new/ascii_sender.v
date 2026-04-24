`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input reset,
    input i_send_start,  // 전송 시작 신호 (예: 's' 키 입력 시)
    input i_tx_busy,     // UART TX가 바쁜지 확인
    // 시계 데이터 입력
    input [4:0] i_hour,
    input [5:0] i_min,
    input [5:0] i_sec,
    input [6:0] i_msec,
    output reg o_tx_start,     // UART TX 시작 신호
    output reg [7:0] o_tx_data // 보낼 ASCII 데이터
);
    // 상태 정의
    localparam IDLE = 0;
    localparam SEND_CHAR = 1;
    localparam WAIT_TX = 2;
    reg [1:0] state;
    reg [3:0] char_index;  // 몇 번째 글자를 보내는지 (0 ~ 11)
    // 전송 도중 시간이 바뀌지 않도록 저장할 레지스터
    reg [4:0] r_hour;
    reg [5:0] r_min;
    reg [5:0] r_sec;
    reg [6:0] r_msec;
    // 각 자리수 추출 (십의 자리, 일의 자리)
    wire [3:0] w_h10, w_h1;
    wire [3:0] w_m10, w_m1;
    wire [3:0] w_s10, w_s1;
    wire [3:0] w_ms10, w_ms1;
    assign w_h10  = r_hour / 10;
    assign w_h1   = r_hour % 10;
    assign w_m10  = r_min / 10;
    assign w_m1   = r_min % 10;
    assign w_s10  = r_sec / 10;
    assign w_s1   = r_sec % 10;
    assign w_ms10 = r_msec / 10;
    assign w_ms1  = r_msec % 10;

    // ASCII 변환: 숫자 + 0x30 ('0')
    wire [7:0] ascii_h10 = {4'h3, w_h10}; //4'h3: 숫자 3을 뜻하는 4비트 (0011)w_h10: 현재 시간의 숫자 (예를 들어 2시라면 0010)
    wire [7:0] ascii_h1 = {4'h3, w_h1};
    wire [7:0] ascii_m10 = {4'h3, w_m10};
    wire [7:0] ascii_m1 = {4'h3, w_m1};
    wire [7:0] ascii_s10 = {4'h3, w_s10};
    wire [7:0] ascii_s1 = {4'h3, w_s1};
    wire [7:0] ascii_ms10 = {4'h3, w_ms10};
    wire [7:0] ascii_ms1 = {4'h3, w_ms1};

    // 구분자 및 제어 문자
    localparam CHAR_COLON = 8'h3A;  // ':'
    localparam CHAR_DOT = 8'h2E;  // '.'
    localparam CHAR_CR = 8'h0D;  // Carriage Return (엔터)
    localparam CHAR_LF = 8'h0A;  // Line Feed (줄바꿈)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            o_tx_start <= 0;
            o_tx_data <= 0;
            char_index <= 0;
            {r_hour, r_min, r_sec, r_msec} <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_tx_start <= 0;
                    char_index <= 0;
                    if (i_send_start && !i_tx_busy) begin
                        // 전송 시작 시 현재 시간 캡처 (스냅샷)
                        r_hour <= i_hour;
                        r_min  <= i_min;
                        r_sec  <= i_sec;
                        r_msec <= i_msec;
                        state  <= SEND_CHAR;
                    end
                end

                SEND_CHAR: begin
                    if (!i_tx_busy) begin // TX가 놀고 있을 때만 데이터 싣기
                        o_tx_start <= 1;  // Start 신호 발생

                        // 순서대로 데이터 선택 (MUX)
                        case (char_index)
                            0: o_tx_data <= ascii_h10;  // 시 (10)
                            1: o_tx_data <= ascii_h1;  // 시 (1)
                            2: o_tx_data <= CHAR_COLON;  // :
                            3: o_tx_data <= ascii_m10;  // 분 (10)
                            4: o_tx_data <= ascii_m1;  // 분 (1)
                            5: o_tx_data <= CHAR_COLON;  // :
                            6: o_tx_data <= ascii_s10;  // 초 (10)
                            7: o_tx_data <= ascii_s1;  // 초 (1)
                            8: o_tx_data <= CHAR_DOT;  // .
                            9: o_tx_data <= ascii_ms10;  // 밀리초 (10)
                            10: o_tx_data <= ascii_ms1;  // 밀리초 (1)
                            11: o_tx_data <= CHAR_CR;  // 엔터
                            12: o_tx_data <= CHAR_LF;  // 줄바꿈
                            default: o_tx_data <= 8'h20;  // 공백
                        endcase
                        state <= WAIT_TX;
                    end
                end

                WAIT_TX: begin
                    o_tx_start <= 0; // Start 신호는 1클럭만 유지하고 끔
                    // 1. tx_start를 주면 곧바로 busy가 1이 됨.
                    // 2. busy가 다시 0이 될 때까지 기다려야 함 (전송 완료 대기).
                    // 하지만 여기서는 간단히 다음 클럭에서 바로 busy 체크를 위해 넘어감
                    // (uart_tx 모듈 특성에 따라 딜레이가 필요할 수도 있음)

                    state <= SEND_CHAR;
                    if (char_index == 12) begin
                        state <= IDLE;  // 다 보냈으면 IDLE로
                    end else begin
                        char_index <= char_index + 1;  // 다음 글자 준비
                        // 여기서 바로 SEND_CHAR로 가면 너무 빠를 수 있으니
                        // i_tx_busy가 1이 된 것을 확인하고 기다리는 로직이 필요할 수 있음.
                        // 안전하게 busy가 풀릴때까지 기다리는 State를 추가하는게 좋음.
                        state <= 3;  // WAIT_BUSY_CLEAR state (아래 추가)
                    end
                end

                3: begin // WAIT_BUSY_CLEAR: 실제로 전송이 끝날 때까지 대기
                    if (i_tx_busy) begin
                        state <= 3;  // 바쁘면 계속 대기
                    end else begin
                        state <= SEND_CHAR; // 다 보냈으면 다음 글자 보내러 감
                    end
                end
            endcase
        end
    end

endmodule

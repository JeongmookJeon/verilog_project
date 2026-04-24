`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,
    input i_send_start,  // 전송 시작 트리거
    input i_tx_busy,     // UART 송신중
    // [추가됨] 모드 선택 (0: 시계 전송, 1: 거리 전송)
    // 이 신호는 Ascii_Decode나 메인 FSM에서 받아와야 합니다.
    input i_mode,        
    // 시간 데이터 입력
    input [4:0] i_hour,
    input [5:0] i_min,
    input [5:0] i_sec,
    input [6:0] i_msec,
    // [추가됨] 거리 데이터 입력 (SR04 Controller로부터)
    input [15:0] i_distance, 
    output reg o_tx_start,  // UART 전송 시작 신호
    output reg [7:0] o_tx_data  // 보낼 문자
);
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam STOP = 2'b10; // Busy 대기
    reg [1:0] state;
    reg [3:0] char_index; 
    // 데이터 캡처용 레지스터
    reg [4:0] r_hour;
    reg [5:0] r_min;
    reg [5:0] r_sec;
    reg [6:0] r_msec;
    reg [15:0] r_distance; // 거리 저장용
    reg r_current_mode;   // 전송 시작 시점의 모드 저장
    // 1. 시간 데이터 ASCII 변환
    wire [7:0] h10  = {4'h3, r_hour / 10};
    wire [7:0] h1   = {4'h3, r_hour % 10};
    wire [7:0] m10  = {4'h3, r_min / 10};
    wire [7:0] m1   = {4'h3, r_min % 10};
    wire [7:0] s10  = {4'h3, r_sec / 10};
    wire [7:0] s1   = {4'h3, r_sec % 10};
    wire [7:0] ms10 = {4'h3, r_msec / 10};
    wire [7:0] ms1  = {4'h3, r_msec % 10};
    // 2. 거리 데이터 ASCII 변환 (예: 123 -> "1", "2", "3")
    wire [7:0] d100 = {4'h3, (r_distance / 100) % 10};
    wire [7:0] d10  = {4'h3, (r_distance / 10) % 10};
    wire [7:0] d1   = {4'h3, r_distance % 10};
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            o_tx_start <= 0;
            o_tx_data <= 0;
            char_index <= 0;
            {r_hour, r_min, r_sec, r_msec} <= 0;
            r_distance <= 0;
            r_current_mode <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_tx_start <= 0;
                    char_index <= 0;
                    if (i_send_start && !i_tx_busy) begin
                        // 입력 데이터 캡처 (전송 중에 값이 바뀌지 않도록)
                        r_hour <= i_hour;
                        r_min  <= i_min;
                        r_sec  <= i_sec;
                        r_msec <= i_msec;
                        r_distance <= i_distance;
                        r_current_mode <= i_mode; // 모드도 캡처
                        state <= START;
                    end
                end
                START: begin
                    o_tx_start <= 1;
                    if (r_current_mode == 0) begin
                        case (char_index)
                            0: o_tx_data <= h10;
                            1: o_tx_data <= h1;
                            2: o_tx_data <= ":";
                            3: o_tx_data <= m10;
                            4: o_tx_data <= m1;
                            5: o_tx_data <= ":";
                            6: o_tx_data <= s10;
                            7: o_tx_data <= s1;
                            8: o_tx_data <= ".";
                            9: o_tx_data <= ms10;
                            10: o_tx_data <= ms1;
                            11: o_tx_data <= 8'h0D; // CR
                            12: o_tx_data <= 8'h0A; // LF
                            default: o_tx_data <= " ";
                        endcase
                    end else begin
                        // --- [MODE 1] 거리 전송 포맷: d=XXXcm\r\n (예시) ---
                        // 총 9글자: "d", "=", 100자리, 10자리, 1자리, "c", "m", CR, LF
                        case (char_index)
                            0: o_tx_data <= "d";
                            1: o_tx_data <= "=";
                            2: o_tx_data <= d100;
                            3: o_tx_data <= d10;
                            4: o_tx_data <= d1;
                            5: o_tx_data <= "c";
                            6: o_tx_data <= "m";
                            7: o_tx_data <= 8'h0D; // CR
                            8: o_tx_data <= 8'h0A; // LF
                            default: o_tx_data <= " ";
                        endcase
                    end
                    state <= STOP;
                end
                // [3] STOP: 전송 완료 대기 및 다음 글자 준비
                STOP: begin
                    o_tx_start <= 0;
                    if (!i_tx_busy) begin
                        // 현재 모드의 최대 글자 수에 도달했는지 확인
                        // 시계 모드는 12번 인덱스까지, 거리 모드는 8번 인덱스까지라고 가정
                        if ( (r_current_mode == 0 && char_index == 12) || 
                             (r_current_mode == 1 && char_index == 8) ) begin
                            state <= IDLE;
                        end else begin
                            char_index <= char_index + 1;
                            state <= START;
                        end
                    end
                end
            endcase
        end
    end
endmodule
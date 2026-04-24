`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input reset,

    input i_send_start,  // 's' 키 입력
    input i_tx_busy,     // UART 송신중 여부

    // 시간 데이터 입력
    input [4:0] i_hour,
    input [5:0] i_min,
    input [5:0] i_sec,
    input [6:0] i_msec,

    output reg o_tx_start,  // UART 전송 시작 신호
    output reg [7:0] o_tx_data  // 보낼 문자
);

    // =============================================================
    // 1. 상태 정의 (S 접두어 제거, WAIT -> STOP 변경)
    // =============================================================
    localparam IDLE = 0;  // 대기
    localparam START = 1;  // 전송 시작 (데이터 싣고 start 1)
    localparam STOP = 2;  // 전송 완료 대기 (잠시 멈춤)

    reg  [1:0] state;
    reg  [3:0] char_index;  // 몇 번째 글자인지 (0~12)

    // 시간 저장용 레지스터
    reg  [4:0] r_hour;
    reg  [5:0] r_min;
    reg  [5:0] r_sec;
    reg  [6:0] r_msec;

    // =============================================================
    // 2. 숫자 -> ASCII 변환 (조합 회로)
    // =============================================================
    wire [7:0] h10 = {4'h3, r_hour / 10};
    wire [7:0] h1 = {4'h3, r_hour % 10};
    wire [7:0] m10 = {4'h3, r_min / 10};
    wire [7:0] m1 = {4'h3, r_min % 10};
    wire [7:0] s10 = {4'h3, r_sec / 10};
    wire [7:0] s1 = {4'h3, r_sec % 10};
    wire [7:0] ms10 = {4'h3, r_msec / 10};
    wire [7:0] ms1 = {4'h3, r_msec % 10};

    // =============================================================
    // 3. FSM (상태 머신)
    // =============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            o_tx_start <= 0;
            o_tx_data <= 0;
            char_index <= 0;
            {r_hour, r_min, r_sec, r_msec} <= 0;
        end else begin
            case (state)

                // [1] IDLE: 평소에는 여기서 대기
                IDLE: begin
                    o_tx_start <= 0;
                    char_index <= 0;

                    if (i_send_start) begin        // 1. 일단 시작 신호가 왔는지 보고
                        if (!i_tx_busy) begin      // 2. 그 안에서 바쁜지 또 확인
                            r_hour <= i_hour;
                            r_min  <= i_min;
                            r_sec  <= i_sec;
                            r_msec <= i_msec;

                            state  <= START;  // 전송 시작하러 이동
                        end
                    end
                end

                // [2] START: 데이터를 싣고 "보내라!" 명령
                START: begin
                    o_tx_start <= 1;  // Start 신호 킴

                    // 글자 선택
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
                        11: o_tx_data <= 8'h0D;  // \r (Enter)
                        12: o_tx_data <= 8'h0A;  // \n (Line Feed)
                        default: o_tx_data <= " ";
                    endcase

                    state <= STOP;  // 명령 줬으니 멈춰서 대기
                end

                // [3] STOP: UART가 다 보낼 때까지 멈춤
                STOP: begin
                    o_tx_start <= 0;  // Start 신호 끔

                    // UART가 안 바쁘면(일 다 했으면) 다음 단계로
                    if (!i_tx_busy) begin
                        if (char_index == 12) begin
                            state <= IDLE;  // 다 보냈으면 끝
                        end else begin
                            char_index <= char_index + 1; // 다음 글자 준비
                            state <= START;  // 다시 보내러 감
                        end
                    end
                    // 바쁘면(i_tx_busy=1) 계속 이 상태(STOP)에 머무름
                end

            endcase
        end
    end

endmodule

`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,

    input i_send_start,  // 's' 키 입력 시 시작
    input i_tx_busy,     // UART TX가 바쁜지 확인

    // 시계 데이터 입력
    input [4:0] i_hour,
    input [5:0] i_min,
    input [5:0] i_sec,
    input [6:0] i_msec,

    output reg o_tx_start,    // UART TX 시작 신호
    output reg [7:0] o_tx_data // 보낼 ASCII 데이터
);

    // =============================================================
    // 1. 상태 정의 (IDLE - START - DATA - STOP 4단계 유지)
    // =============================================================
    localparam IDLE  = 2'd0;
    localparam START = 2'd1; // 데이터 준비 & 바쁘면 대기 & 발사
    localparam DATA  = 2'd2; // 전송 완료 확인 (Handshake)
    localparam STOP  = 2'd3; // 다음 글자 판단

    // =============================================================
    // 2. 레지스터 선언
    // =============================================================
    reg [1:0] c_state, n_state;
    
    // 출력 및 제어용 레지스터 (Next/Current 분리)
    reg o_tx_start_next;
    reg [7:0] o_tx_data_next;
    reg [3:0] char_index_reg, char_index_next;
    reg busy_flag_reg, busy_flag_next; 

    // 시간 스냅샷
    reg [4:0] r_hour_reg, r_hour_next;
    reg [5:0] r_min_reg, r_min_next;
    reg [5:0] r_sec_reg, r_sec_next;
    reg [6:0] r_msec_reg, r_msec_next;

    // =============================================================
    // 3. ASCII 변환 (안전한 덧셈 방식)
    // =============================================================
    wire [7:0] h10 = (r_hour_reg / 10) + 8'h30;
    wire [7:0] h1  = (r_hour_reg % 10) + 8'h30;
    wire [7:0] m10 = (r_min_reg  / 10) + 8'h30;
    wire [7:0] m1  = (r_min_reg  % 10) + 8'h30;
    wire [7:0] s10 = (r_sec_reg  / 10) + 8'h30;
    wire [7:0] s1  = (r_sec_reg  % 10) + 8'h30;
    wire [7:0] ms10= (r_msec_reg / 10) + 8'h30;
    wire [7:0] ms1 = (r_msec_reg % 10) + 8'h30;

    // =============================================================
    // 4. Sequential Logic
    // =============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state            <= IDLE;
            o_tx_start         <= 1'b0;
            o_tx_data          <= 8'h00;
            char_index_reg     <= 4'd0;
            busy_flag_reg      <= 1'b0;
            
            r_hour_reg <= 5'd0;
            r_min_reg  <= 6'd0;
            r_sec_reg  <= 6'd0;
            r_msec_reg <= 7'd0;
        end else begin
            c_state            <= n_state;
            o_tx_start         <= o_tx_start_next;
            o_tx_data          <= o_tx_data_next;
            char_index_reg     <= char_index_next;
            busy_flag_reg      <= busy_flag_next;

            r_hour_reg <= r_hour_next;
            r_min_reg  <= r_min_next;
            r_sec_reg  <= r_sec_next;
            r_msec_reg <= r_msec_next;
        end
    end

    // =============================================================
    // 5. Combinational Logic (Next State Logic)
    // =============================================================
    always @(*) begin
        // 기본값 (Latch 방지)
        n_state             = c_state;
        o_tx_start_next     = o_tx_start;
        o_tx_data_next      = o_tx_data;
        char_index_next     = char_index_reg;
        busy_flag_next      = busy_flag_reg;
        
        r_hour_next = r_hour_reg;
        r_min_next  = r_min_reg;
        r_sec_next  = r_sec_reg;
        r_msec_next = r_msec_reg;

        case (c_state)
            // -----------------------------------------------------
            // [IDLE] 시작 신호 대기
            // -----------------------------------------------------
            IDLE: begin
                o_tx_start_next = 1'b0;
                char_index_next = 4'd0;
                busy_flag_next  = 1'b0;

                if (i_send_start) begin
                    // 시간 캡처
                    r_hour_next = i_hour;
                    r_min_next  = i_min;
                    r_sec_next  = i_sec;
                    r_msec_next = i_msec;
                    
                    n_state = START;
                end
            end

            // -----------------------------------------------------
            // [START] 데이터 준비 & "Busy 확인 후" 발사 (핵심 수정!)
            // -----------------------------------------------------
            START: begin
                busy_flag_next = 1'b0; // DATA 상태용 플래그 초기화

                // 1. 데이터 준비 (항상 수행)
                case (char_index_reg)
                    0:  o_tx_data_next = h10;
                    1:  o_tx_data_next = h1;
                    2:  o_tx_data_next = ":";
                    3:  o_tx_data_next = m10;
                    4:  o_tx_data_next = m1;
                    5:  o_tx_data_next = ":";
                    6:  o_tx_data_next = s10;
                    7:  o_tx_data_next = s1;
                    8:  o_tx_data_next = ".";
                    9:  o_tx_data_next = ms10;
                    10: o_tx_data_next = ms1;
                    11: o_tx_data_next = 8'h0D;
                    12: o_tx_data_next = 8'h0A;
                    default: o_tx_data_next = " ";
                endcase

                // 2. 발사 여부 결정 (여기가 포인트)
                // 's'가 Echo 되느라 UART가 바쁘면(Busy=1), 쏘지 말고 대기
                if (i_tx_busy) begin
                    o_tx_start_next = 1'b0; 
                    n_state = START;  // 바쁜 게 풀릴 때까지 START에서 맴돔
                end else begin
                    // 안 바쁘면 발사!
                    o_tx_start_next = 1'b1; 
                    n_state = DATA;
                end
            end

            // -----------------------------------------------------
            // [DATA] 전송 완료 대기 (Handshake)
            // -----------------------------------------------------
            DATA: begin
                o_tx_start_next = 1'b0; // Pulse 내림

                // Start를 줬으니 UART가 Busy가 되었는지 확인
                if (i_tx_busy) begin
                    busy_flag_next = 1'b1;
                end

                // Busy였다가(flag=1) 다시 한가해지면(!busy) 완료
                if (busy_flag_reg == 1'b1 && i_tx_busy == 1'b0) begin
                    n_state = STOP;
                end
            end

            // -----------------------------------------------------
            // [STOP] 다음 글자 판단
            // -----------------------------------------------------
            STOP: begin
                if (char_index_reg == 12) begin
                    n_state = IDLE;
                end else begin
                    char_index_next = char_index_reg + 1;
                    n_state = START; // 다음 글자 쏘러 START로
                end
            end

            default: n_state = IDLE;
        endcase
    end

endmodule
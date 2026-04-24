`timescale 1ns / 1ps

module btn_avg_controller (
    input clk,
    input rst,
    input btn_r,          // 🔥 핵심: 우측 버튼
    
    // 모드 확인 (해당 모드일 때만 센서를 켬)
    input mode_sr04,      // sw[3]=1, sw[4]=0
    input mode_dht11,     // sw[4]=1
    
    // 센서에서 실시간으로 올라오는 원본 데이터
    input [15:0] i_distance,
    input [15:0] i_temperature,
    input [15:0] i_humidity,

    // 센서로 보내는 시작 펄스 (기존 btn_r을 대체함)
    output reg o_sr04_start,
    output reg o_dht11_start,

    // 2초 뒤에 완성되는 깔끔한 평균 데이터
    output reg [15:0] o_avg_distance,
    output reg [15:0] o_avg_temperature,
    output reg [15:0] o_avg_humidity
);

    // 1ms(밀리초) 틱 생성기 (100MHz 기준 100,000 클럭)
    reg [16:0] tick_cnt;
    wire tick_1ms = (tick_cnt == 100_000 - 1);

    // 2초(2000ms)를 세는 타이머
    reg [11:0] ms_timer; 

    // 더하기(누적)용 임시 저장소 (넘침 방지를 위해 비트 수를 넉넉하게 20비트로 잡음)
    reg [19:0] sum_dist;
    reg [16:0] sum_temp;
    reg [16:0] sum_hum;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt <= 0; ms_timer <= 0;
            o_sr04_start <= 0; o_dht11_start <= 0;
            sum_dist <= 0; sum_temp <= 0; sum_hum <= 0;
            o_avg_distance <= 0; o_avg_temperature <= 0; o_avg_humidity <= 0;
        end else begin
            // ----------------------------------------------------
            // 1. 버튼을 누르고 있는 동안 타이머 굴리기
            // ----------------------------------------------------
            if (btn_r) begin
                if (tick_1ms) begin
                    tick_cnt <= 0;
                    if (ms_timer < 2000) ms_timer <= ms_timer + 1; // 2000ms(2초)까지만 셈
                end else begin
                    tick_cnt <= tick_cnt + 1;
                end
            end else begin
                // 버튼에서 손을 떼면 타이머와 누적값 즉시 초기화
                tick_cnt <= 0; ms_timer <= 0;
                sum_dist <= 0; sum_temp <= 0; sum_hum <= 0;
            end

            // 기본적으로 시작 신호는 0으로 끔 (1클럭 펄스 생성용)
            o_sr04_start <= 0;
            o_dht11_start <= 0;

            // ----------------------------------------------------
            // 2. 2초 동안 센서 측정 및 누적 (버튼을 누르고 있을 때만)
            // ----------------------------------------------------
            if (btn_r) begin
                
                // [SR04 초음파 모드]
                if (mode_sr04) begin
                    // 125ms 마다 한 번씩 쏜다 (총 16번 발사)
                    if (tick_1ms && (ms_timer % 125 == 0) && ms_timer < 2000) begin
                        o_sr04_start <= 1;
                    end
                    // 쏘고 나서 60ms 뒤에 메아리가 돌아오면 값을 누적함
                    if (tick_1ms && (ms_timer % 125 == 60) && ms_timer < 2000) begin
                        // (안전장치 내장) 400 이상 튀면 400으로 치고 더함
                        sum_dist <= sum_dist + ((i_distance > 400) ? 16'd400 : i_distance);
                    end
                end
                
                // [DHT11 온습도 모드]
                if (mode_dht11) begin
                    // 0초, 1초일 때 한 번씩 쏜다 (총 2번 발사)
                    if (tick_1ms && (ms_timer == 0 || ms_timer == 1000)) begin
                        o_dht11_start <= 1;
                    end
                    // 쏘고 나서 500ms 뒤에 측정 완료되면 값을 누적함
                    if (tick_1ms && (ms_timer == 500 || ms_timer == 1500)) begin
                        sum_temp <= sum_temp + i_temperature;
                        sum_hum <= sum_hum + i_humidity;
                    end
                end

                // ----------------------------------------------------
                // 3. 2초(2000ms) 도달 시! 마법의 비트 시프트(평균) 계산
                // ----------------------------------------------------
                if (tick_1ms && ms_timer == 1999) begin
                    if (mode_sr04) begin
                        o_avg_distance <= sum_dist >> 4;    // 16번 더했으니 16으로 나눔
                    end
                    if (mode_dht11) begin
                        o_avg_temperature <= sum_temp >> 1; // 2번 더했으니 2로 나눔
                        o_avg_humidity <= sum_hum >> 1;     // 2번 더했으니 2로 나눔
                    end
                end
            end
        end
    end
endmodule
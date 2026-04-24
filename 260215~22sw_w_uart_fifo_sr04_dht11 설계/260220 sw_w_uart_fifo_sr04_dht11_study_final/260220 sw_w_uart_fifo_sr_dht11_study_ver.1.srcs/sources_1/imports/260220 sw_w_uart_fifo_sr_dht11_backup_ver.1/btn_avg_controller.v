`timescale 1ns / 1ps

module btn_avg_controller (
    input clk,
    input rst,
    input btn_r,          // 우측 버튼 (1클럭 펄스)
    
    input mode_sr04,      
    input mode_dht11,     
    
    input [15:0] i_distance,
    input [15:0] i_temperature,
    input [15:0] i_humidity,

    output reg o_sr04_start,
    output reg o_dht11_start,

    output reg [15:0] o_avg_distance,
    output reg [15:0] o_avg_temperature,
    output reg [15:0] o_avg_humidity
);
    reg [11:0] ms_timer; 
    reg [6:0]  sr04_timer; 

    reg [19:0] sum_dist;
    reg [16:0] sum_temp;
    reg [16:0] sum_hum;

    // 🔥 [핵심 추가] '측정 중' 상태를 기억하는 플래그 변수
    reg is_measuring; 

    wire tick_1ms; 

    tick_gen_1khz U_TICK_GEN_1KHZ(
        .clk(clk),
        .rst(rst),
        .o_1khz(tick_1ms)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ms_timer <= 0; sr04_timer <= 0;
            o_sr04_start <= 0; o_dht11_start <= 0;
            sum_dist <= 0; sum_temp <= 0; sum_hum <= 0;
            o_avg_distance <= 0; o_avg_temperature <= 0; o_avg_humidity <= 0;
            is_measuring <= 0; // 초기 상태는 측정 안 함
        end else begin
            
            o_sr04_start <= 0;
            o_dht11_start <= 0;

            // ----------------------------------------------------
            // 1. 버튼을 '딸깍' 누르면 2초 측정 스위치 ON!
            // ----------------------------------------------------
            if (btn_r && !is_measuring) begin
                is_measuring <= 1; // 측정 시작!
                ms_timer <= 0;
                sr04_timer <= 0;
                sum_dist <= 0;
                sum_temp <= 0;
                sum_hum <= 0;
            end

            // ----------------------------------------------------
            // 2. '측정 중'일 때만 타이머가 굴러가며 센서를 읽음
            // ----------------------------------------------------
            if (is_measuring) begin
                if (tick_1ms) begin 
                    ms_timer <= ms_timer + 1; 
                    if (sr04_timer == 124) sr04_timer <= 0;
                    else sr04_timer <= sr04_timer + 1;
                end

                // [SR04 초음파 모드]
                if (mode_sr04) begin
                    if (tick_1ms && sr04_timer == 0) o_sr04_start <= 1;
                    if (tick_1ms && sr04_timer == 60) begin
                        sum_dist <= sum_dist + ((i_distance > 400) ? 16'd400 : i_distance);
                    end
                end
                
                // [DHT11 온습도 모드]
                if (mode_dht11) begin
                    if (tick_1ms && (ms_timer == 0 || ms_timer == 1000)) o_dht11_start <= 1;
                    if (tick_1ms && (ms_timer == 500 || ms_timer == 1500)) begin
                        sum_temp <= sum_temp + i_temperature;
                        sum_hum <= sum_hum + i_humidity;
                    end
                end

                // ----------------------------------------------------
                // 3. 2초 도달 시! 평균 계산 후 자동으로 스위치 OFF
                // ----------------------------------------------------
                if (tick_1ms && ms_timer == 1999) begin
                    if (mode_sr04)  o_avg_distance <= sum_dist >> 4; 
                    if (mode_dht11) begin
                        o_avg_temperature <= sum_temp >> 1; 
                        o_avg_humidity <= sum_hum >> 1;    
                    end
                    is_measuring <= 0; // 측정 끝! 다시 대기 상태로.
                end
            end
        end
    end
endmodule

module tick_gen_1khz (
    input clk,
    input rst,
    output reg o_1khz
);
    parameter F_COUNT = 100_000; 

    reg [$clog2(F_COUNT) - 1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_1khz <= 1'b0; // b_tick 오타 수정
        end else begin
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule
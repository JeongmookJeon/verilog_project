`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input rst,

    input i_send_start,  
    input i_tx_busy,     

    input [1:0]  i_mode,      
    input [15:0] i_distance,
    input [15:0] i_temperature, 
    input [15:0] i_humidity,    
    input [ 4:0] i_hour,
    input [ 5:0] i_min,
    input [ 5:0] i_sec,
    input [ 6:0] i_msec,

    output reg o_tx_start,      
    output reg [7:0] o_tx_data  
);

    localparam IDLE  = 3'd0; 
    localparam START = 3'd1;  
    localparam CALC  = 3'd2; // 파이프라인 1단계
    localparam DATA  = 3'd3; // 파이프라인 2단계
    localparam STOP  = 3'd4;  

    reg [2:0] c_state, n_state;

    reg o_tx_start_next;
    reg [7:0] o_tx_data_next;
    
    // 깔끔해진 레지스터 이름들!
    reg [3:0] char_index_reg, char_index_next;
    reg [7:0] char_data_reg,  char_data_next;

    reg [1:0]  mode_reg,        mode_next;
    reg [15:0] distance_reg,    distance_next;
    reg [15:0] temperature_reg, temperature_next;
    reg [15:0] humidity_reg,    humidity_next;
    reg [4:0]  hour_reg,        hour_next;
    reg [5:0]  min_reg,         min_next;
    reg [5:0]  sec_reg,         sec_next;
    reg [6:0]  msec_reg,        msec_next;

    // [순차 회로]
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state          <= IDLE;
            o_tx_start       <= 1'b0;
            o_tx_data        <= 8'h00;
            char_index_reg   <= 4'd0;
            char_data_reg    <= 8'h00; 
            mode_reg         <= 2'd0;
            distance_reg     <= 16'd0;
            temperature_reg  <= 16'd0;
            humidity_reg     <= 16'd0;
            {hour_reg, min_reg, sec_reg, msec_reg} <= 0;
        end else begin
            c_state          <= n_state;
            o_tx_start       <= o_tx_start_next;
            o_tx_data        <= o_tx_data_next;
            char_index_reg   <= char_index_next;
            char_data_reg    <= char_data_next; 
            mode_reg         <= mode_next;
            distance_reg     <= distance_next;
            temperature_reg  <= temperature_next;
            humidity_reg     <= humidity_next;
            hour_reg         <= hour_next;
            min_reg          <= min_next;
            sec_reg          <= sec_next;
            msec_reg         <= msec_next;
        end
    end

    // [조합 회로]
    always @(*) begin
        n_state          = c_state;
        o_tx_start_next  = 1'b0;   
        o_tx_data_next   = o_tx_data;
        
        char_index_next  = char_index_reg;
        char_data_next   = char_data_reg;

        mode_next        = mode_reg;
        distance_next    = distance_reg;
        temperature_next = temperature_reg;
        humidity_next    = humidity_reg;
        hour_next        = hour_reg;
        min_next         = min_reg;
        sec_next         = sec_reg;
        msec_next        = msec_reg;

        case (c_state)
            IDLE: begin
                char_index_next = 4'd0;
                if (i_send_start) begin
                    mode_next        = i_mode;
                    distance_next    = i_distance;
                    temperature_next = i_temperature;
                    humidity_next    = i_humidity;
                    hour_next        = i_hour;
                    min_next         = i_min;
                    sec_next         = i_sec;
                    msec_next        = i_msec;
                    n_state          = START;
                end
            end

            START: begin
                if (i_tx_busy) n_state = START; 
                else           n_state = CALC; 
            end

            CALC: begin
                if (mode_reg == 2'd0) begin  // 시계 모드
                    case (char_index_reg)
                        0: char_data_next = (hour_reg / 10) + 8'h30;
                        1: char_data_next = (hour_reg % 10) + 8'h30;
                        2: char_data_next = ":";  
                        3: char_data_next = (min_reg / 10) + 8'h30;
                        4: char_data_next = (min_reg % 10) + 8'h30;
                        5: char_data_next = ":";
                        6: char_data_next = (sec_reg / 10) + 8'h30;  
                        7: char_data_next = (sec_reg % 10) + 8'h30;
                        8: char_data_next = ".";  
                        9: char_data_next = (msec_reg / 10) + 8'h30;
                        10: char_data_next = (msec_reg % 10) + 8'h30; 
                        11: char_data_next = 8'h0D; // CR
                        12: char_data_next = 8'h0A; // LF
                        default: char_data_next = " ";
                    endcase
                end else if (mode_reg == 2'd1) begin  // 거리 모드
                    case (char_index_reg)
                        0: char_data_next = "d";  
                        1: char_data_next = "=";
                        2: char_data_next = ((distance_reg / 100) % 10) + 8'h30; 
                        3: char_data_next = ((distance_reg / 10) % 10) + 8'h30;
                        4: char_data_next = (distance_reg % 10) + 8'h30;   
                        5: char_data_next = "c";
                        6: char_data_next = "m";  
                        7: char_data_next = 8'h0D; 
                        8: char_data_next = 8'h0A; 
                        default: char_data_next = " ";
                    endcase
                end else if (mode_reg == 2'd2) begin  // 온도 모드
                    case (char_index_reg)
                        0: char_data_next = "T";  
                        1: char_data_next = "=";
                        2: char_data_next = ((temperature_reg[15:8] / 10) % 10) + 8'h30; 
                        3: char_data_next = (temperature_reg[15:8] % 10) + 8'h30; 
                        4: char_data_next = ".";                                 
                        5: char_data_next = ((temperature_reg[7:0] / 10) % 10) + 8'h30; 
                        6: char_data_next = (temperature_reg[7:0] % 10) + 8'h30; 
                        7: char_data_next = "C";  
                        8: char_data_next = 8'h0D; 
                        9: char_data_next = 8'h0A; 
                        default: char_data_next = " ";
                    endcase
                end else begin  // 습도 모드
                    case (char_index_reg)
                        0: char_data_next = "H";  
                        1: char_data_next = "=";
                        2: char_data_next = ((humidity_reg[15:8] / 10) % 10) + 8'h30; 
                        3: char_data_next = (humidity_reg[15:8] % 10) + 8'h30; 
                        4: char_data_next = ".";                                 
                        5: char_data_next = ((humidity_reg[7:0] / 10) % 10) + 8'h30; 
                        6: char_data_next = (humidity_reg[7:0] % 10) + 8'h30; 
                        7: char_data_next = "%";  
                        8: char_data_next = 8'h0D; 
                        9: char_data_next = 8'h0A; 
                        default: char_data_next = " ";
                    endcase
                end
                
                n_state = DATA; 
            end

            DATA: begin
                o_tx_data_next  = char_data_reg; 
                o_tx_start_next = 1'b1;            
                n_state         = STOP;
            end

            STOP: begin
                if ((mode_reg == 2'd0 && char_index_reg == 4'd12) || 
                    (mode_reg == 2'd1 && char_index_reg == 4'd8)  ||
                    (mode_reg >= 2'd2 && char_index_reg == 4'd9)) begin
                    n_state = IDLE; 
                end else begin
                    char_index_next = char_index_reg + 1; 
                    n_state = START; 
                end
            end

            default: n_state = IDLE;
        endcase
    end

endmodule
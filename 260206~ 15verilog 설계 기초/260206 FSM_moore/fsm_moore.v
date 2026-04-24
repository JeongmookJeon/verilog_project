`timescale 1ns / 1ps

module fsm_moore (
    input clk,
    input reset,
    input [2:0] sw,
    output [2:0] led 
);
    
    parameter S0 = 3'd0, S1 = 3'd1;
    parameter S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;
    
    reg [2:0] current_st, next_st;

    reg[2:0] current_led, next_led; 

    

    assign led = current_led;


    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= S0;
            current_led <= 3'b000; 
        end else begin
            current_st <= next_st;
            current_led <=next_led; 
        end
    end
    always @(*) begin
        next_st = current_st;  
        next_led = current_led; 
        case (current_st)
            S0: begin
                
                next_led = 3'b000; 
                if (sw == 3'b001) begin
                    next_st = S1;
                end else if (sw == 3'b010) begin
                    next_st = S2;
                end
            end
            S1: begin
                next_led = 3'b001;
                if (sw == 3'b010) begin
                    next_st = S2;
                end
            end
            S2: begin
                next_led = 3'b010;
                if (sw == 3'b100) begin
                    next_st = S3;
                end
            end
            S3: begin
                next_led = 3'b100;
                if (sw == 3'b000) begin
                    next_st = S0;
                end else if (sw === 3'b011) begin
                    next_st = S1;
                end else if (sw === 3'b111) begin
                    next_st = S4;
                end else begin
                    next_st = current_st;
                end
            end
            S4: begin
                next_led = 3'b000;
                if (sw == 3'b000) begin
                    next_st = S0;
                end
            end
            default: next_st = current_st;
        endcase
    end
endmodule

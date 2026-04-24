`timescale 1ns / 1ps

module fsm_0101_mealy(
    input clk,
    input reset,
    input din_bit,
    output dout_bit
);
    
    localparam S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3;

    
    reg [1:0] current_state, next_state; 

    
    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            current_state <= S0; 
        end else begin
            current_state <= next_state;
        end
    end

    
    always @(*) begin
        case (current_state)
            S0 : begin
                if (din_bit == 1) begin
                    next_state = S0; 
                end else begin
                    next_state = S1; 
                end
            end
            S1 : begin
                if (din_bit == 1) begin  
                    next_state = S2;
                end else begin 
                    next_state = S1;
                end
            end
            S2 : begin
                if (din_bit == 1) begin
                    next_state = S0;
                end else begin
                    next_state = S3;
                end
            end
            S3 : begin
                if (din_bit == 1) begin
                    next_state = S0;
                end else begin
                    next_state = S1;
                end
            end
            default : next_state = current_state;
        endcase
    end

    
    assign dout_bit = ((current_state == S3) && (din_bit == 1));

endmodule

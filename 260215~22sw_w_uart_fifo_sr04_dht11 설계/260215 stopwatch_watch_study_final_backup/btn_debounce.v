`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    parameter CLK_DIV = 100_000;  // 100khz 틱 생성 10us
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_r;
    reg CLK_100khz;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r  <= 0;
            CLK_100khz <= 1'b0;
        end else begin
            if (counter_r == F_COUNT - 1) begin
                counter_r  <= 0;
                CLK_100khz <= 1'b1;
            end else begin
                counter_r  <= counter_r + 1;
                CLK_100khz <= 1'b0;
            end
        end
    end
    reg [7:0] q_reg, q_next;

    always @(posedge CLK_100khz, posedge rst) begin
        if (rst) begin
            q_reg <= 8'b0;
        end else begin
            q_reg <= q_next;
        end
    end
    always@(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end
    wire debounce;
    assign debounce = &q_reg;
    reg edge_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    assign o_btn = debounce & (~edge_reg);
endmodule

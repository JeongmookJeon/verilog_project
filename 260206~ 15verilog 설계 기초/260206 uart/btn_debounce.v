`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    //series 8 tap DFF 

    reg [7:0] debounce_reg;
    wire debounce;

    //SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            debounce_reg <= 0;
        end else begin
            //입력을 MSB에 두고 나머지 하나씩 미루기 (bit_shift)
            debounce_reg <= {
                i_btn, debounce_reg[7:1]
            };  //마지막 bit은 버리기
        end
    end

    /*SL 다른 방법으로 만드는 코드
always @(posedge clk, posedge reset) begin
    if(reset) begin
        q_reg <=0;
    end else begin
        q_reg <= q_next;
        // debounce_reg<={i_btn, debounce_reg[7:1]}
    end
end
//next CL
always @(*) begin
    q_next = {i_btn, q_reg[7:1]};
end
*/

    // generate debounce signal, 8input AND
    assign debounce = &debounce_reg;

    reg edge_reg;  // 100MHz DFF

    //edge detection
    always @(posedge clk, posedge rst) begin
        if (rst) edge_reg <= 0;
        else edge_reg <= debounce;
    end

    //rising edge out btn
    assign o_btn = debounce & (~edge_reg);
endmodule
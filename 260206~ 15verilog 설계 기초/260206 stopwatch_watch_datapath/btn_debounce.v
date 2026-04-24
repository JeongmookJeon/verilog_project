`timescale 1ns / 1ps

module btn_debounce (  // 완료
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    //clock divider for debounce shift register
    //100Mhz -> 100Khz  100,000을 나누먄 됨.
    //counter = 100를 100K = 1000
    // 100mhz의 클럭을 1khz마다 한번씩 신호를 발생시키는 분주기 로직 즉 1khz 틱생성 
    parameter CLK_DIV = 100_000; //10; //100_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg CLK_100khz_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            CLK_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                CLK_100khz_reg <= 1'b1;
            end else begin
                CLK_100khz_reg <= 1'b0;
            end
        end

    end

    wire o_btn_down_u, o_btn_down_d;  // 디바운싱된 신호를 담을 전선

    //series 8 tap F/F   8개 짜리 플립플롭 사용(검증하기 위함)

    reg [7:0] q_reg, q_next;
    wire debounce;
    //SL
    always @(posedge CLK_100khz_reg, posedge reset) begin
        if (reset) begin
            q_reg <= 0;  // 초기값 생성
        end else begin
            //register 생성
            q_reg <= q_next;
            //debounce_reg <= {i_btn, debounce_reg[7:1]};
        end
    end
    // next CL
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};  // shift register 동작.

    end

    //debounce 신호, 8bit input, And gate활용
    assign debounce = &q_reg; // 비트별로 전부 and한다라는 뜻. q_reg가 8비트이기 대문에
    reg edge_reg;
    //edge detection
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_reg);  // 반전된 reg와 and함.

endmodule

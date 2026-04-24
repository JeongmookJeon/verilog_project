`timescale 1ns / 1ps

module ascii_decoder (
    input        clk,
    input        rst,
    input  [7:0] rx_data,
    input        rx_done,

    output       ascii_btn_r, // run / stop
    output       ascii_btn_l, // left
    output       ascii_btn_u, // up
    output       ascii_btn_d, // down
    output       ascii_btn_m  // clear (middle)
);

    reg r_reg, l_reg, u_reg, d_reg, m_reg;

    assign ascii_btn_r = r_reg;
    assign ascii_btn_l = l_reg;
    assign ascii_btn_u = u_reg;
    assign ascii_btn_d = d_reg;
    assign ascii_btn_m = m_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_reg <= 1'b0;
            l_reg <= 1'b0;
            u_reg <= 1'b0;
            d_reg <= 1'b0;
            m_reg <= 1'b0;
        end else begin
            // 기본값: 모든 버튼 0 (1-tick 펄스)
            r_reg <= 1'b0;
            l_reg <= 1'b0;
            u_reg <= 1'b0;
            d_reg <= 1'b0;
            m_reg <= 1'b0;

            if (rx_done) begin
                case (rx_data)
                    8'h72: r_reg <= 1'b1; // 'r'
                    8'h6C: l_reg <= 1'b1; // 'l'
                    8'h75: u_reg <= 1'b1; // 'u'
                    8'h64: d_reg <= 1'b1; // 'd'
                    8'h63: m_reg <= 1'b1; // 'c'
                    default: ;           // 다른 문자는 무시
                endcase
            end
        end
    end

endmodule

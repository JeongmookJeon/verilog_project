`timescale 1ns / 1ps

module adder_1_10 (
    input clk,
    input rst,
    output [7:0] out
);
    logic isrcsel, sumsrcsel, iload, sumload, alusrcsel, outload, ilq10;
    control_unit U_CONTROL_UNIT (.*);
    datapath U_DATAPATH (.*);

endmodule

module control_unit (
    input        clk,
    input        rst,
    input        ilq10,
    output logic isrcsel,
    output logic sumsrcsel,
    output logic iload,
    output logic sumload,
    output logic alusrcsel,
    output logic outload
);
    typedef enum logic [2:0] {
        s0,
        s1,
        s2,
        s3,
        s4,
        s5
    } state_t;
    state_t c_state, n_state;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= s0;
        end else begin
            c_state <= n_state;
        end
    end
    //next, output
    always_comb begin
        n_state   = c_state;
        isrcsel   = 0;
        sumsrcsel = 0;
        iload     = 0;
        sumload   = 0;
        alusrcsel = 0;
        outload   = 0;
        case (c_state)
            s0: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = s1;
            end
            s1: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                if (ilq10 == 1) n_state = s2;
                else n_state = s5;
            end
            s2: begin
                isrcsel   = 0;
                sumsrcsel = 1;
                iload     = 0;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = s3;
            end
            s3: begin
                isrcsel   = 1;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 0;
                alusrcsel = 1;
                outload   = 0;
                n_state   = s4;
            end
            s4: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 1;
                n_state   = s1;
            end
            s5: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
            end
        endcase
    end
endmodule


module datapath (
    input        clk,
    input        rst,
    input        isrcsel,
    input        sumsrcsel,
    input        iload,
    input        sumload,
    input        alusrcsel,
    input        outload,
    output       ilq10,
    output [7:0] out
);

    logic [7:0]
        ireg_src_data,
        sumreg_src_data,
        ireg_out,
        sumreg_out,
        alu_src_data,
        alu_out;

    register U_OUTREGISTER (
        .clk     (clk),
        .rst     (rst),
        .load    (outload),
        .in_data (sumreg_out),
        .out_data(out)
    );

    mux2x1 U_IREG_SRC_MUX (  // 1이면  alu출력, 0이면 a(0)출력
        .a      (0),
        .b      (alu_out),
        .sel    (isrcsel),
        .mux_out(ireg_src_data)
    );

    register U_REGISTER (
        .clk     (clk),
        .rst     (rst),
        .load    (iload),
        .in_data (ireg_src_data),
        .out_data(ireg_out)
    );

    mux2x1 U_SUMREG_SRC_MUX (  // 1이면  alu출력, 0이면 a(0)출력
        .a      (0),
        .b      (alu_out),
        .sel    (sumsrcsel),
        .mux_out(sumreg_src_data)
    );

    register U_SUMREGISTER (
        .clk     (clk),
        .rst     (rst),
        .load    (sumload),
        .in_data (sumreg_src_data),
        .out_data(sumreg_out)
    );

    mux2x1 U_ALU_SRC_MUX (  // 1이면  alu출력, 0이면 a(0)출력
        .a      (sumreg_out),
        .b      (1),
        .sel    (alusrcsel),
        .mux_out(alu_src_data)
    );

    alu U_ALU (  // a+b 모듈
        .a      (ireg_out),      // from ireg
        .b      (alu_src_data),  //from sumreg
        .alu_out(alu_out)
    );

    ilq10_comp U_ALU_COMP (  // 10 비교기
        .in_data(ireg_out),
        .ilq10  (ilq10)
    );


endmodule

module ilq10_comp (  // 10 비교기
    input  [7:0] in_data,
    output       ilq10
);
    assign ilq10 = (in_data <= 10);
endmodule

module mux2x1 (  // 1이면  alu출력, 0이면 a(0)출력
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);
    assign mux_out = (sel) ? b : a;
endmodule



module register (
    input              clk,
    input              rst,
    input              load,
    input        [7:0] in_data,
    output logic [7:0] out_data
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_data <= 0;
        end else begin
            if (load) begin
                out_data <= in_data;
            end
        end
    end

endmodule

module alu (  // a+b 모듈
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

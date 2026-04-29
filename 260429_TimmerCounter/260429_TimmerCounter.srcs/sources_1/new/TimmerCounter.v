`timescale 1ns / 1ps

module TimmerCounter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cnt_en,
    input  wire        cnt_clear,
    input  wire        intr_en,
    input  wire [31:0] PSC,
    input  wire [31:0] ARR,
    output wire        intr,
    output wire [31:0] count
);

    wire tick, c_intr;

    assign intr = c_intr & intr_en;

    prescaler u_prescaler (
        .clk      (clk),
        .rst_n    (rst_n),      // axi는 전부 reset이 negative
        .cnt_en   (cnt_en),
        .cnt_clear(cnt_clear),
        .PSC      (PSC),
        .tick     (tick)
    );

    counter u_counter (
        .clk      (clk),
        .rst_n    (rst_n),      // axi는 전부 reset이 negative
        .tick     (tick),
        .cnt_en   (cnt_en),
        .cnt_clear(cnt_clear),
        .ARR      (ARR),
        .intr     (c_intr),     //인터럽트
        .count    (count)
    );



endmodule

module prescaler (
    input  wire        clk,
    input  wire        rst_n,      // axi는 전부 reset이 negative
    input  wire        cnt_en,
    input  wire        cnt_clear,
    input  wire [31:0] PSC,
    output reg         tick
);

    reg [31:0] preCounter;

    always @(posedge clk) begin
        if (!rst_n) begin
            preCounter <= 0;
            tick <= 1'b0;
        end else begin
            if (cnt_en && !cnt_clear) begin //!cnt_clear가 없으면 race condition 발생!!
                if (preCounter == PSC) begin
                    preCounter <= 0;
                    tick <= 1'b1;
                end else begin
                    preCounter <= preCounter + 1;
                    tick       <= 1'b0;
                end
            end else if (cnt_clear) begin
                preCounter <= 0;
                tick       <= 1'b0;
            end
        end
    end
endmodule

module counter (
    input  wire        clk,
    input  wire        rst_n,      // axi는 전부 reset이 negative
    input  wire        tick,
    input  wire        cnt_en,
    input  wire        cnt_clear,
    input  wire [31:0] ARR,
    output reg         intr,       //인터럽트
    output reg  [31:0] count
);
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
            intr  <= 1'b0;
        end else begin
            if (cnt_en && !cnt_clear) begin //!cnt_clear가 없으면 race condition 발생!!
                intr <= 1'b0;
                if (tick) begin  //tick들어왔을 때 count!!!
                    if (count == ARR) begin
                        count <= 0;
                        intr  <= 1'b1; // tick으로 발생했는데 1틱이 되면 유지되고 1틱이되면 유지되는 동작!
                    end else begin
                        count <= count + 1;
                        intr  <= 1'b0;
                    end
                end
            end else if (cnt_clear) begin
                count <= 0;
                intr  <= 1'b0;
            end
        end
    end
endmodule


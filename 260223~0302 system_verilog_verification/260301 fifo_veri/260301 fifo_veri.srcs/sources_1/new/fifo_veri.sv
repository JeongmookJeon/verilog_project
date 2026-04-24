`timescale 1ns / 1ps

module FIFO (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] wdata,
    input  logic       we, //push
    input  logic       re, //pop
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [3:0] waddr, raddr; //wptr, rptr
    

    registerfile U_REG_FILE (
        .waddr(waddr),
        .raddr(raddr),
        .we(~full&we),
        .*  //같으면 자동 연결됨 아래꺼
        /*.clk(clk),
        .wdata(wdata),
        .rdata(rdata)*/
    );

    controlunit U_CNTL_UNIT (
        .wptr(waddr),
        .rptr(raddr),
        .*
       /* .clk(clk),
        .rst(rst),
        .we(we),
        .re(re),
        .full(full),
        .empty(empty),*/
    );

endmodule

module registerfile (
    input  logic       clk,
    input  logic [7:0] wdata,
    input  logic [3:0] waddr,
    input  logic [3:0] raddr,
    input  logic       we,
    output logic [7:0] rdata
);

    logic [7:0] ram[0:15];

    assign rdata = ram[raddr]; //출력은 조합논리로 설계할 것임!!!

    always_ff @(posedge clk) begin  //입력은 순차논리로 설게할 것임!!
        if (we) begin
            ram[waddr] <= wdata;
        end
    end


endmodule

module controlunit (
    input  logic     clk,
    input  logic       rst,
    input  logic       we,
    input  logic       re,
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty
);

    logic [3:0] wptr_reg, wptr_next;
    logic [3:0] rptr_reg, rptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    localparam PUSH = 2'b10, POP = 2'b01, BOTH = 2'b11;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin : blockName
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin : blockName1
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            we, re  //push&pop 데이터임
        })
            POP:
            if (!empty_reg) begin
                rptr_next = rptr_reg + 1;
                full_next = 1'b0;
                if (rptr_next == wptr_reg) begin
                    empty_next = 1'b1;
                end
            end
            PUSH:
            if (!full_reg) begin
                wptr_next  = wptr_reg + 1;
                empty_next = 1'b0;
                if (wptr_next == rptr_reg) begin
                    full_next = 1'b1;
                end
            end
            BOTH:
            if (full_reg) begin
                rptr_next = rptr_reg + 1;
                full_next = 1'b0;
            end else if (empty_reg) begin
                wptr_next  = wptr_reg + 1;
                empty_next = 1'b0;
            end else begin
                rptr_next = rptr_reg + 1;
                wptr_next = wptr_reg + 1;
            end
        endcase
    end

endmodule

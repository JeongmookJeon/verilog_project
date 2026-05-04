`timescale 1 ns / 1 ps

module SPI_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire mosi,
    input  wire miso,
    output wire sclk,
    output wire cs_n,
    // User ports ends

    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);

    // Instantiation of Axi Bus Interface S00_AXI
    SPI_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) SPI_v1_0_S00_AXI_inst (
        // SPI 포트 연결 추가
   
        .sclk(sclk),
        .cs_n(cs_n),
        .cpol(cpol),  // idle 0: low, 1: high
        .cpha(cpha),  // first sampling, 0: first edge, 1: second edge
        .clk_div(clk_div),
        .tx_data(tx_data),
        .done(done),
        .busy(busy),

        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

endmodule

module spi_master (
    input clk,
    input rst,
    input cpol,  // idle 0: low, 1: high
    input cpha,  // first sampling, 0: first edge, 1: second edge
    input [7:0] clk_div,
    input [7:0] tx_data,
    output reg done,
    output reg busy,
    input start,
    output reg [7:0] rx_data,
    input miso,
    output sclk,
    output reg mosi,
    output reg cs_n  // cs
);

    // State Encoding (SystemVerilog의 enum을 localparam으로 변경)
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state;
    reg [7:0] div_cnt;
    reg half_tick;  // sclk (master -> slave)
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg [3:0] bit_cnt;
    reg step, sclk_r;

    assign sclk = sclk_r;

    // Clock Divider 로직 (always_ff를 always @로 변경)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1'b1;
                    half_tick <= 1'b0;
                end
            end else begin
                half_tick <= 1'b0;
            end
        end
    end

    // Main SPI FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            cs_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            bit_cnt      <= 4'd0;
            step         <= 1'b0;
            rx_data      <= 8'd0;
            sclk_r       <= cpol;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi         <= 1'bz;
                    cs_n         <= 1'b1;
                    sclk_r       <= cpol;
                    rx_shift_reg <= 8'd0;
                    if (start) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 4'd0;
                        step         <= 1'b0;
                        busy         <= 1'b1;
                        cs_n         <= 1'b0;
                        state        <= START;
                    end
                end

                START: begin
                    if (!cpha) begin
                        mosi <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end

                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 1'b0) begin
                            // DATA_LOW: 수신(Sampling) 또는 송신 준비
                            step <= 1'b1;
                            if (!cpha) begin
                                if (bit_cnt <= 7) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], miso};
                                    bit_cnt <= bit_cnt + 1'b1;
                                end else begin
                                    state   <= STOP;
                                    rx_data <= rx_shift_reg;
                                    bit_cnt <= 4'd0;
                                end
                            end else begin
                                mosi <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin
                            // DATA_HIGH: 송신(Shift) 또는 수신 준비
                            step <= 1'b0;
                            if (!cpha) begin
                                mosi <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end else begin
                                if (bit_cnt <= 7) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], miso};
                                    bit_cnt <= bit_cnt + 1'b1;
                                end else begin
                                    state   <= STOP;
                                    rx_data <= rx_shift_reg;
                                    bit_cnt <= 4'd0;
                                end
                            end
                        end
                    end
                end

                STOP: begin
                    sclk_r <= cpol;  // idle 상태의 clock polarity로 복구
                    cs_n <= 1'b1;
                    done <= 1'b1;
                    busy <= 1'b0;
                    mosi <= 1'bz;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

`timescale 1ns / 1ps

module tb_uart ();



    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115_200;
    parameter integer C_S00_AXI_DATA_WIDTH = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH = 4;
    wire                                  tx;
    reg                                   rx;
    wire                                  rx_intr;
    reg                                   s00_axi_aclk;
    reg                                   s00_axi_aresetn;
    reg  [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    reg  [                         2 : 0] s00_axi_awprot;
    reg                                   s00_axi_awvalid;
    wire                                  s00_axi_awready;
    reg  [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    reg  [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    reg                                   s00_axi_wvalid;
    wire                                  s00_axi_wready;
    wire [                         1 : 0] s00_axi_bresp;
    wire                                  s00_axi_bvalid;
    reg                                   s00_axi_bready;
    reg  [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    reg  [                         2 : 0] s00_axi_arprot;
    reg                                   s00_axi_arvalid;
    wire                                  s00_axi_arready;
    wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    wire [                         1 : 0] s00_axi_rresp;
    wire                                  s00_axi_rvalid;
    reg                                   s00_axi_rready;


    uart_v1_0 #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115_200),
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) dut (
        .*,
        .tx(loop_wire),
        .rx(loop_wire)
    );

    always #5 s00_axi_aclk = ~s00_axi_aclk;

    initial begin
        s00_axi_aclk    = 0;
        s00_axi_aresetn = 0;
    end

endmodule

`timescale 1 ns / 1 ps

module GPIO_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    inout wire [3:0] io_port,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);

    wire [3:0] cr;
    wire [3:0] idr;
    wire [3:0] odr;


    // Instantiation of Axi Bus Interface S00_AXI
    GPIO_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) GPIO_v1_0_S00_AXI_inst (
        .cr           (cr),
        .idr          (idr),
        .odr          (odr),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // Add user logic here
    GPIO U_GPIO (
        .cr     (cr),
        .idr    (idr),
        .odr    (odr),
        .io_port(io_port)
    );
    // User logic ends

endmodule

//GPIO 제작
module GPIO (
    // internal port
    input  wire [3:0] cr,
    output wire [3:0] idr,
    input  wire [3:0] odr,
    // external port
    inout  wire [3:0] io_port
);

    //generate를 사용해서 비트수가 늘어나도 쉬워짐 
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign io_port[i] = cr[i] ? odr[i] : 1'bz;
            assign idr[i]     = cr[i] ? 1'bz : io_port[i];
        end
    endgenerate

    //assign io_port[1] = cr[1] ? odr[1] : 1'bz;
    //assign idr[1] = cr[1] ? 1'bz : io_port[1];
    //
    //assign io_port[2] = cr[2] ? odr[2] : 1'bz;
    //assign idr[2] = cr[2] ? 1'bz : io_port[2];
    //
    //assign io_port[3] = cr[3] ? odr[3] : 1'bz;
    //assign idr[3] = cr[3] ? 1'bz : io_port[3];



endmodule

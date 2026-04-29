
`timescale 1 ns / 1 ps

module TMR_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire intr,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
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
    wire        cnt_en;
    wire        cnt_clear;
    wire        intr_en;
    wire [31:0] PSC;
    wire [31:0] ARR;
    wire [31:0] count;


    // Instantiation of Axi Bus Interface S00_AXI
    TMR_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) TMR_v1_0_S00_AXI_inst (

        .cnt_en(cnt_en),
        .cnt_clear(cnt_clear),
        .intr_en(intr_en),
        .PSC(PSC),
        .ARR(ARR),
        .count(count),
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

    TimmerCounter u_timer (
        .clk      (s00_axi_aclk),
        .rst_n    (s00_axi_aresetn),
        .cnt_en   (cnt_en),
        .cnt_clear(cnt_clear),
        .intr_en  (intr_en),
        .PSC      (PSC),
        .ARR      (ARR),
        .intr     (intr),
        .count    (count)
    );



    // Add user logic here

    // User logic ends

endmodule

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
                        intr  <= 1'b1;
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


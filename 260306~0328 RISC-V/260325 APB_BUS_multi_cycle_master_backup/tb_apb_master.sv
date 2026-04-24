`timescale 1ns / 1ps

module tb_apb_master ();
    logic        PCLK;
    logic        PRESETn;
    logic [31:0] Addr;
    logic [31:0] Wdata;
    logic        WREQ;
    logic        RREQ;
    logic [31:0] Rdata;
    logic        Ready;
    logic [31:0] PADDR;  // need register
    logic [31:0] PWDATA;  // need register
    logic        PENABLE;
    logic        PWRITE;
    logic        PSEL0;  // RAM 
    logic        PSEL1;  // GPO 
    logic        PSEL2;  // GPI 
    logic        PSEL3;  // GPIO
    logic        PSEL4;  // FND 
    logic        PSEL5;  // UART
    logic [31:0] PRDATA0;  // from RAM 
    logic [31:0] PRDATA1;  // from GPO 
    logic [31:0] PRDATA2;  // from GPI 
    logic [31:0] PRDATA3;  // from GPIO
    logic [31:0] PRDATA4;  // from FND 
    logic [31:0] PRDATA5;  // from UART
    logic        PREADY0;  // from RAM 
    logic        PREADY1;  // from GPO 
    logic        PREADY2;  // from GPI 
    logic        PREADY3;  // from GPIO
    logic        PREADY4;  // from FND 
    logic        PREADY5;  // from UART
    APB_Master dut (.*);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        PRESETn = 0;

        @(negedge PCLK);
        @(negedge PCLK);
        PRESETn = 1;  // 1로 올려서 리셋 해제 (시스템 시작!)

        //RAM Write Test, 0x1000_0000
        @(posedge PCLK);
        #1;
        WREQ  = 1'b1;
        Addr  = 32'h1000_0000;  //RAM 주소
        Wdata = 32'h0000_00041;  //A출력

//       @(posedge PCLK);
//       #1;
        @(PSEL0 && PENABLE);
        PREADY0 = 1'b1;
        @(posedge PCLK);
        #1;
        PREADY0 = 1'b0;
        WREQ = 1'b0;

        //UART Read Test, 0x2000_4000, with waitting for 2cycle
        @(posedge PCLK);
        #1;
        RREQ  = 1'b1;
        Addr  = 32'h2000_4000;  //RAM 주소
        Wdata = 32'h0000_00041;  //A출력
        //uart psel5
        @(PSEL5 && PENABLE);
        @(posedge PCLK);
        @(posedge PCLK);
        #1;
        PREADY5 = 1'b1;
        PRDATA5 = 32'h0000_0041;
        @(posedge PCLK);
        #1;
        PREADY5 = 1'b0;
        RREQ = 1'b0;
        @(posedge PCLK);
        @(posedge PCLK);

        $stop;
    end

endmodule

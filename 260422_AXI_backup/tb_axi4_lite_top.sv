`timescale 1ns / 1ps

module tb_axi4_lite_top ();

    axi4_top dut (.*);
    // Global signals
    logic        ACLK;
    logic        ARESETn;
    // Internal Signals
    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    always #5 ACLK = ~ACLK;

    //CPU 역할 
    task axi_write(logic [31:0] address, logic [31:0] data);
        addr     <= address;
        wdata    <= data;
        write    <= 1'b1;
        transfer <= 1'b1;
        @(posedge ACLK);
        transfer <= 1'b0;
        do @(posedge ACLK); while (!ready);
        $display("[%t] CPU WRITE ADDR = %0h, WDATA = %0h", $time, addr, wdata);
    endtask  //axi_write

    //CPU 역할 
    task axi_read(logic [31:0] address);
        addr     <= address;
        write    <= 1'b0;
        transfer <= 1'b1;
        @(posedge ACLK);
        transfer <= 1'b0;
        do @(posedge ACLK); while (!ready);
        $display("[%t] CPU READ ADDR =  %0h, RDATA = %0h", $time, addr, rdata);
    endtask  //axi_read

    initial begin
        ACLK = 0;
        ARESETn = 0;
        repeat (3) @(posedge ACLK);
        ARESETn = 1;
        repeat (3) @(posedge ACLK);

    
        @(posedge ACLK);
        axi_write(32'h00000000, 32'h11111111);
        @(posedge ACLK);
        axi_write(32'h00000004, 32'h22222222);
        @(posedge ACLK);
        axi_write(32'h00000008, 32'h33333333);
        @(posedge ACLK);
        axi_write(32'h0000000c, 32'h44444444);

        @(posedge ACLK);
        axi_read(32'h00000000);
        @(posedge ACLK);
        axi_read(32'h00000004);
        @(posedge ACLK);
        axi_read(32'h00000008);
        @(posedge ACLK);
        axi_read(32'h0000000c);

        repeat (10) @(posedge ACLK);
        $stop;
    end

endmodule

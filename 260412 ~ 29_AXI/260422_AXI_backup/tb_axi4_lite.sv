`timescale 1ns / 1ps

module tb_axi4_lite ();

    // Global signals
    logic        ACLK;
    logic        ARESETn;
    // AW channel
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    // W channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    // B channel
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    // AR channel
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    // R channel
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;
    // Internal Signals
    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    axi4_lite_master dut (.*);

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
        $display("[%t] CPU WRITE ADDR = %0h, WDATA = %0h", $time, addr,
                 wdata);
    endtask  //axi_write

    //CPU 역할 
    task axi_read(logic [31:0] address);
        addr     <= address;
        write    <= 1'b0;
        transfer <= 1'b1;
        @(posedge ACLK);
        transfer <= 1'b0;
        do @(posedge ACLK); while (!ready);
        $display("[%t] CPU READ ADDR =  %0h, RDATA = %0h", $time, addr,
                 rdata);
    endtask  //axi_read

    //SLAVE AXI-Lite simulator
    //register 값이 있어야 함
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    bit [31:0] slave_addr;
    bit slv_addr_flag;  //이걸 왜?

    task axi_slave_write_aw();
        // AW channel
        forever begin
            @(posedge ACLK);
            if (AWVALID & !AWREADY) begin
                slave_addr = AWADDR;
                AWREADY = 1'b1;
                slv_addr_flag = 1;
            end else if (AWVALID & AWREADY) begin
                AWREADY = 1'b0;
            end else begin
                AWREADY = 1'b0;
                slv_addr_flag = 0;
            end
        end
    endtask  //axi_slave

    task axi_slave_write_w();
        // W channel
        forever begin
            @(posedge ACLK);
            if (WVALID & !WREADY) begin
                wait (slv_addr_flag);
                case (slave_addr[3:2])
                    2'h0: slv_reg0 = WDATA;
                    2'h1: slv_reg1 = WDATA;
                    2'h2: slv_reg2 = WDATA;
                    2'h3: slv_reg3 = WDATA;
                endcase
                WREADY = 1'b1;
                $display("[%t] SLAVE WRITE ADDR =  %0h, WDATA = %0h", $time,
                         slave_addr, WDATA);
            end else if (WVALID & WREADY) begin
                WREADY = 1'b0;
            end else begin
                WREADY = 1'b0;
            end
        end
    endtask  //axi_slave

    task axi_slave_write_b();
        // B channel
        forever begin
            @(posedge ACLK);
            if (WVALID) begin
                BRESP  = 2'b00;  //OK 
                BVALID = 1'b1;
                $display("[%t] SLAVE WRITE BRESP = %0h", $time, BRESP);
            end else if (BVALID & BREADY) begin
                BVALID = 1'b0;
            end else begin
                BVALID = 1'b0;
            end
        end
    endtask  //axi_slave\\

    task axi_slave_read_ar();
        // AR channel
        forever begin
            @(posedge ACLK);
            if (ARVALID & !ARREADY) begin
                slave_addr = ARADDR;
                ARREADY = 1'b1;
                slv_addr_flag = 1;
                $display("[%t] SLAVE READ BRESP = %0h", $time, slave_addr);
            end else if (ARVALID & ARREADY) begin
                ARREADY = 1'b0;
            end else begin
                ARREADY = 1'b0;
                //여기 조건으로 0으로 내려가기 때문에 AW 에서 flag 안 뜨는 것 
                //동시 작용헀는데, 이게 뒤에 있어서 이게 작용한 듯 
                slv_addr_flag = 0;
            end
        end
    endtask  //axi_slave

    task axi_slave_read_r();
        // R channel
        forever begin
            @(posedge ACLK);
            //!RVALID & ARVALID는 뭐야?  => 이게 맞음 
            if (!RVALID & ARVALID) begin //애매함 RREADY를 0으로 하는지 1로 하는지 차이가 뭔데?
                wait (slv_addr_flag);
                case (slave_addr[3:2])
                    2'h0: RDATA = slv_reg0;
                    2'h1: RDATA = slv_reg1;
                    2'h2: RDATA = slv_reg2;
                    2'h3: RDATA = slv_reg3;
                endcase
                RVALID = 1'b1;
                RRESP  = 2'b00;
                $display("[%t] SLAVE READ ADDR =  %0h, RDATA = %0h", $time,
                         slave_addr, RDATA);
            end else if (RVALID & RREADY) begin
                RVALID = 1'b0;
            end else begin
                RVALID = 1'b0;
            end
        end
    endtask  //axi_slave


    initial begin
        ACLK = 0;
        ARESETn = 0;
        repeat (3) @(posedge ACLK);
        ARESETn = 1;
        repeat (3) @(posedge ACLK);

        //fork join으로 동시 동작 시키기
        fork
            axi_slave_write_aw();
            axi_slave_write_w();
            axi_slave_write_b();
            axi_slave_read_ar();
            axi_slave_read_r();
        join_none

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

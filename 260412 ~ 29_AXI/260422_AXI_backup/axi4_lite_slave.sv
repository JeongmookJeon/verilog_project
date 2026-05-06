`timescale 1ns / 1ps

module axi4_lite_slave (
    // Global signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // AW channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // W channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // B channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // AR channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // R channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP     // ok로 보기 : 무시하는 형태로 
);

    logic [31:0] aw_addr, aw_addr_next;

    logic [31:0] ar_addr, ar_addr_next;

    //logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    logic [31:0] mem[0:(2*32-1)];
    logic write_plag;
    logic read_plag;

    always_ff @(posedge ACLK) begin
        if (write_plag) begin
            if (WVALID && WREADY) begin
                mem[aw_addr[31:2]] <= WDATA;
            end
        end
        //else if (read_plag) begin
        //    RDATA = mem[ar_addr[31:2]];
        //end
    end

    //assign mem[aw_addr[31:2]] = (write_plag) ? WDATA : 32'h0000_0000;
    assign RDATA = (read_plag) ? mem[ar_addr[31:2]] : 32'h0000_0000;

    /************************ WRITE TRANSACTION ***********************/

    //AW Channel transfer
    typedef enum {
        AW_IDLE,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE;
            aw_addr  <= 0;
        end else begin
            aw_state <= aw_state_next;
            aw_addr  <= aw_addr_next;
        end
    end

    always_comb begin
        AWREADY = 0;
        aw_state_next = AW_IDLE;
        aw_addr_next = aw_addr;
        case (aw_state)
            AW_IDLE: begin
                AWREADY = 0;
                if (AWVALID) begin
                    aw_state_next = AW_READY;
                end
            end
            AW_READY: begin
                aw_addr_next = AWADDR;
                AWREADY = 1;
                if (WVALID) begin
                    aw_state_next = AW_IDLE;
                end
            end
        endcase
    end

    //W Channel transfer
    typedef enum {
        W_IDLE,
        W_READY
    } w_state_e;

    w_state_e w_state, w_state_next;

    logic [31:0] w_data;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        write_plag = 0;
        WREADY = 0;
        w_state_next = W_IDLE;
        case (w_state)
            W_IDLE: begin
                write_plag = 0;
                WREADY = 0;
                if (WVALID && AWREADY) begin
                    w_state_next = W_READY;
                    //write_plag   = 1;
                end
            end
            W_READY: begin
                //case (aw_addr[3:2])
                //    2'h0: slv_reg0 = WDATA;
                //    2'h1: slv_reg1 = WDATA;
                //    2'h2: slv_reg2 = WDATA;
                //    2'h3: slv_reg3 = WDATA;
                //endcase
                WREADY = 1;
                if (WVALID) begin
                    write_plag   = 1;
                    w_state_next = W_IDLE;
                end
            end
        endcase
    end

    //B Channel transfer
    typedef enum {
        B_IDLE,
        B_VALID
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        BRESP = 0;
        BVALID = 0;
        b_state_next = B_IDLE;
        case (b_state)
            B_IDLE: begin
                BRESP  = 0;
                BVALID = 0;
                if (WREADY) begin
                    b_state_next = B_VALID;
                end
            end
            B_VALID: begin
                BRESP  = 2'b00;
                BVALID = 1;
                if (BREADY) begin
                    b_state_next = B_IDLE;
                end
            end
        endcase
    end

    /************************ READ TRANSACTION ***********************/

    //AR Channel transfer
    typedef enum {
        AR_IDLE,
        AR_READY
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
            ar_addr  <= 0;
        end else begin
            ar_state <= ar_state_next;
            ar_addr  <= ar_addr_next;
        end
    end

    always_comb begin
        ARREADY = 0;
        ar_state_next = AR_IDLE;
        ar_addr_next = ar_addr;
        case (ar_state)
            AR_IDLE: begin
                ARREADY = 0;
                if (ARVALID) begin
                    ar_state_next = AR_READY;
                end
            end
            AR_READY: begin
                ar_addr_next = ARADDR;
                ARREADY = 1;
                if (RVALID) begin
                    ar_state_next = AR_IDLE;
                end
            end
        endcase
    end

    //R Channel transfer
    typedef enum {
        R_IDLE,
        R_VALID
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        read_plag = 0;
        //RDATA = 0;
        RVALID = 0;
        RRESP = 0;
        r_state_next = R_IDLE;
        case (r_state)
            R_IDLE: begin
                read_plag = 0;
                //RDATA  = 0;
                RVALID = 0;
                RRESP = 0;
                if (ARREADY && ARREADY) begin
                    r_state_next = R_VALID;
                end
            end
            R_VALID: begin
                read_plag = 1;
                //case (ar_addr[3:2])
                //    2'h0: RDATA = slv_reg0;
                //    2'h1: RDATA = slv_reg1;
                //    2'h2: RDATA = slv_reg2;
                //    2'h3: RDATA = slv_reg3;
                //endcase
                RVALID = 1;
                RRESP = 2'b00;
                if (RREADY) begin
                    r_state_next = R_IDLE;
                end
            end
        endcase
    end

endmodule

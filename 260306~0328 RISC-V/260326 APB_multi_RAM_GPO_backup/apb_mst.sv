`timescale 1ns / 1ps


module apb_master (
    // BUS Global signal
    input        PCLK,
    input        PRESET,
    // SoC Internal signal with CPU
    input [31:0] Addr,    // from CPU
    input [31:0] Wdata,   // from CPU
    input        WREQ,    // from cpu, write request, single cpu : dwe
    input        RREQ,    // from cpu, read request, single cpu : dre

    //output logic        SlvERR,
    output logic        Ready,
    output logic [31:0] Rdata,


    // APB Interface signal
    output logic [31:0] PADDR,  // need register
    output logic [31:0] PWDATA, // need register


    output logic PENABLE,
    output logic PWRITE,
    output logic PSEL0,    // ram
    output logic PSEL1,    // gpo
    output logic PSEL2,    // gpi
    output logic PSEL3,    // gpiO
    output logic PSEL4,    // fnd
    output logic PSEL5,    // uart


    // ram
  //  input        pslverr0,
    input [31:0] PRDATA0,
    input        PREADY0,

    // gpo
   // input        pslverr1,
    input [31:0] PRDATA1,
    input        PREADY1,
    //gpi
   // input        pslverr2,
    input [31:0] PRDATA2,
    input        PREADY2,
    //gpio
   // input        pslverr3,
    input [31:0] PRDATA3,
    input        PREADY3,
    // fnd
  //  input        pslverr4,
    input [31:0] PRDATA4,
    input        PREADY4,

    //uart
  //  input        pslverr5,
    input [31:0] PRDATA5,
    input        PREADY5
);





    typedef enum {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e c_st, n_st;
    logic [31:0] PADDR_next, PWDATA_next;
    logic decode_en;
    logic PWRITE_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin  // 0
            c_st   <= IDLE;
            PADDR  <= 32'd0;
            PWDATA <= 32'd0;
        end else begin
            c_st   <= n_st;
            PADDR  <= PADDR_next;
            PWDATA <= PWDATA_next;
            PWRITE <= PWRITE_next;
        end
    end

    // next
    always_comb begin
        decode_en = 1'b0;
        PENABLE = 1'b0;
        PADDR_next = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        n_st = c_st;
        case (c_st)

            IDLE: begin
                decode_en = 1'b0;
                PENABLE = 1'b0;
                PADDR_next = 32'd0;
                PWDATA_next = 32'd0;
                PWRITE_next = 1'b0;
                if (WREQ | RREQ) begin
                    PADDR_next  = Addr;
                    PWDATA_next = Wdata;
                    if (WREQ) begin
                        PWRITE_next = 1'b1;
                    end else PWRITE_next = 1'b0;
                    n_st = SETUP;
                end
            end

            SETUP: begin
                decode_en = 1'b1;
                PENABLE = 1'b0;
                n_st = ACCESS;
            end

            ACCESS: begin
                decode_en = 1'b1;
                PENABLE   = 1'b1;
                //     if (PREADY0|PREADY1|PREADY2|PREADY3|PREADY4|PREADY5) begin
                if (Ready) begin  // MUX's ready-> hamchuk
                    // bus_ready = 1'b1;
                    n_st = IDLE;
                end
            end
        endcase
    end

    addr_decoder U_DEC (
        .en(decode_en),
        .addr(PADDR),
        .psel0(PSEL0),
        .psel1(PSEL1),
        .psel2(PSEL2),
        .psel3(PSEL3),
        .psel4(PSEL4),
        .psel5(PSEL5)
    );

    apb_mux U_MUX (
        .sel(PADDR),
        .PRDATA0(PRDATA0),
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PRDATA4(PRDATA4),
        .PRDATA5(PRDATA5),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .PREADY4(PREADY4),
        .PREADY5(PREADY5),
        .Rdata(Rdata),
        .Ready(Ready)
    );


   // assign bus_ready = (c_st == ACCESS) && Ready;



endmodule

// address decoder
module addr_decoder (
    input               en,
    input        [31:0] addr,
    output logic        psel0,
    output logic        psel1,
    output logic        psel2,
    output logic        psel3,
    output logic        psel4,
    output logic        psel5
);

    always_comb begin
        psel0 = 1'b0;  // idle : 0
        psel1 = 1'b0;
        psel2 = 1'b0;
        psel3 = 1'b0;
        psel4 = 1'b0;
        psel5 = 1'b0;

        if (en) begin

            case (addr[31:28])  // instead of casex
                4'h1: psel0 = 1'b1;
                4'h2: begin
                    case (addr[15:12])
                        4'h0: psel1 = 1'b1;
                        4'h1: psel2 = 1'b1;
                        4'h2: psel3 = 1'b1;
                        4'h3: psel4 = 1'b1;
                        4'h4: psel5 = 1'b1;
                    endcase
                end

            endcase
        end

    end

endmodule

module apb_mux (
    input        [31:0] sel,
    input        [31:0] PRDATA0,
    input        [31:0] PRDATA1,
    input        [31:0] PRDATA2,
    input        [31:0] PRDATA3,
    input        [31:0] PRDATA4,
    input        [31:0] PRDATA5,
    input               PREADY0,
    input               PREADY1,
    input               PREADY2,
    input               PREADY3,
    input               PREADY4,
    input               PREADY5,
    output logic [31:0] Rdata,
    output logic        Ready
);

    always_comb begin
        Rdata = 32'h0000_0000;  // idle : 0
        Ready = 1'b0;
        case (sel[31:28])  // instead of casex
            4'h1: begin
                Rdata = PRDATA0;
                Ready = PREADY0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = PRDATA1;
                        Ready = PREADY1;
                    end
                    4'h1: begin
                        Rdata = PRDATA2;
                        Ready = PREADY2;
                    end
                    4'h2: begin
                        Rdata = PRDATA3;
                        Ready = PREADY3;
                    end
                    4'h3: begin
                        Rdata = PRDATA4;
                        Ready = PREADY4;
                    end
                    4'h4: begin
                        Rdata = PRDATA5;
                        Ready = PREADY5;
                    end
                    default: begin
                        Rdata = 32'hxxxx_xxxx;
                        Ready = 1'bx;
                    end
                endcase
            end

        endcase

    end



endmodule




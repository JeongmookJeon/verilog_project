`timescale 1ns / 1ps

module rv32I_mcu (
    input         clk,
    input         rst,
    output [15:0] led
);

    logic bus_wreq;
    logic bus_rreq;  // chooga
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata;
    // chooga
    logic bus_ready;

    logic [31:0] PADDR, PWDATA;
    logic PENABLE, PWRITE;

    logic PSEL0, PSEL1, PSEL2, PSEL3, PSEL4, PSEL5;
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3, PRDATA4, PRDATA5;
    logic PREADY0, PREADY1, PREADY2, PREADY3, PREADY4, PREADY5;

    // assign led = bus_rdata[15:0];

    instruction_mem U_INSTRUTION_MEM (.*);


    rv32i_cpu U_RV32I (
        .clk(clk),
        .rst(rst),
        .instr_data(instr_data),
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready),
        .instr_addr(instr_addr),
        .bus_wreq(bus_wreq),
        .bus_rreq(bus_rreq),
        .o_funct3(o_funct3),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata)
    );

    apb_master U_APB_MASTER (
        .PCLK  (clk),
        .PRESET(rst),
        .Addr  (bus_addr),
        .Wdata (bus_wdata),
        .WREQ  (bus_wreq),
        .RREQ  (bus_rreq),
        .Ready (bus_ready),
        .Rdata (bus_rdata),


        // to APB SLAVE
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PENABLE(PENABLE),
        .PWRITE (PWRITE),

        // form APB SLAVE
        .PSEL0(PSEL0),
        .PSEL1(PSEL1),
        .PSEL2(PSEL2),
        .PSEL3(PSEL3),
        .PSEL4(PSEL4),
        .PSEL5(PSEL5),


        //.pslverr0(),
        .PRDATA0(PRDATA0),
        .PREADY0(PREADY0),
        // .pslverr1(),
        .PRDATA1(PRDATA1),
        .PREADY1(PREADY1),
        //  .pslverr2(),
        .PRDATA2(PRDATA2),
        .PREADY2(PREADY2),
        //  .pslverr3(),
        .PRDATA3(PRDATA3),
        .PREADY3(PREADY3),
        //   .pslverr4(),
        .PRDATA4(PRDATA4),
        .PREADY4(PREADY4),
        //   .pslverr5(),
        .PRDATA5(PRDATA5),
        .PREADY5(PREADY5)
    );


    BRAM U_BRAM (

        .*,
        .PCLK  (clk),
        .PRESET(rst),
        .PSEL  (PSEL0),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );

    APB_GPO U_APB_GPO (
        .PCLK(clk),
        .PRESET(rst),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PSEL(PSEL1),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1),
        .GPO_OUT(led)
    );


endmodule

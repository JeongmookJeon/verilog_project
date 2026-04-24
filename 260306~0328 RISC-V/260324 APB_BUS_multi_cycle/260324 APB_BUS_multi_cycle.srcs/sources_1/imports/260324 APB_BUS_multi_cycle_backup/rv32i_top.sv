`timescale 1ns / 1ps

module rv32I_top (
    input clk,
    input rst,
    output [15:0] led
);

    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata; // daddr, dwdata, drdata;
    logic bus_wreq, bus_rreq, bus_ready;

    logic [31:0] Addr, Wdata, PADDR, PWDATA;
    logic [31:0] PRDATA0;  // from RAM 
    logic [31:0] PRDATA1;  // from GPO 
    logic [31:0] PRDATA2;  // from GPI 
    logic [31:0] PRDATA3;  // from GPIO
    logic [31:0] PRDATA4;  // from FND
    logic [31:0] PRDATA5;  // from UART
    logic Ready;

    //assign led = drdata[15:0];

    instruction_mem U_INSTRUTION_MEM (.*);
    rv32i_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );
    APB_Master U_APB_MASTER (
        .PCLK(clk),
        .PRESETn(rst),
        .Addr(bus_addr),   // from cpu
        .Wdata(bus_wdata),  // from cpu
        .WREQ(bus_wreq),   // from cpu, Write request, signal cpu : dwe
        .RREQ(bus_rreq),   // from cpu, Read request,  signal cpu : dre
        .Rdata(bus_rdata),
        .Ready(bus_ready)
        // .PADDR(),    // need register
        // .PWDATA(),   // need register
        // .PENABLE(),
        // .PWRITE(),
        // .PSEL0(),    // RAM 
        // .PSEL1(),    // GPO 
        // .PSEL2(),    // GPI 
        // .PSEL3(),    // GPIO
        // .PSEL4(),    // FND 
        // .PSEL5(),    // UART
        // .PRDATA0(),  // from RAM 
        // .PRDATA1(),  // from GPO 
        // .PRDATA2(),  // from GPI 
        // .PRDATA3(),  // from GPIO
        // .PRDATA4(),  // from FND 
        // .PRDATA5(),  // from UART
        // .PREADY0(),  // from RAM 
        // .PREADY1(),  // from GPO 
        // .PREADY2(),  // from GPI 
        // .PREADY3(),  // from GPIO
        // .PREADY4(),  // from FND 
        // .PREADY5()   // from UART
    );    
    // data_mem U_DATA_MEM (
    //     .*,
    //     .i_funct3(o_funct3)
    // );
endmodule

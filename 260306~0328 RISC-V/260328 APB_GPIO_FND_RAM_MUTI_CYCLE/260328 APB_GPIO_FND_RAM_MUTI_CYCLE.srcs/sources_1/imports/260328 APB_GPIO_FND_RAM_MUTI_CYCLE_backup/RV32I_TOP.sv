`timescale 1ns / 1ps

module rv32I_mcu (
    input         clk,
    input         rst,
    input  [ 7:0] GPI,
    output [ 7:0] GPO,
    inout  [15:0] GPIO,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    input         rx,
    output        tx
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

	// UART
	wire tx_start, rx_done, rxfifo_empty, rx_get, tx_busy, b_tick;
	wire [1:0] baud_rate;
	wire [7:0] rx_data, fifo_rx_reg, tx_data;
	APB_UART U_APB_UART (
    	.PCLK		(clk),
    	.PRESET		(rst),
    	.PADDR		(PADDR),
    	.PWDATA		(PWDATA),
    	.PWRITE		(PWRITE),
    	.PENABLE	(PENABLE),
    	.PSEL		(PSEL5),
    	.PREADY		(PREADY5),
    	.PRDATA		(PRDATA5),
    	.i_rx_data	(fifo_rx_reg),
    	.i_rx_done	(~rxfifo_empty),
		.o_rx_get	(rx_get),
    	.o_tx_start	(tx_start),
    	.o_tx_data	(tx_data),
    	.i_tx_busy	(tx_busy),
		.o_baud_rate(baud_rate)
	);
	baud_tick_sampling_divide_3types U_BAUD_TICK_GEN (
	    .clk			(clk),
	    .rst			(rst),
		.i_baud_rate 	(baud_rate),
	    .b_tick			(b_tick)
	);
	uart_rx U_UART_RX (
	    .clk		(clk),
	    .rst		(rst),
	    .rx			(rx),
	    .b_tick		(b_tick),
	    .rx_data	(rx_data),
	    .rx_done	(rx_done)
	);
	fifo #(
	    .DEPTH		(8),
	    .BIT_WIDTH 	(8)
	) U_RX_FIFO (
	    .clk		(clk),
	    .rst		(rst),
	    .push		(rx_done),
	    .pop		(rx_get),
	    .push_data	(rx_data),
	    .pop_data	(fifo_rx_reg),
	    .full		(),
	    .empty		(rxfifo_empty)
	);
	uart_tx U_UART_TX (
	    .clk		(clk),
	    .rst		(rst),
	    .tx_start	(tx_start),
	    .b_tick		(b_tick),  // *16
	    .tx_data	(tx_data),
	    .tx_busy	(tx_busy),
	    .tx_done	(),
	    .uart_tx	(tx)
	);


    // assign led = bus_rdata[15:0];
    APB_FND U_APB_FND (
        .PCLK(clk),
        .PRESET(rst),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL4),
        .PRDATA(PRDATA4),
        .PREADY(PREADY4),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );



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

    APB_GPI U_APB_GPI (

        .PCLK(clk),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL2),
        .GPI(GPI),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2)
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
        .GPO_OUT(GPO)
    );


    GPIO U_GPIO (
        // BUS Global signal
        .PCLK(clk),
        .PRESET(rst),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL3),
        .PRDATA(PRDATA3),
        .PREADY(PREADY3),
        .GPIO(GPIO)
    );


endmodule

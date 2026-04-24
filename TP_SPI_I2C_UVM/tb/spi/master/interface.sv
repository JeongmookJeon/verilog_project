`ifndef SPI_MASTER_INTERFACE_SV
`define SPI_MASTER_INTERFACE_SV

interface spi_master_if (
    input logic       clk,
    input logic       reset,
    input logic       cpol,
    input logic       cpha,
    input logic [7:0] clk_div
);
    logic [7:0] tx_data;
    logic       start;
    logic [7:0] rx_data;
    logic       done;
    logic       busy;
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;

	clocking drv_cb @(posedge clk);
		default input #1step output #0;
		output tx_data;
		output start;
		input  rx_data;
		input  done;
		input  busy;
		input  sclk;
		input  mosi;
		output miso;
		input  cs_n;
	endclocking // drv_cb

	clocking mon_cb @(posedge clk);
		default input #1step;
		input tx_data;
		input start;
		input rx_data;
		input done;
		input busy;
		input sclk;
		input mosi;
		input miso;
		input cs_n;
	endclocking // mon_cb

	modport mp_drv(clocking drv_cb, input clk, input reset);
	modport mp_mon(clocking mon_cb, input clk, input reset);

endinterface // spi_master_if

`endif


`ifndef SPI_SLAVE_INTERFACE_SV
`define SPI_SLAVE_INTERFACE_SV

interface spi_slave_if (    
	input  logic       clk,
    input  logic       reset
);
    logic       SCLK;
    logic       MOSI;
    logic       MISO;
    logic       CS_n;
    logic       tx_updata;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       busy;

	clocking drv_cb @(posedge clk);
		default input #1step output #0;
		output SCLK;
		output MOSI;
		input  MISO;
		output CS_n;
		output tx_updata;
		output tx_data;
		input  rx_data;
		input  rx_done;
		input  busy;
	endclocking // drv_cb

	clocking mon_cb @(posedge clk);
		default input #1step;
		input  SCLK;
		input  MOSI;
		input  MISO;
		input  CS_n;
		input  tx_updata;
		input  tx_data;
		input  rx_data;
		input  rx_done;
		input  busy;
	endclocking // mon_cb

	modport mp_drv(clocking drv_cb, input clk, input reset);
	modport mp_mon(clocking mon_cb, input clk, input reset);

endinterface // spi_slave_if

`endif


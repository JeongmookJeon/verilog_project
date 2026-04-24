`ifndef I2C_INTERFACE_SV
`define I2C_INTERFACE_SV

interface i2c_if (
    input logic       clk,
    input logic       reset
);
	// Master
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       m_ack_in;
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       m_ack_out;
    logic       m_busy;
	// Slave
    logic [7:0] s_tx_data;
    logic       s_tx_update;
    logic       s_tx_insert_enable;
    logic [7:0] s_rx_data;
    logic       s_rx_valid;
    logic       s_busy;
	// I2C Signal
    //logic       scl;
    //wire        sda;

	clocking drv_cb @(posedge clk);
		default input #1step output #0;
    	output cmd_start;
    	output cmd_write;
    	output cmd_read;
    	output cmd_stop;
    	output m_tx_data;
    	output m_ack_in;
    	input  m_rx_data;
    	input  m_done;
    	input  m_ack_out;
    	input  m_busy;
    	output s_tx_data;
    	output s_tx_update;
    	input  s_tx_insert_enable;
    	input  s_rx_data;
    	input  s_rx_valid;
    	input  s_busy;
	endclocking // drv_cb

	clocking mon_cb @(posedge clk);
		default input #1step;
    	output cmd_start;
    	output cmd_write;
    	output cmd_read;
    	output cmd_stop;
    	output m_tx_data;
    	output m_ack_in;
    	output m_rx_data;
    	output m_done;
    	output m_ack_out;
    	output m_busy;
    	output s_tx_data;
    	output s_tx_update;
    	output s_tx_insert_enable;
    	output s_rx_data;
    	output s_rx_valid;
    	output s_busy;
	endclocking // mon_cb

	modport mp_drv(clocking drv_cb, input clk, input reset);
	modport mp_mon(clocking mon_cb, input clk, input reset);

endinterface // i2c_if

`endif


`ifndef UART_INTERFACE_SV
`define UART_INTERFACE_SV

interface uart_if (
    input logic clk,
    input logic rst
);
    logic uart_rx; // testbench에서 DUT연결(드라이버가 구동)
    logic uart_tx; // DUT에서 testbench로 연결(모니터가 only 관찰)
endinterface
`endif

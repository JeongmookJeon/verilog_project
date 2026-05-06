`include "uvm_macros.svh" 
import uvm_pkg::*;

`include "uart_agent.sv"
`include "uart_coverage.sv"
`include "uart_driver.sv"
`include "uart_env.sv"
`include "uart_interface.sv"
`include "uart_monitor.sv"
`include "uart_scoreboard.sv"
`include "uart_seq_item.sv"
`include "uart_sequence.sv"
`include "tb_test.sv"

module tb_uart (); 
    logic clk;
    logic rst;

    initial begin 
        clk = 0;
        forever #5 clk = ~clk; 
    end

    uart_if vif (
        .clk(clk),
        .rst(rst)
    );
uart_top dut(
    .clk(vif.clk),
    .rst(vif.rst),
    .uart_rx(vif.uart_rx),
    .uart_tx(vif.uart_tx)
);
    

    // 리셋 생성 (Active High 방식에 맞게 수정)
    initial begin
        rst = 1; 
        repeat (5) @(posedge clk);
        rst = 0; 
    end

    initial begin
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
        run_test();
    end

    // 웨이브폼 덤프
    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_uart, "+all");
    end

endmodule
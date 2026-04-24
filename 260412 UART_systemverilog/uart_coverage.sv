`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_coverage extends uvm_subscriber #(uart_seq_item);
    `uvm_component_utils(uart_coverage)
    
    uart_seq_item tx;

    // 
    covergroup uart_cg;
        cp_data: coverpoint tx.data {
            bins data_q1 = {[8'h00 : 8'h3F]}; // 구간 1: 0   ~ 63
            bins data_q2 = {[8'h40 : 8'h7F]}; // 구간 2: 64  ~ 127
            bins data_q3 = {[8'h80 : 8'hBF]}; // 구간 3: 128 ~ 191
            bins data_q4 = {[8'hC0 : 8'hFF]}; // 구간 4: 192 ~ 255
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        uart_cg = new();
    endfunction

    function void write(uart_seq_item t);
        tx = t;
        uart_cg.sample(); // 데이터가 들어올 때마다 어느 구간에 속하는지 체크
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== UART Coverage Summary =====", UVM_LOW);
        
        `uvm_info(get_type_name(), $sformatf("Overall Coverage: %.1f%%", uart_cg.get_coverage()), UVM_LOW);
        
        `uvm_info(get_type_name(), $sformatf("Data 4-Partition (cp_data): %.1f%%", uart_cg.cp_data.get_coverage()), UVM_LOW);
        
        `uvm_info(get_type_name(), "===============================\n", UVM_LOW);
    endfunction
endclass

`endif
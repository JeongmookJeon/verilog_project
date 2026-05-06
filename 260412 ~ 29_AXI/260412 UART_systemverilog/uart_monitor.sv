`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
// uart tx에서 보낸 데이터를 받음( RX)
class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uvm_analysis_port #(uart_seq_item) ap;
    virtual uart_if vif;

    localparam int BIT_TIME = 10417;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(),
                       "monitor에서 uvm_config_db error 발생");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "UART TX 핀 모니터링 시작...",
                  UVM_MEDIUM)
        wait (vif.rst == 0);
        forever begin
            collect_transaction();
        end
    endtask
    // uart 프로토콜 샘플링 동작 (wave form)
    // 실제 uart rx와 동일한 프로토콜로 동작해야함.
    task collect_transaction();
        uart_seq_item tx = uart_seq_item::type_id::create("mon_tx");
        //
        // Start bit 대기 (Falling edge)
        @(negedge vif.uart_tx);

        // 비트의 중앙점(0.5 bit)으로 이동 후, 첫 Data bit 위치로 이동 (안정적인 샘플링)
        repeat (BIT_TIME / 2) @(posedge vif.clk);
        repeat (BIT_TIME) @(posedge vif.clk);

        // 8 Data bits 샘플링
        for (int i = 0; i < 8; i++) begin
            tx.data[i] = vif.uart_tx;
            repeat (BIT_TIME) @(posedge vif.clk);
        end

        // Stop bit 대기
        repeat (BIT_TIME) @(posedge vif.clk);

        `uvm_info(get_type_name(), $sformatf("Monitor 수신 완료 : %s",
                                             tx.convert2string()), UVM_MEDIUM)
        ap.write(tx);
    endtask
endclass

`endif

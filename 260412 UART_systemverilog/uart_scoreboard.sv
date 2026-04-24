`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_drv) // Driver용 포트 선언
`uvm_analysis_imp_decl(_mon) // Monitor용 포트 선언

class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_imp_drv #(uart_seq_item, uart_scoreboard) ap_imp_drv;
    uvm_analysis_imp_mon #(uart_seq_item, uart_scoreboard) ap_imp_mon;

    // FIFO Queue (먼저 보낸 데이터가 먼저 수신되므로)
    logic [7:0] ref_mem[$];

    int num_matches = 0;
    int num_errors = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp_drv = new("ap_imp_drv", this);
        ap_imp_mon = new("ap_imp_mon", this);
    endfunction

    // Driver가 보낸 데이터 저장
    function void write_drv(uart_seq_item tx);
        ref_mem.push_back(tx.data);
    endfunction

    // Monitor가 수신한 데이터와 비교
    function void write_mon(uart_seq_item tx);
        logic [7:0] expected;
        
        if (ref_mem.size() > 0) begin
            expected = ref_mem.pop_front();
            
            if (expected !== tx.data) begin
                num_errors++;
                `uvm_error(get_type_name(), $sformatf("FAIL! expected = 0x%02h, actual = 0x%02h", expected, tx.data))
            end else begin
                num_matches++;
                `uvm_info(get_type_name(), $sformatf("PASS! expected = 0x%02h, actual = 0x%02h", expected, tx.data), UVM_MEDIUM)
            end
        end else begin
            `uvm_error(get_type_name(), "큐가 비어있는데 Monitor에서 데이터가 수신됨!")
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (num_errors == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "************ summary report ***********", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Result : %s", result), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Match num : %0d", num_matches), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Error num : %0d", num_errors), UVM_MEDIUM)
        `uvm_info(get_type_name(), "***********************************", UVM_MEDIUM)
    endfunction
endclass

`endif
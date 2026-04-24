`ifndef UART_TEST_SV 
`define UART_TEST_SV 

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;


class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    
    uart_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== UVM 계층 구조 =====", UVM_MEDIUM)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Base에서는 동작 없음
    endtask

    virtual function void report_phase(uvm_phase phase);
        // Base에서는 동작 없음
    endfunction
endclass


class uart_rand_test extends uart_base_test;
    `uvm_component_utils(uart_rand_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_rand_seq seq;
        
        phase.raise_objection(this);
        
        seq = uart_rand_seq::type_id::create("seq");
        seq.num_loop = 15; // 랜덤 15번 돌리기
        seq.start(env.agt.sqr);
        
        // 모니터에 도달할 때까지 시뮬레이션이 안 꺼지도록 대기
        #5ms; 
        
        phase.drop_objection(this);
    endtask
endclass


class uart_pattern_test extends uart_base_test;
    `uvm_component_utils(uart_pattern_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_pattern_seq seq;
        
        phase.raise_objection(this);
        
        seq = uart_pattern_seq::type_id::create("seq");
        seq.num_loop = 5; // 패턴 4개짜리를 5번 반복 
        seq.start(env.agt.sqr);
        
        //루프백 대기 시간
        #5ms; 
        
        phase.drop_objection(this);
    endtask
endclass

`endif
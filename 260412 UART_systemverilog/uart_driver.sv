`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;

    // Scoreboard에 내가 보낸 값을 알려주기 위한 포트
    uvm_analysis_port #(uart_seq_item) ap_drv;

    // 100MHz / 9600 baudrate = 약 10417 cycles per bit
    localparam int BIT_TIME = 10417;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_drv = new("ap_drv", this);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(),
                       "driver에서 uvm_config_db error 발생");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.uart_rx <= 1'b1;  // Idle state
        wait (vif.rst == 0);
        `uvm_info(get_type_name(),
                  "리셋 해제 확인, 트랜잭션 대기중...", UVM_MEDIUM)

        forever begin
            //1. drv가 tx 핸들러 준비
            uart_seq_item tx;
            //uvm 내장 포트.
            //이 포트는 sequencer와 drv간에 연결하는 통로
            //2. drv가 seqitemport의 다음 item요청
            seq_item_port.get_next_item(tx);

            //아래 task에 tx 핸들러 연결
            //rx가 0일때 수신 시작(uart 프로토콜임.)
            drive_uart(tx);
            //analysis port로 tx를 scb에 보냄
            ap_drv.write(tx);  // 보낸 데이터를 Scoreboard로 전송!
            //seq_item_port에게 item_done 완료 신호 보냄.
            seq_item_port.item_done();

            // 바이트와 바이트 사이의 여유 시간 대기
            repeat (BIT_TIME * 2) @(posedge vif.clk);
        end
    endtask

    task drive_uart(uart_seq_item tx);
        // Start bit
        vif.uart_rx <= 1'b0;
        //0으로 내린채로 1클럭 기다림.
        repeat (BIT_TIME) @(posedge vif.clk);

        // Data bits (LSB first)
        // lsm 부터 msb까지 송신할때까지 기다렸다가.
        // for문으로 1비트당 bittime기다리게끔 설계.
        //다음으로 넘어감
        for (int i = 0; i < 8; i++) begin
            vif.uart_rx <= tx.data[i];
            repeat (BIT_TIME) @(posedge vif.clk);
        end

        // Stop bit
        vif.uart_rx <= 1'b1;
        repeat (BIT_TIME) @(posedge vif.clk);

        `uvm_info(get_type_name(), $sformatf("Driver 전송 완료 : %s",
                                             tx.convert2string()), UVM_MEDIUM)
    endtask
endclass

`endif

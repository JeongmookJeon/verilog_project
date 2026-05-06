`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class uart_base_sequence extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_base_sequence)

    function new(string name = "uart_base_sequence");
        super.new(name);
    endfunction

    // 자식 시퀀스들이 편하게 쓸 수 있도록 데이터 전송 Task를 미리 정의해둠
    task send_data(bit [7:0] wdata);
        uart_seq_item item = uart_seq_item::type_id::create("item");
        start_item(item);

        // 인자로 받은 wdata를 아이템의 data에 강제로 주입
        if (!item.randomize() with {data == wdata;}) begin
            `uvm_fatal(get_type_name(), "send_data() Randomize() fail!")
        end

        finish_item(item);
        `uvm_info(get_type_name(),
                  $sformatf("send_data() 전송 완료 : data = 0x%02h", wdata),
                  UVM_MEDIUM)
    endtask

    virtual task body();
        // Base에서는 아무것도 하지 않음. 자식들이 구현함.
    endtask
endclass

class uart_rand_seq extends uart_base_sequence;
    `uvm_object_utils(uart_rand_seq)

    int num_loop = 10;

    function new(string name = "uart_rand_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (num_loop) begin
            uart_seq_item item = uart_seq_item::type_id::create("item");
            start_item(item);

            if (!item.randomize())
                `uvm_fatal(get_type_name(), "Randomize() Fail")

            finish_item(item);
        end
    endtask
endclass

class uart_pattern_seq extends uart_base_sequence;
    `uvm_object_utils(uart_pattern_seq)

    int num_loop = 5;

    function new(string name = "uart_pattern_seq");
        super.new(name);
    endfunction

    virtual task body();
        for (int i = 0; i < num_loop; i++) begin
            `uvm_info(get_type_name(), $sformatf(
                      "--- Pattern Test Loop %0d ---", i), UVM_MEDIUM)

            // 0x55 (01010101)
            send_data(8'h55);

            // 0xAA (10101010)
            send_data(8'hAA);

            // 0x00 (00000000)
            send_data(8'h00);

            // 0xFF (11111111)
            send_data(8'hFF);
        end
    endtask
endclass

`endif

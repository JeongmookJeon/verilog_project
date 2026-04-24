`timescale 1ns / 1ps

module tb_i2c_master ();

    logic       clk;
    logic       reset;
    logic       cmd_write;
    logic       cmd_start;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] tx_data;
    logic       ack_in;
    logic [7:0] rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;
    logic       scl;
    wire        sda;

    //assign scl = 1'b1;
    //assign sda = 1'b1;

    localparam SLA = 8'h12;  //slave address
    I2C_Master dut (
        .*,
        .scl(scl),
        .sda(sda)
    );

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);

    endtask

    task i2c_addr(byte addr);
        //wait_cmd 절차
        //ADDRESS 절차
        //address + R/W signal 절차 == data(tx_data)
        //tx_data = address(8'h12) + rw
        tx_data   = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // = DATA_ACK의 done
        @(posedge clk);


    endtask

    task i2c_write(byte data);
        //wait_cmd 절차
        //ADDRESS 절차
        //address + R/W signal 절차 == data(tx_data)
        //tx_data = address(8'h12) + rw
        tx_data   = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // = DATA_ACK의 done
        @(posedge clk);


    endtask

    task i2c_read();
        //wait_cmd 절차
        //ADDRESS 절차
        //address + R/W signal 절차 == data(tx_data)
        //tx_data = address(8'h12) + rw
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // = DATA_ACK의 done
        @(posedge clk);
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);  //data_ack
        @(posedge clk);
    endtask





    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        i2c_start();
        i2c_addr(SLA << 1 + 1'b0);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_write(8'h01);
        i2c_write(8'h02);
        i2c_write(8'h03);
        i2c_write(8'h04);
        i2c_write(8'h05);
        i2c_write(8'hff);
        i2c_stop();

        //        //start > address > ack > data > ack > stop절차
        //
        //        //START 절차
        //        cmd_start = 1'b1;
        //        cmd_write = 1'b0;
        //        cmd_read  = 1'b0;
        //        cmd_stop  = 1'b0;
        //        @(posedge clk);
        //        wait (done);
        //        @(posedge clk);
        //
        //
        //
        //        //wait_cmd 절차
        //        //ADDRESS 절차
        //        //address + R/W signal 절차 == data(tx_data)
        //        //tx_data = address(8'h12) + rw
        //        tx_data   = (SLA << 1) + 1'b0;
        //        cmd_start = 1'b0;
        //        cmd_write = 1'b1;
        //        cmd_read  = 1'b0;
        //        cmd_stop  = 1'b0;
        //        @(posedge clk);
        //        wait (done);  // = DATA_ACK의 done
        //        @(posedge clk);
        //
        //
        //        //wait_cmd 절차
        //        //tx_data = data
        //        tx_data   = 8'h55;
        //        cmd_start = 1'b0;
        //        cmd_write = 1'b1;
        //        cmd_read  = 1'b0;
        //        cmd_stop  = 1'b0;
        //        @(posedge clk);
        //        wait (done);  //data_ack
        //        @(posedge clk);
        //
        //        //stop 절차
        //        cmd_start = 1'b0;
        //        cmd_write = 1'b0;
        //        cmd_read  = 1'b0;
        //        cmd_stop  = 1'b1;
        //        @(posedge clk);
        //        wait (done);  //data_ack
        //        @(posedge clk);
        //

        //        //IDLE state
        #100;
        $finish;

    end

endmodule

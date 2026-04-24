`timescale 1ns / 1ps

module i2c_demo_top (
    input logic clk,
    input logic reset,
    input logic btn_start,
    input logic sw,
    output logic [7:0] led,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data,
    output logic scl,
    inout wire sda
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        ADDR,
        WRITE,
        READ,
        STOP
    } i2c_state_e;
    i2c_state_e state;

    localparam SLA_W = {7'h5A, 1'b0};
    localparam SLA_R = {7'h5A, 1'b1};

    logic [7:0] counter;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       ack_in;
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       s_done;
    logic       ack_out;
    logic       m_busy;
    logic       s_busy;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       o_btn;

    assign led = s_rx_data;

    btn_debounce u_bd (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(o_btn)
    );

    i2c_top U_I2C_IP (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_stop (cmd_stop),
        .m_tx_data(m_tx_data),
        .s_tx_data(8'h55),
        .m_rx_data(m_rx_data),
        .s_rx_data(s_rx_data),
        .m_done   (m_done),
        .scl      (scl),
        .sda      (sda),
        .*
    );

    fnd_controller U_FND (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data(sw ? {6'b0, m_rx_data} : {6'b0, s_rx_data}),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            state <= IDLE;
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read <= 1'b0;
            cmd_stop <= 1'b0;
            m_tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (o_btn) begin
                        state <= START;
                    end
                end
                START: begin
                    cmd_start <= 1'b1;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    m_tx_data <= sw ? SLA_R : SLA_W;
                    if (m_done) begin
                        state <= ADDR;
                    end
                end
                ADDR: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    m_tx_data <= sw ? SLA_R : SLA_W;
                    if (m_done) begin
                        state <= sw ? READ : WRITE;
                    end
                end
                WRITE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    m_tx_data <= counter;
                    if (m_done) begin
                        state <= STOP;
                    end
                end
                READ: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b1;
                    cmd_stop  <= 1'b0;
                    m_tx_data <= counter;
                    if (m_done) begin
                        state <= STOP;
                    end
                end
                STOP: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b1;
                    m_tx_data <= SLA_W;
                    if (m_done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


/*
`timescale 1ns / 1ps

module i2c_demo_top (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic scl,
    inout  wire  sda
);

    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        //READ,
        STOP
    } i2c_state_e;

    localparam SLA_W = {7'h12, 1'b0};  //8bit
    i2c_state_e       state;
    logic       [7:0] counter;
    logic             cmd_write;
    logic             cmd_start;
    logic             cmd_read;
    logic             cmd_stop;
    logic       [7:0] tx_data;
    logic             ack_in;
    logic       [7:0] rx_data;
    logic             done;
    logic             ack_out;
    logic             busy;
    


    I2C_Master U_I2C_MASTER (
        .clk      (clk),
        .reset    (reset),
        .cmd_write(cmd_write),
        .cmd_start(cmd_start),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .ack_in   (ack_in),
        .rx_data  (rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)         //in out port
    );

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            state <= IDLE;
            cmd_write <= 1'b0;
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_stop <= 1'b0;
            tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (sw) begin
                        state <= START;
                    end
                end
                START: begin
                    cmd_start <= 1'b1;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (done) begin
                        state <= ADDR;
                    end
                end
                ADDR: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= SLA_W;
                    if (done) begin
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= counter;
                    if (done) begin
                        state <= STOP;
                    end
                end
                //data 보냄.
                STOP: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b1;
                    tx_data   <= SLA_W;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end

                default: begin
                    state <= IDLE;

                end
            endcase
        end

    end



endmodule
*/
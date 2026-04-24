module i2c_slave #(
    parameter ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       reset,
    // Control/Status
    input  logic [7:0] tx_data,
    input  logic       tx_update,
    output logic       tx_insert_enable,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       busy,
    // I2C Interface
    input  logic       SCL,
    inout  wire        SDA
);

    logic SDA_i, SDA_o, SDA_t;
    assign SDA_i = SDA;
    assign SDA = (~SDA_t && ~SDA_o)? 1'b0 : 1'bz;

    i2c_slave_ctrl #(
        .ADDR(ADDR)
    ) U_I2C_SLAVE_CTRL (
        .clk                (clk),
        .reset              (reset),
        .tx_data            (tx_data),
        .tx_update          (tx_update),
        .tx_insert_enable   (tx_insert_enable),
        .rx_data            (rx_data),
        .rx_valid           (rx_valid),
        .busy               (busy),
        .SCL                (SCL),
        .SDA_i              (SDA_i),
        .SDA_o              (SDA_o),
        .SDA_t              (SDA_t)
    );

endmodule

module i2c_slave_ctrl #(
    parameter ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       reset,
    // Control/Status
    input  logic [7:0] tx_data,
    input  logic       tx_update,
    output logic       tx_insert_enable,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       busy,
    // I2C Interface
    input  logic       SCL,
    input  logic       SDA_i,
    output logic       SDA_o,
    output logic       SDA_t  // 0: output, 1: input
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        REQ,
        ACK,
        WDATA,
        WACK,
        RDATA,
        RACK
    } i2c_slave_state_e;

    i2c_slave_state_e       state;
    logic                   scl_rise_wait;
    logic             [2:0] bit_cnt;
    logic             [7:0] tx_shift_reg, rx_shift_reg;
    logic                   ack_r;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_insert_enable <= 0;
            rx_data          <= 0;
            rx_valid         <= 1'b0;
            busy             <= 1'b0;
            SDA_o            <= 1'b0;
            SDA_t            <= 1'b1;
            state            <= IDLE;
            scl_rise_wait    <= 1'b0;
            bit_cnt          <= 7;
            tx_shift_reg     <= 0;
            rx_shift_reg     <= 0;
            ack_r            <= 0;
        end
        else begin
            case (state)
                IDLE : begin
                    bit_cnt       <= 7;
                    scl_rise_wait <= 1'b0;
                    tx_insert_enable <= 1'b0;

                    if (~SDA_i && SCL) begin
                        busy          <= 1'b1;
                        state         <= START;
                    end
                end
                START: begin
                    if (~SCL) begin
                        state         <= REQ;
                        scl_rise_wait <= 1'b1;
                        SDA_t         <= 1'b1;
                    end
                end
                REQ  : begin
                    if (scl_rise_wait && SCL) begin
                        rx_shift_reg  <= {rx_shift_reg[6:0], SDA_i};
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        if (bit_cnt == 0) begin
                            SDA_t   <= 1'b0;
                            SDA_o   <= 1'b0;
                            state   <= (ADDR == rx_shift_reg[7:1])? ACK : IDLE;
                            bit_cnt <= 7;
                            
                            if (rx_shift_reg[0]) tx_insert_enable <= 1'b1;
                        end
                        else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                ACK  : begin
                    if (scl_rise_wait && SCL) begin
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        SDA_t   <= (rx_shift_reg[0]) ? 1'b0 : 1'b1;
                        SDA_o   <= 1'b0;
                        state   <= (rx_shift_reg[0]) ? RDATA : WDATA;
                    end
                end
                WDATA: begin
                    rx_valid <= 1'b0;

                    if (scl_rise_wait && SCL) begin
                        rx_shift_reg  <= {rx_shift_reg[6:0], SDA_i};
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && SCL && ~rx_shift_reg[0] && SDA_i) begin
                        // STOP
                        busy             <= 1'b0;
                        SDA_o            <= 1'b0;
                        SDA_t            <= 1'b1;
                        state            <= IDLE;
                        scl_rise_wait    <= 1'b0;
                        tx_shift_reg     <= 0;
                        rx_shift_reg     <= 0;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        if (bit_cnt == 0) begin
                            SDA_t   <= 1'b0;
                            SDA_o   <= 1'b0;
                            state   <= WACK;
                            bit_cnt <= 7;
                        end
                        else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                WACK : begin
                    if (scl_rise_wait && SCL) begin
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        SDA_t    <= 1'b1;
                        SDA_o    <= 1'b0;
                        state    <= WDATA;
                        rx_data  <= rx_shift_reg;
                        rx_valid <= 1'b1;
                    end
                end
                RDATA: begin
                    if (scl_rise_wait && ~ SCL) begin
                        SDA_o         <= tx_shift_reg[7];
                    end
                    else if (scl_rise_wait && SCL) begin
                        tx_shift_reg  <= {tx_shift_reg[6:0], 1'b0};
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        if (bit_cnt == 0) begin
                            SDA_t   <= 1'b1;
                            state   <= RACK;
                            bit_cnt <= 7;
                            tx_insert_enable <= 1'b1;
                        end
                        else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                RACK : begin
                    if (scl_rise_wait && SCL) begin
                        scl_rise_wait <= 1'b0;
                    end
                    else if (~scl_rise_wait && SCL) begin
                        ack_r <= SDA_i;
                    end
                    else if (~scl_rise_wait && ~SCL) begin
                        scl_rise_wait <= 1'b1;
                        
                        SDA_t    <= (ack_r) ? 1'b1 : 1'b0;
                        state    <= (ack_r) ? IDLE : RDATA;
                        busy     <= (ack_r) ? 1'b0 : 1'b1;

                        ack_r    <= 1'b0;
                    end
                end
            endcase

            if (tx_insert_enable && tx_update) begin
                tx_shift_reg     <= tx_data;
                tx_insert_enable <= 1'b0;
            end
        end
    end

endmodule
